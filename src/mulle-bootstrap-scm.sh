#! /usr/bin/env bash
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#
MULLE_BOOTSTRAP_SCM_SH="included"


git_is_repository()
{
   [ -d "${1}/.git" ] || [ -d  "${1}/refs" -a -f "${1}/HEAD" ]
}


git_is_bare_repository()
{
   local is_bare

   # if bare repo, we can only clone anyway
   is_bare=`(
               cd "$1" &&
               git rev-parse --is-bare-repository 2> /dev/null
            )` || internal_fail "wrong \"$1\" for \"`pwd`\""
   [ "${is_bare}" = "true" ]
}


git_set_url()
{
   local directory="$1"
   local remote="$2"
   local url="$3"

   (
      cd "${directory}" &&
      git remote set-url "${remote}" "${url}"  >&2 &&
      git fetch "${remote}"  >&2  # prefetch to get new branches
   ) || exit 1
}


#
# prefer origin over others, probably could be smarter
# by passing in the desired branch and figuring more
# stuff out
#
git_get_default_remote()
{
   local i
   local match

   match=""
   IFS="
"
   for i in `( cd "$1" ; git remote)`
   do
      case "$i" in
         origin)
            match="$i"
            break
         ;;

         *)
            if [ -z "${match}" ]
            then
               match="$i"
            fi
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"

   echo "$match"
}


git_has_branch()
{
   (
      cd "$1" &&
      git branch | cut -c3- | fgrep -q -s -x "$2" > /dev/null
   ) || exit 1
}


git_get_branch()
{
   (
      cd "$1" &&
      git rev-parse --abbrev-ref HEAD 2> /dev/null
   ) || exit 1
}


git_checkout()
{
   [ $# -ge 7 ] || internal_fail "git_checkout: parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local scm="$1"; shift
   local tag="$1"; shift
   local stashdir="$1"; shift

   [ -z "${stashdir}" ] && internal_fail "stashdir is empty"
   [ -z "${tag}" ]      && internal_fail "tag is empty"

   local options

   # checkout don't know -v
   options="${GITOPTIONS}"
   if [ "${options}" = "-v" ]
   then
      options=""
   fi

   local branch

   branch="`git_get_branch "${stashdir}"`"

   if [ "${branch}" != "${tag}" ]
   then
      log_info "Checking out version ${C_RESET_BOLD}${tag}${C_INFO} of ${C_MAGENTA}${C_BOLD}${stashdir}${C_INFO} ..."
      (
         exekutor cd "${stashdir}" &&
         exekutor git ${GITFLAGS} checkout ${options} "${tag}"  >&2
      ) || return 1

      if [ $? -ne 0 ]
      then
         log_error "Checkout failed, moving ${C_CYAN}${C_BOLD}${stashdir}${C_ERROR} to ${C_CYAN}${C_BOLD}${stashdir}.failed${C_ERROR}"
         log_error "You need to fix this manually and then move it back."

         rmdir_safer "${stashdir}.failed"
         exekutor mv "${stashdir}" "${stashdir}.failed"  >&2
         return 1
      fi
   else
      log_fluff "Already on proper branch \"${branch}\""
   fi
}


fork_and_name_from_url()
{
   local url="$1"
   local name
   local hack
   local fork

   hack="`sed 's|^[^:]*:|:|' <<< "${url}"`"
   name="`basename -- "${hack}"`"
   fork="`dirname -- "${hack}"`"
   fork="`basename -- "${fork}"`"

   case "${hack}" in
      /*/*|:[^/]*/*|://*/*/*)
      ;;

      *)
         fork="__other__"
      ;;
   esac

   echo "${fork}" | sed 's|^:||'
   echo "${name}"
}



