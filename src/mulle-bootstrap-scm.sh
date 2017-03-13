#! /bin/sh
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


git_get_url()
{
   local remote

   remote="$2"

   (
      cd "$1" &&
      git remote get-url "${remote}"  >&2
   ) || internal_fail "wrong \"$1\" or \"${remote}\" for \"`pwd`\""
}


git_set_url()
{
   local remote
   local url

   remote="$2"
   url="$3"

   (
      cd "$1" &&
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
         exekutor cd "${stashdir}" ;
         exekutor git ${GITFLAGS} checkout ${options} "${tag}"  >&2
      ) || exit 1

      if [ $? -ne 0 ]
      then
         log_error "Checkout failed, moving ${C_CYAN}${C_BOLD}${stashdir}${C_ERROR} to ${C_CYAN}${C_BOLD}${stashdir}.failed${C_ERROR}"
         log_error "You need to fix this manually and then move it back."

         rmdir_safer "${stashdir}.failed"
         exekutor mv "${stashdir}" "${stashdir}.failed"  >&2
         exit 1
      fi
   else
      log_fluff "Already on proper branch \"${branch}\""
   fi
}


git_clone()
{
   [ $# -ge 7 ] || internal_fail "git_clone: parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local scm="$1"; shift
   local tag="$1"; shift
   local stashdir="$1"; shift

   [ ! -z "${url}" ]      || internal_fail "url is empty"
   [ ! -z "${stashdir}" ] || internal_fail "stashdir is empty"

   local options

   options="$*"
   if [ ! -z "${branch}" ]
   then
      log_info "Cloning branch ${C_RESET_BOLD}$branch${C_INFO} of ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
      options="`concat "${options}" "-b ${branch}"`"
   else
      log_info "Cloning ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
   fi

#
# callers responsibility
#
#   local parent
#
#    parent="`dirname -- "${stashdir}"`"
#   mkdir_if_missing "${parent}"

   exekutor git ${GITFLAGS} clone ${options} ${GITOPTIONS} -- "${url}" "${stashdir}"  >&2 \
    || fail "git clone of \"${url}\" into \"${stashdir}\" failed"

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

   log_info "Fetching ${C_MAGENTA}${C_BOLD}${stashdir}${C_INFO} ..."

   (
      exekutor cd "${stashdir}" &&
      exekutor git ${GITFLAGS} fetch "$@" ${GITOPTIONS}  >&2
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

   exekutor svn checkout ${options} ${SVNOPTIONS} "${url}" "${stashdir}"  >&2 \
     || fail "svn clone of \"${url}\" into \"${stashdir}\" failed"
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


git_main()
{
   log_debug "::: git :::"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ]           && . mulle-bootstrap-scripts.sh


   while :
   do
      if [ "$1" = "-h" -o "$1" = "--help" ]
      then
         git_usage
      fi

      break
   done

   if dir_has_files "${REPOS_DIR}"
   then
      log_fluff "Will git $* clones " >&2
   else
      log_verbose "There is nothing to run git over."
      return 0
   fi

   run_git "$@"
}


run_git()
{
   local i

   IFS="
"
   for i in `all_repository_directories_from_repos`
   do
      IFS="${DEFAULT_IFS}"

      if [ -d "${i}/.git" -o -d "${i}/refs" ]
      then
         log_info "### $i:"
         (
            cd "$i" ;
            exekutor git ${GITFLAGS} "$@" ${GITOPTIONS}  >&2
         ) || fail "git failed"
         log_info
      fi
   done

   IFS="${DEFAULT_IFS}"
}


_validate_download()
{
   local filename="$1"
   local options="$2"

   local checksum
   local expected

   case "${options}" in
      *shasum256*)
         case "${UNAME}" in
            mingw)
               log_fluff "mingw does not support shasum" # or does it ?
            ;;

            *)
               log_verbose "Validating ${C_MAGENTA}${C_BOLD}${filename}${C_INFO} ..."


               expected="`echo "${options}" | sed -n 's/shasum256=\([a-f0-9]*\).*/\1/p'`"
               checksum="`shasum -a 256 -p "${filename}" | awk '{ print $1 }'`"
               if [ "${expected}" != "${checksum}" ]
               then
                  fail "${filename} sha256 is ${checksum}, not ${expected} as expected"
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
# b) create a temporary directory, extract into it
# c) move it into place
#

tar_unpack()
{
   [ $# -ge 7 ] || internal_fail "tar_unpack: parameters missing"

#   local reposdir="$1"
   local name="$2"
   local url="$3"
#   local branch="$4"
#   local scm="$5"
#   local tag="$6"
   local stashdir="$7"

   local tmpdir
   local archive
   local download
   local options
   local archivename

   download="`basename "${url}"`"
   archive="${download}"

   # remove .tar (or .zip et friends)
   archivename="`extension_less_basename "${download}"`"
   case "${archivename}" in
      *.tar)
         archivename="`extension_less_basename "${archivename}"`"
      ;;
   esac

   rmdir_safer "${name}.tmp"
   tmpdir="`exekutor mktemp -d "${name}.tmp"`" || exit 1
   (
      exekutor cd "${tmpdir}" || exit 1

      log_info "Downloading ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."

      exekutor curl -O -L ${CURLOPTIONS} "${url}" || exit 1
      _validate_download "${download}" "${SCM_OPTIONS}" || exit 1

      case "${url}" in
         *.zip)
            exekutor unzip "${download}" || exit 1
            archive="`basename "${download}" .zip`"
            exekutor rm "${download}" || exit 1
         ;;
      esac

      case "${UNAME}" in
         darwin)
         ;;

         *)
            case "${url}" in
               *.gz)
                  options="-z"
               ;;

               *.bz2)
                  options="-j"
               ;;

               *.x)
                  options="-J"
               ;;
            esac
         ;;
      esac

      log_verbose "Extracting ${C_MAGENTA}${C_BOLD}${archive}${C_INFO} ..."

      exekutor tar xf ${TAROPTIONS} ${options} "${archive}" || exit 1
      exekutor rm "${archive}" || exit 1
   ) || exit 1

   _move_stuff "${tmpdir}" "${stashdir}" "${archivename}" "${name}"
}


zip_unpack()
{
   [ $# -ge 7 ] || internal_fail "zip_unpack: parameters missing"

#   local reposdir="$1"
   local name="$2"
   local url="$3"
#   local branch="$4"
#   local scm="$5"
#   local tag="$6"
   local stashdir="$7"

   local tmpdir
   local download
   local archivename

   download="`basename --  "${url}"`"
   archivename="`extension_less_basename "${download}"`"

   rmdir_safer "${name}.tmp"
   tmpdir="`exekutor mktemp -d "${name}.tmp"`" || exit 1
   (
      exekutor cd "${tmpdir}" || exit 1

      log_info "Downloading ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."

      exekutor curl -O -L ${CURLOPTIONS} "${url}" || exit 1
      _validate_download "${download}" "${SCM_OPTIONS}" || exit 1

      log_verbose "Extracting ${C_MAGENTA}${C_BOLD}${download}${C_INFO} ..."

      exekutor unzip "${download}" || exit 1
      exekutor rm "${download}" || exit 1
   ) || exit 1

   _move_stuff "${tmpdir}" "${stashdir}" "${archivename}" "${name}"
}



scm_initialize()
{
   log_debug ":scm_initialize:"
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ] && . mulle-bootstrap-repositories.sh
   :
}

scm_initialize