# global variable __GIT_MIRROR_URLS__ used to avoid refetching
# repos in one setting
#
_git_get_mirror_url()
{
   local url="$1"; shift

   local name
   local fork
   local result

   result="`fork_and_name_from_url "${url}"`"
   fork="`echo "${result}" | head -1`"
   name="`echo "${result}" | tail -1`"

   local mirrordir

   mkdir_if_missing "${GIT_MIRROR}/${fork}"
   mirrordir="${GIT_MIRROR}/${fork}/${name}" # try to keep it global

   local match
   local filelistpath

   # use global reposdir
   [ -z "${REPOS_DIR}" ] && internal_fail "REPOS_DIR undefined"

   filelistpath="${REPOS_DIR}/.uptodate-mirrors"
   log_debug "Mirror URLS: `cat "${filelistpath}" 2>/dev/null`"

   match="`fgrep -s -x "${mirrordir}" "${filelistpath}" 2>/dev/null`"
   if [ ! -z "${match}" ]
   then
      log_fluff "Repository \"${mirrordir}\" already up-to-date for this session"
      echo "${mirrordir}"
      return 0
   fi

   if [ ! -d "${mirrordir}" ]
   then
      log_verbose "Set up git-mirror \"${mirrordir}\""
      if ! exekutor git ${GITFLAGS} clone --mirror ${options} ${GITOPTIONS} -- "${url}" "${mirrordir}" >&2
      then
         log_error "git clone of \"${url}\" into \"${mirrordir}\" failed"
         return 1
      fi
   else
      # refetch

      if [ "${REFRESH_GIT_MIRROR}" = "YES" ]
      then
      (
         log_verbose "Refreshing git-mirror \"${mirrordir}\""
         cd "${mirrordir}";
         if ! exekutor git ${GITFLAGS} fetch >&2
         then
            log_warning "git fetch from \"${url}\" failed, using old state"
         fi
      )
      fi
   fi

   # for embedded we are otherwise too early
   echo "${mirrordir}" >> "${filelistpath}"
   echo "${mirrordir}"
}


_git_clone()
{
   [ $# -ge 2 ] || internal_fail "_git_clone: parameters missing"

   local url="$1"; shift
   local stashdir="$1"; shift
   local branch="$1"

   [ ! -z "${url}" ]      || internal_fail "url is empty"
   [ ! -z "${stashdir}" ] || internal_fail "stashdir is empty"

   [ -e "${stashdir}" ]   && internal_fail "${stashdir} already exists"

   local options
   local dstdir

   dstdir="${stashdir}"
   options=""
   if [ ! -z "${branch}" ]
   then
      log_info "Cloning ${C_RESET_BOLD}$branch${C_INFO} of ${C_MAGENTA}${C_BOLD}${url}${C_INFO} into \"${stashdir}\" ..."
      options="-b ${branch}"
   else
      log_info "Cloning ${C_MAGENTA}${C_BOLD}${url}${C_INFO} into \"${stashdir}\" ..."
   fi

   # "remote urls" go through caches
   case "${url}" in
      file:*|/*|~*|.*)
      ;;

      *:*)
         if [ ! -z "${GIT_MIRROR}" ]
         then
            url="`_git_get_mirror_url "${url}"`" || return 1
         fi
      ;;
   esac

#
# callers responsibility
#
#   local parent
#
#    parent="`dirname -- "${stashdir}"`"
#   mkdir_if_missing "${parent}"

   if [ "${stashdir}" = "${url}" ]
   then
      # since we know that stash dir does not exist, this
      # message is a bit less confusing
      log_error "Clone source \"${url}\" does not exist."
      return 1
   fi

   if ! exekutor git ${GITFLAGS} clone ${options} ${GITOPTIONS} -- "${url}" "${stashdir}"  >&2
   then
      log_error "git clone of \"${url}\" into \"${stashdir}\" failed"
      return 1
   fi
}


git_clone()
{
   [ $# -ge 7 ] || internal_fail "git_clone: parameters missing"

   local reposdir="$1"
#   local name="$2"
   local url="$3"
   local branch="$4"
#   local scm="$5"
   local tag="$6"
   local stashdir="$7"

   if ! _git_clone "${url}" "${stashdir}" "${branch}" "${reposdir}"
   then
      return 1
   fi

   if [ ! -z "${tag}" ]
   then
      git_checkout "$@"
   fi
}


git_fetch()
{
   [ $# -ge 7 ] || internal_fail "git_fetch: parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local scm="$1"; shift
   local tag="$1"; shift
   local stashdir="$1"; shift

   # "remote urls" going through cache will be refreshed here
   case "${url}" in
      file:*|/*|~*|.*)
      ;;

      *:*)
         if [ ! -z "${GIT_MIRROR}" ]
         then
            url="`_git_get_mirror_url "${url}"`" || return 1
         fi
      ;;
   esac

   log_info "Fetching ${C_MAGENTA}${C_BOLD}${stashdir}${C_INFO} ..."

   (
      exekutor cd "${stashdir}" &&
      exekutor git ${GITFLAGS} fetch "$@" ${GITOPTIONS} >&2
   ) || fail "git fetch of \"${stashdir}\" failed"
}


git_pull()
{
   [ $# -ge 7 ] || internal_fail "git_pull: parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local scm="$1"; shift
   local tag="$1"; shift
   local stashdir="$1"; shift

   # "remote urls" going through cache will be refreshed here
   case "${url}" in
      file:*|/*|~*|.*)
      ;;

      *:*)
         if [ ! -z "${GIT_MIRROR}" ]
         then
            url="`_git_get_mirror_url "${url}"`" || return 1
         fi
      ;;
   esac

   log_info "Pulling ${C_MAGENTA}${C_BOLD}${stashdir}${C_INFO} ..."

   (
      exekutor cd "${stashdir}" &&
      exekutor git ${GITFLAGS} pull $* ${GITOPTIONS}  >&2
   ) || fail "git pull of \"${stashdir}\" failed"

   if [ ! -z "${tag}" ]
   then
      git_checkout "$@"  >&2
   fi
}


git_status()
{
   [ $# -ge 7 ] || internal_fail "git_status: parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local scm="$1"; shift
   local tag="$1"; shift
   local stashdir="$1"; shift

   log_info "Status ${C_MAGENTA}${C_BOLD}${stashdir}${C_INFO} ..."

   (
      exekutor cd "${stashdir}" &&
      exekutor git ${GITFLAGS} status $* ${GITOPTIONS} >&2
   ) || fail "git status of \"${stashdir}\" failed"
}


svn_checkout()
{
   [ $# -ge 7 ] || internal_fail "svn_checkout: parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local scm="$1"; shift
   local tag="$1"; shift
   local stashdir="$1"; shift

   local options

   options="$*"
   if [ ! -z "${branch}" ]
   then
      log_info "SVN checkout ${C_RESET_BOLD}${branch}${C_INFO} of ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
      options="`concat "${options}" "-r ${branch}"`"
   else
      if [ ! -z "${tag}" ]
      then
         log_info "SVN checkout ${C_RESET_BOLD}${tag}${C_INFO} of ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
         options="`concat "${options}" "-r ${tag}"`"
      else
         log_info "SVN checkout ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
      fi
   fi

   if ! exekutor svn checkout ${options} ${SVNOPTIONS} "${url}" "${stashdir}"  >&2
   then
      log_error "svn clone of \"${url}\" into \"${stashdir}\" failed"
      return 1
   fi
}


svn_update()
{
   [ $# -ge 7 ] || internal_fail "svn_update: parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local scm="$1"; shift
   local tag="$1"; shift
   local stashdir="$1"; shift

   local options

   options="$*"

   [ ! -z "${stashdir}" ] || internal_fail "stashdir is empty"

   log_info "SVN updating ${C_MAGENTA}${C_BOLD}${stashdir}${C_INFO} ..."

   if [ ! -z "$branch" ]
   then
      options="`concat "-r ${branch}" "${options}"`"
   else
      if [ ! -z "$tag" ]
      then
         options="`concat "-r ${tag}" "${options}"`"
      fi
   fi

   (
      exekutor cd "${stashdir}" ;
      exekutor svn update ${options} ${SVNOPTIONS}  >&2
   ) || fail "svn update of \"${stashdir}\" failed"
}


svn_status()
{
   [ $# -ge 7 ] || internal_fail "svn_status: parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local scm="$1"; shift
   local tag="$1"; shift
   local stashdir="$1"; shift

   local options

   options="$*"

   [ ! -z "${stashdir}" ] || internal_fail "stashdir is empty"

   (
      exekutor cd "${stashdir}" ;
      exekutor svn status ${options} ${SVNOPTIONS}  >&2
   ) || fail "svn update of \"${stashdir}\" failed"
}


append_dir_to_gitignore_if_needed()
{
   local directory=$1

   [ -z "${directory}" ] && internal_fail "empty directory"

   case "${directory}" in
      "${REPOS_DIR}/"*)
         return 0
      ;;
   esac

   # strip slashes
   case "${directory}" in
      /*/)
         directory="`echo "$1" | sed 's/.$//' | sed 's/^.//'`"
      ;;

      /*)
         directory="`echo "$1" | sed 's/^.//'`"
      ;;

      */)
         directory="`echo "/$1" | sed 's/.$//'`"
      ;;

      *)
         directory="$1"
      ;;
   esac

   #
   # prepend \n because it is safer, in case .gitignore has no trailing
   # LF which it often seems to not have
   # fgrep is bugged on at least OS X 10.x, so can't use -e chaining
   if [ -f ".gitignore" ]
   then
      local pattern0
      local pattern1
      local pattern2
      local pattern3


      # variations with leadinf and trailing slashes
      pattern0="${directory}"
      pattern1="${pattern0}/"
      pattern2="/${pattern0}"
      pattern3="/${pattern0}/"

      if fgrep -q -s -x -e "${pattern0}" .gitignore ||
         fgrep -q -s -x -e "${pattern1}" .gitignore ||
         fgrep -q -s -x -e "${pattern2}" .gitignore ||
         fgrep -q -s -x -e "${pattern3}" .gitignore
      then
         return
      fi
   fi

   local line
   local lf
   local terminator

   line="/${directory}"
   terminator="`tail -c 1 ".gitignore" 2> /dev/null | tr '\012' '|'`"

   if [ "${terminator}" != "|" ]
   then
      line="${lf}/${directory}"
   fi

   log_info "Adding \"/${directory}\" to \".gitignore\""
   redirect_append_exekutor .gitignore echo "${line}" || fail "Couldn\'t append to .gitignore"
}


#
# will this run over embedded too ?
#
_run_git_on_stash()
{
   local i="$1" ; shift

   local name

   if [ -d "${i}/.git" -o -d "${i}/refs" ]
   then
      name="`basename -- "${i}"`"
      log_info "### $i:"
      (
         cd "$i"  &&
         REPOSITORY="${name}" eval_exekutor "git" "${GITFLAGS}" "$@" "${GITOPTIONS}"  >&2
      )
      if [ $? -ne 0 -a "${MULLE_FLAG_LENIENT}" = "NO" ]
      then
         fail "git failed, use \`${MULLE_EXECUTABLE} --lenient git\` to ignore"
      fi

      log_info
   fi
}


#
# todo: let user select what repositories are affected
#
run_git()
{
   local i

   IFS="
"
   for i in `all_repository_stashes`
   do
      IFS="${DEFAULT_IFS}"

      _run_git_on_stash "$i" "$@"
   done

   for i in `all_embedded_repository_stashes`
   do
      IFS="${DEFAULT_IFS}"

      _run_git_on_stash "$i" "$@"
   done

   for i in `all_deep_embedded_repository_stashes`
   do
      IFS="${DEFAULT_IFS}"

      _run_git_on_stash "$i" "$@"
   done

   IFS="${DEFAULT_IFS}"
}


git_main()
{
   log_debug "::: git :::"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ]           && . mulle-bootstrap-scripts.sh

   # hmm
   if [ "$1" = "-h" -o "$1" = "--help" ]
   then
      git_usage
   fi

   if dir_has_files "${REPOS_DIR}"
   then
      log_fluff "Will run \"git $*\" over clones" >&2
   else
      log_verbose "There is nothing to run git over."
      return 0
   fi

   run_git "$@"
}


_archive_test()
{
   log_debug "_archive_test" "$@"

   local archive="$1"
   local scm="$2"

   log_fluff "Testing ${C_MAGENTA}${C_BOLD}${archive}${C_INFO} ..."

   case "${archive}" in
      *.zip)
         redirect_exekutor /dev/null unzip -t "${archive}" || return 1
	      archive="${archive%.*}"
      ;;
   esac

   case "${scm}" in
      zip*)
         return
      ;;
   esac

   local tarcommand

   tarcommand="tf"

   case "${UNAME}" in
      darwin)
         # don't need it
      ;;

      *)
         case "${url}" in
            *.gz)
               tarcommand="tfz"
            ;;

            *.bz2)
               tarcommand="tfj"
            ;;

            *.x)
               tarcommand="tfJ"
            ;;
         esac
      ;;
   esac


   redirect_exekutor /dev/null tar ${tarcommand} ${TAROPTIONS} ${options} "${archive}" || return 1
}


_archive_unpack()
{
   local archive="$1"

   log_verbose "Extracting ${C_MAGENTA}${C_BOLD}${archive}${C_INFO} ..."

   case "${archive}" in
      *.zip)
         exekutor unzip "${archive}" || return 1
	      archive="${archive%.*}"
      ;;
   esac

   local tarcommand

   tarcommand="xf"

   case "${UNAME}" in
      darwin)
         # don't need it
      ;;

      *)
         case "${url}" in
            *.gz)
               tarcommand="xfz"
            ;;

            *.bz2)
               tarcommand="xfj"
            ;;

            *.x)
               tarcommand="xfJ"
            ;;
         esac
      ;;
   esac

   exekutor tar ${tarcommand} ${TAROPTIONS} ${options} "${archive}" || return 1
}


_validate_download()
{
   log_debug "_validate_download" "$@"

   local filename="$1"
   local scm="$2"

   local checksum
   local expected

   if ! _archive_test "${filename}" "${scm}"
   then
      return 1
   fi

   local options

   #
   # later: make it so tar?shasum256=djhdjhdfdh
   # and check that the archive is correct
   #
   options="`echo "${scm}" | sed -n 's/^[^?]*\?\(.*\)/\1/p'`"
   if [ ! -z "${extra}" ]
   then
      log_fluff "Parsed scm options as \"${options}\""
   fi

   case "${options}" in
      *shasum256*)
         case "${UNAME}" in
            mingw)
               log_fluff "mingw does not support shasum" # or does it ?
            ;;

            *)
               log_fluff "Validating ${C_MAGENTA}${C_BOLD}${filename}${C_INFO} ..."

               expected="`echo "${options}" | sed -n 's/shasum256=\([a-f0-9]*\).*/\1/p'`"
               checksum="`shasum -a 256 -p "${filename}" | awk '{ print $1 }'`"
               if [ "${expected}" != "${checksum}" ]
               then
                  log_error "${filename} sha256 is ${checksum}, not ${expected} as expected"
                  return 1
               fi
            ;;
         esac
      ;;
   esac
}


_single_directory_in_directory()
{
   local count
   local filename

   filename="`ls -1 "${tmpdir}"`"

   count="`echo "$filename}" | wc -l`"
   if [ $count -ne 1 ]
   then
      return
   fi

   echo "${tmpdir}/${filename}"
}


_move_stuff()
{
   local tmpdir="$1"
   local stashdir="$2"
   local archivename="$3"
   local name="$4"

   local src
   local toremove

   toremove="${tmpdir}"
   src="${tmpdir}/${archivename}"
   if [ ! -d "${src}" ]
   then
      src="${tmpdir}/${name}"
      if [ ! -d "${src}" ]
      then
         src="`_single_directory_in_directory "${tmpdir}"`"
         if [ -z "${src}" ]
         then
            src="${tmpdir}"
            toremove=""
         fi
      fi
   fi

   exekutor mv "${src}" "${stashdir}"

   if [ ! -z "${toremove}" ]
   then
      rmdir_safer "${toremove}"
   fi
}


#
# What we do is
# a) download the package using curl
# b) optionally copy it into a cache for next time
# c) create a temporary directory, extract into it
# d) move it into place
#
_tar_download()
{
   local download="$1"
   local url="$2"
   local scm="$3"

   local archive_cache
   local cachable_path
   local cached_archive
   local filename
   local directory

   archive_cache="`read_config_setting "archive_cache" "${DEFAULT_ARCHIVE_CACHE}"`"

   if [ ! -z "${archive_cache}" -a "${archive_cache}" != "NO" ]
   then
      # fix for github
      case "${url}" in
         *github.com*/archive/*)
            directory="`dirname -- "${url}"`" # remove 3.9.2
            directory="`dirname -- "${directory}"`" # remove archives
            filename="`basename -- "${directory}"`-${download}"
         ;;

         *)
            filename="${download}"
         ;;
      esac

      cachable_path="${archive_cache}/${filename}"

      if [ -f "${cachable_path}" ]
      then
         cached_archive="${cachable_path}"
      fi
   fi

   if [ ! -z "${cached_archive}" ]
   then
      log_info "Using cached \"${cached_archive}\" for ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
      # we are in a tmp dir
      cachable_path=""
      if ! _validate_download "${cached_archive}" "${scm}"
      then
         remove_file_if_present "${cached_archive}"
         cached_archive=""
      fi
      exekutor ln -s "${cached_archive}" "${download}" || fail "failed to symlink \"${cached_archive}\""
   fi

   if [ -z "${cached_archive}" ]
   then
      exekutor curl -O -L ${CURLOPTIONS} "${url}" || fail "failed to download \"${url}\""
      if ! _validate_download "${download}" "${scm}"
      then
         remove_file_if_present "${download}"
         fail "Can't download archive from \"${url}\""
      fi
   fi

   [ -f "${download}" ] || internal_fail "expected file \"${download}\" is mising"

   if [ -z "${cached_archive}" -a ! -z "${cachable_path}" ]
   then
      log_verbose "Caching \"${url}\" as \"${cachable_path}\" ..."
      mkdir_if_missing "${archive_cache}" || fail "failed to create archive cache \"${archive_cache}\""
      exekutor cp "${download}" "${cachable_path}" || fail "failed to copy \"${download}\" to \"${cachable_path}\""
   fi
}


tar_unpack()
{
   log_debug "tar_unpack" "$@"

   [ $# -ge 7 ] || internal_fail "tar_unpack: parameters missing"

#   local reposdir="$1"
   local name="$2"
   local url="$3"
#   local branch="$4"
   local scm="$5"
#   local tag="$6"
   local stashdir="$7"

   local tmpdir
   local archive
   local download
   local options
   local archivename
   local directory

   # fixup github
   download="`basename -- "${url}"`"
   archive="${download}"

   # remove .tar (or .zip et friends)
   archivename="`extension_less_basename "${download}"`"
   case "${archivename}" in
      *.tar)
         archivename="`extension_less_basename "${archivename}"`"
      ;;
   esac

   rmdir_safer "${name}.tmp"
   tmpdir="`make_tmp_directory "${name}"`" || return 1
   (
      exekutor cd "${tmpdir}" || return 1

      _tar_download "${download}" "${url}" "${scm}" || return 1

      _archive_unpack "${download}" || return 1
      exekutor rm "${download}" || return 1
   ) || return 1

   _move_stuff "${tmpdir}" "${stashdir}" "${archivename}" "${name}"
}


zip_unpack()
{
   log_debug "zip_unpack" "$@"

   [ $# -ge 7 ] || internal_fail "zip_unpack: parameters missing"

#   local reposdir="$1"
   local name="$2"
   local url="$3"
#   local branch="$4"
   local scm="$5"
#   local tag="$6"
   local stashdir="$7"

   local tmpdir
   local download
   local archivename

   download="`basename --  "${url}"`"
   archivename="`extension_less_basename "${download}"`"

   rmdir_safer "${name}.tmp"
   tmpdir="`make_tmp_directory "${name}"`" || exit 1
   (
      exekutor cd "${tmpdir}" || return 1

      log_info "Downloading ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."

      exekutor curl -O -L ${CURLOPTIONS} "${url}" || return 1
      _validate_download "${download}" "${scm}" || return 1

      log_verbose "Extracting ${C_MAGENTA}${C_BOLD}${download}${C_INFO} ..."

      exekutor unzip "${download}" || return 1
      exekutor rm "${download}"
   ) || return 1

   _move_stuff "${tmpdir}" "${stashdir}" "${archivename}" "${name}"
}


git_enable_mirroring()
{
   local allow_refresh="${1:-YES}"

   #
   # stuff clones get intermediate saved too, default is on
   # this is only called in main if the option is yes
   #
   GIT_MIRROR="`read_config_setting "git_mirror"`"
   if [ "${allow_refresh}" = "YES" ]
   then
      REFRESH_GIT_MIRROR="`read_config_setting "refresh_git_mirror" "YES"`"
   fi
}


scm_initialize()
{
   log_debug ":scm_initialize:"

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ]    && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ] && . mulle-bootstrap-repositories.sh

   # this is an actual GIT variable
   GIT_TERMINAL_PROMPT="`read_config_setting "git_terminal_prompt" "0"`"
   export GIT_TERMINAL_PROMPT
}

scm_initialize

:
