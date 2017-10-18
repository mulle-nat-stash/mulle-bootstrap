#! /usr/bin/env bash
#
#   Copyright (c) 2016 Nat! - Mulle kybernetiK
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
#   POSSIBILITY OF SUCH DAMAGE.
#

MULLE_BOOTSTRAP_REPOSITORIES_SH="included"



# ####################################################################
#                       repository file
# ####################################################################
#

#
# deal with contents of files in .bootstrap.repos
#
#
# memorize where we placed a repository, need URL to identify
# and the subdir, where it was stored
#
# store it inside the possibly recursed dstprefix dependency
#
remember_repository()
{
   local clone="$1"
   local reposdir="$2"  # ususally .bootstrap.repos
   local name="$3"      # name of the clone
   local parentclone="$4"

   [ -z "${clone}" ]    && internal_fail "clone is missing"
   [ -z "${reposdir}" ] && internal_fail "reposdir is missing"
   [ -z "${name}" ]     && internal_fail "name is missing"

   local content
   local filepath

   mkdir_if_missing "${reposdir}"
   filepath="${reposdir}/${name}"

   content="${clone}
${parentclone}"  ## a clone line

   log_fluff "Remembering repository \"${name}\" via \"${filepath}\""

   redirect_exekutor "${filepath}" echo "${content}"
}


forget_repository()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone

   [ -z "${reposdir}" ] && internal_fail "reposdir is missing"
   [ -z "${name}" ]     && internal_fail "name is missing"

   local content
   local filepath

   filepath="${reposdir}/${name}"
   log_fluff "Forgetting about repository \"${name}\" via \"${filepath}\""
   remove_file_if_present "${filepath}"
}


_clone_of_reposdir_file()
{
   sed -n '1p' "${1}"
}


_parentclone_of_reposdir_file()
{
   sed -n '2p' "$1"
}


clone_of_repository()
{
   local reposdir
   local name

   reposdir="$1"
   name="$2"

   [ -z "${name}" ] && internal_fail "Empty parameter"

   local relpath

   relpath="${reposdir}/${name}"
   if [ -f "${relpath}" ]
   then
      _clone_of_reposdir_file "${relpath}"
   fi
}


_stash_of_reposdir_file()
{
   local clone

   clone="`_clone_of_reposdir_file "$@"`" || exit 1
   _dstdir_part_from_clone "${clone}"
}


stash_of_repository()
{
   local clone

   clone="`clone_of_repository "$@"`" || exit 1
   _dstdir_part_from_clone "${clone}"
}


parentclone_of_repository()
{
   local reposdir="$1"
   local name="$2"

   [ -z "${reposdir}" ] && internal_fail "Empty reposdir"
   [ -z "${name}" ]     && internal_fail "Empty name"

   local reposfilepath

   reposfilepath="${reposdir}/${name}"
   if [ -f "${reposfilepath}" ]
   then
      _parentclone_of_reposdir_file "${reposfilepath}"
   else
      log_fluff "No stash found for ${name} in ${reposdir}"
   fi
}


all_repository_names()
{
   ( cd "${REPOS_DIR}" ; ls -1 ) 2> /dev/null
}


_all_repository_stashes()
{
   local reposdir="$1"

   [ -z "${reposdir}" ] && internal_fail "repos is empty"

   local name
   local stash

   IFS="
"
   for name in `ls -1 "${reposdir}/" 2> /dev/null`
   do
      IFS="${DEFAULT_IFS}"

      # somewhat a hack, since name is actually a subpath
      stash="`stash_of_repository "${reposdir}" "${name}"`" || exit 1
      if [ ! -z "${stash}" ]
      then
         if [ -d "${stash}" ]
         then
            echo "${stash}"
         fi
      fi
   done

   IFS="${DEFAULT_IFS}"
}


_all_deep_embedded_repository_stashes()
{
   local reposdir="$1"

   [ -z "${reposdir}" ] && internal_fail "repos is empty"

   local name
   local stash
   local deep

   IFS="
"
   for deep in `ls -1d "${reposdir}/.deep"/*.d 2> /dev/null`
   do
      for name in `ls -1 "${reposdir}/${deep}"/* 2> /dev/null`
      do
         IFS="${DEFAULT_IFS}"

         # somewhat a hack, since name is actually a subpath
         stash="`stash_of_repository "${reposdir}" "${name}"`" || exit 1
         if [ ! -z "${stash}" ]
         then
           if [ -d "${stash}" ]
           then
              echo "${stash}"
           fi
         fi
      done
   done

   IFS="${DEFAULT_IFS}"
}



all_repository_stashes()
{
   _all_repository_stashes "${REPOS_DIR}"
}


all_embedded_repository_stashes()
{
   _all_repository_stashes "${EMBEDDED_REPOS_DIR}"
}


all_deep_embedded_repository_stashes()
{
   _all_deep_embedded_repository_stashes "${REPOS_DIR}"
}


_get_all_repos_headers()
{
   local reposdir="$1"

   if ! dir_has_files "${reposdir}" "f"
   then
      return
   fi

   local i

   for i in "${reposdir}"/*
   do
      log_debug "repository: $i"
      head -1 "$i"
   done
}


_get_all_repos_minions()
{
   log_debug "_get_all_repos_minions" "$@" "($PWD)"

   _get_all_repos_headers "$@" | egrep '^[^;]*;[^;]*;[^;]*;minion'
}


_get_all_repos_clones()
{
   log_debug "_get_all_repos_clones" "$@" "($PWD)"

   _get_all_repos_headers "$@" | egrep -v '^[^;]*;[^;]*;[^;]*;minion'
}


#
# Walkers
#
# Possible permissions: "symlink\nmission\nmissing"
#
walk_check()
{
   log_debug "walk_check" "$@"

   local stashdir="$1"
   local permissions="$2"

   local match

   if [ -L "${stashdir}" ]
   then
      # this not being in permissions makes things easier
      if [ "${MULLE_FLAG_FOLLOW_SYMLINKS}" != "YES" ]
      then
         log_verbose "\"${stashdir}\" is a symlink, skipped"
         return 1
      fi
   else
      if [ ! -d "${stashdir}" ]
      then
         if [ -e "${stashdir}" ]
         then
            fail "\"${stashdir}\" is unexpectedly not a directory, move it away"
         fi

         match="`echo "${permissions}" | fgrep -s -x "missing"`"
         if [ -z "${match}" ]
         then
            log_verbose "Repository expected in \"${stashdir}\" is not yet fetched, skipped"
            return 1
         fi
      fi
   fi

   if is_minion_bootstrap_project "${stashdir}"
   then
      match="`echo "${permissions}" | fgrep -s -x "minion"`"
      if [ -z "${match}" ]
      then
         log_verbose "\"${stashdir}\" is a minion, skipped"
         return 1
      fi
   fi

   return 0
}


_walk_minions()
{
   log_debug "_walk_minions" "$@"

   local minions="$1"; shift
   local callback="$1"; shift
   local permissions="$1"; shift
   local reposdir="$1"; shift

   [ -z "${callback}" ]  && internal_fail "callback is empty"

   # parse_clone
   local name
   local url
   local branch
   local scm
   local tag
   local stashdir

   permissions="`add_line "${permissions}" "minions"`"

   IFS="
"
   for minion in ${minions}
   do
      IFS="${DEFAULT_IFS}"

      [ -z "${minion}" ] && continue

      name="${minion}"
      url="${minion}"
      stashdir="${minion}"

      if ! walk_check "${stashdir}" "${permissions}"
      then
         continue
      fi

      ${callback} "${reposdir}" \
                  "${name}" \
                  "${url}" \
                  "${branch}" \
                  "${scm}" \
                  "${tag}" \
                  "${stashdir}" \
                  "$@"
   done

   IFS="${DEFAULT_IFS}"
}

#
# _walk_repositories clones,callback,permissions,reposdir ...
#
_walk_repositories()
{
   log_debug "_walk_repositories" "$@"

   local clones="$1"; shift
   local callback="$1"; shift
   local permissions="$1"; shift
   local reposdir="$1"; shift

   [ -z "${callback}" ]  && internal_fail "callback is empty"

   # parse_clone
   local name
   local url
   local branch
   local scm
   local tag
   local stashdir

   IFS="
"
   for clone in ${clones}
   do
      IFS="${DEFAULT_IFS}"

      [ -z "${clone}" ] && continue

      parse_clone "${clone}"

      if ! walk_check "${stashdir}" "${permissions}"
      then
         continue
      fi

      ${callback} "${reposdir}" \
                  "${name}" \
                  "${url}" \
                  "${branch}" \
                  "${scm}" \
                  "${tag}" \
                  "${stashdir}" \
                  "$@"
   done

   IFS="${DEFAULT_IFS}"
}



_deep_walk_repos_trampoline()
{
   log_debug "_deep_walk_repos_trampoline" "$@"

   local reposdir="$1"; shift  # ususally .bootstrap.repos
   local name="$1"; shift      # name of the clone
   local url="$1"; shift       # URL of the clone
   local branch="$1"; shift    # branch of the clone
   local scm="$1"; shift       # scm to use for this clone
   local tag="$1"; shift       # tag to checkout of the clone
   local stashdir="$1"; shift  # stashdir of this clone (absolute or relative to $PWD)

   local callback="$1"; shift
   local permissions="$1"; shift

   (
      local embedded_clones
      local filepath
      local reposdir

      reposdir="${REPOS_DIR}/.deep/${name}.d"

      embedded_clones="`_get_all_repos_clones "${reposdir}"`"

      PARENT_REPOSITORY_NAME="${name}"
      PARENT_CLONE="${clone}"
      STASHES_DEFAULT_DIR=""
      STASHES_ROOT_DIR="${stashdir}"

      _walk_repositories "${embedded_clones}" \
                         "${callback}" \
                         "${permissions}" \
                         "${reposdir}" \
                         "$@"
   ) || exit 1
}


_deep_walk_auto_trampoline()
{
   log_debug "_deep_walk_auto_trampoline" "$@"

   local reposdir="$1"; shift  # ususally .bootstrap.repos
   local name="$1"; shift      # name of the clone
   local url="$1"; shift       # URL of the clone
   local branch="$1"; shift    # branch of the clone
   local scm="$1"; shift       # scm to use for this clone
   local tag="$1"; shift       # tag to checkout of the clone
   local stashdir="$1"; shift  # stashdir of this clone (absolute or relative to $PWD)

   local callback="$1"; shift
   local permissions="$1"; shift

   (
      local embedded_clones
      local filepath
      local reposdir

      reposdir="${REPOS_DIR}/.deep/${name}.d"
      filepath="${BOOTSTRAP_DIR}.auto/.deep/${name}.d/embedded_repositories"
      # sigh have to use read_setting here
      embedded_clones="`read_setting "${filepath}"`"

      PARENT_REPOSITORY_NAME="${name}"
      PARENT_CLONE="${clone}"

      STASHES_DEFAULT_DIR=""
      STASHES_ROOT_DIR="${stashdir}"

      _walk_repositories "${embedded_clones}" \
                         "${callback}" \
                         "${permissions}" \
                         "${reposdir}" \
                         "$@"
   ) || exit 1
}



#
# walk_auto_repositories settingname,callback,permissions,reposdir ...
#
walk_auto_repositories()
{
   log_debug "walk_auto_repositories" "$@"

   local settingname="$1";shift

   local clones

   clones="`read_root_setting "${settingname}"`"
   _walk_repositories "${clones}" "$@"
}


#
# walk_repos_repositories unused,callback,permissions,reposdir ...
#
walk_repos_repositories()
{
   log_debug "walk_repos_repositories" "$@"

   shift

   local reposdir="$3"

   local clones

   clones="`_get_all_repos_clones "${reposdir}"`"
   _walk_repositories "${clones}" "$@"
}


#
# walk_auto_deep_embedded_repositories callback,permissions,reposdir ...
#
walk_auto_deep_embedded_repositories()
{
   log_debug "walk_auto_deep_embedded_repositories" "$@"

   local callback="$1";shift
   local permissions="$1";shift
   local reposdir="$1";shift

   local clones

   clones="`read_root_setting "repositories"`"
   _walk_repositories "${clones}" \
                      _deep_walk_auto_trampoline \
                      "${permissions}" \
                      "${reposdir}" \
                      "${callback}" \
                      "$@"
}

#
# walk_repos_deep_embedded_repositories callback,permissions,reposdir ...
#
walk_repos_deep_embedded_repositories()
{
   log_debug "walk_repos_deep_embedded_repositories" "$@"

   local callback="$1";shift
   local permissions="$1";shift
   local reposdir="$1";shift

   local clones

   clones="`_get_all_repos_clones "${reposdir}"`"
   _walk_repositories "${clones}" \
                      _deep_walk_repos_trampoline \
                      "${permissions}" \
                      "${reposdir}" \
                      "${callback}" \
                      "$@"
}


#
# walk_repos_deep_embedded_minion_repositories callback,permissions,reposdir ...
#
walk_repos_deep_embedded_minion_repositories()
{
   log_debug "walk_repos_deep_embedded_minion_repositories" "$@"

   local callback="$1"; shift
   local permissions="$1"; shift
   local reposdir="$1"; shift

   local minions

   minions="`_get_all_repos_minions "${reposdir}"`"
   _walk_repositories "${minions}" \
                      _deep_walk_repos_trampoline \
                      "${permissions}" \
                      "${reposdir}" \
                      "${callback}" \
                      "$@"
}


#
# walk_auto_minions callback,permissions,reposdir ...
#
walk_auto_minions()
{
   log_debug "walk_auto_minions" "$@"

   local minions

   minions="`read_root_setting "minions"`"
   _walk_minions "${minions}" "$@"
}


#
# walk_repos_minions callback,permissions,reposdir ...
#
walk_repos_minions()
{
   log_debug "walk_repos_minions" "$@"

   local reposdir="$3"

   local minions

   minions="`_get_all_repos_minions "${reposdir}"`"
   _walk_minions "${minions}" "$@"
}




#
# walk over clones just give raw values
# no checks
#
walk_raw_clones()
{
   local clones=$1; shift
   local callback=$1; shift

   local url
   local dstdir
   local branch
   local scm
   local tag

   log_debug "Walking raw \"${clones}\" with \"${callback}\""

   [ -z "${callback}" ] && internal_fail "callback missing"

   IFS="
"
   for clone in ${clones}
   do
      IFS="${DEFAULT_IFS}"

      parse_raw_clone "${clone}"

      "${callback}" "${url}" \
                    "${dstdir}" \
                    "${branch}" \
                    "${scm}" \
                    "${tag}" \
                    "$@"
   done

   IFS="${DEFAULT_IFS}"
}


walk_root_setting()
{
   local name=$1; shift
   local callback=$1; shift

   [ -z "${callback}" ] && internal_fail "callback missing"

   local lines

   lines="`read_root_setting "${name}"`"

   log_debug "Walking setting \"${name}\" with \"${callback}\""

   IFS="
"
   for line in ${lines}
   do
      IFS="${DEFAULT_IFS}"

      "${callback}" "${line}" "$@"
   done

   IFS="${DEFAULT_IFS}"
}


# deal with stuff like
# foo
# https://www./foo.git
# host:foo
#
_canonical_clone_name()
{
   local url
   local name

   url="$1"
   # cut off scheme part
   case "$url" in
      *:*)
         url="`echo "$@" | sed 's/^\(.*\):\(.*\)/\2/'`"
      ;;
   esac

   # github/gitlist urls (hacquish)
   # cut off last two path components
   case "$url" in
      */archive/*.gz|*/archive/*.zip|*/tarball/*|*/zipball/*)
         url="`dirname -- "${url}"`"
         url="`dirname -- "${url}"`"
      ;;
   esac

   name="`basename -- "${url}"`"
   name="`echo "${name%%.*}"`"

   case "${name}" in
      "")
         fail "clone name can't be empty"
      ;;

      .*)
         fail "clone name \"${name}\" can't start with a '.'"
      ;;
   esac

   echo "${name}"
}


_url_part_from_clone()
{
   echo "$@" | cut '-d;' -f 1
}


_dstdir_part_from_clone()
{
   echo "$@" | cut -s '-d;' -f 2
}


_branch_part_from_clone()
{
   echo "$@" | cut -s '-d;' -f 3
}


_scm_part_from_clone()
{
   echo "$@" | cut -s '-d;' -f 4
}


_tag_part_from_clone()
{
   echo "$@" | cut -s '-d;' -f 5
}


#
# Always use URL name, even if stashdir renames it
#
_canonical_name_from_clone()
{
   local url

   url="`_url_part_from_clone "$@"`"
   _canonical_clone_name "${url}"
}


path_relative_to_root_dir()
{
   local relpath="$1"

   [ -z "${ROOT_DIR}" ] && internal_fail "ROOT_DIR not set"
   [ -z "${relpath}" ]  && internal_fail "relpath not set"

   local apath

   apath="${ROOT_DIR}/${relpath}"

   # make sure destination doesn't stray outside of project
   _relative_path_between "${apath}" "${ROOT_DIR}"
}


computed_stashdir()
{
   local name="$1"
   local dstdir="$2"

   if is_minion_bootstrap_project "${name}"
   then
      dstdir="${name}"
   else
      if [ -z "${dstdir}" ]
      then
         dstdir="`path_concat "${STASHES_DEFAULT_DIR}" "${name}"`"
      fi
      dstdir="`path_concat "${STASHES_ROOT_DIR}" "${dstdir}"`"
   fi

   path_relative_to_root_dir "${dstdir}"
}


#
# Read the CVS from the .repositories file
#
# This function sets values of variables that should be declared
# in the caller!
#
#   # parse_raw_clone
#   local url        # url of clone
#   local dstdir
#   local branch
#   local scm
#   local tag
#
parse_raw_clone()
{
   local clone="$1"

   [ -z "${clone}" ] && internal_fail "parse_raw_clone: clone is empty"

   IFS=";" read -r url dstdir branch scm tag <<< "${clone}"
}


#   # process_raw_clone
#   local name        # name of clone
process_raw_clone()
{
   name="`_canonical_clone_name "${url}"`" || exit 1

   # memo this is done in .auto already
   # stashdir="`computed_stashdir "${name}" "${dstdir}"`"
}


# this sets values to variables that should be declared
# in the caller!
#
# this sets values to variables that should be declared
# in the caller!
#
#   # parse_clone
#   local name
#   local url
#   local branch
#   local scm
#   local tag
#   local stashdir
#
# expansion is now done during .auto creation
# clone="`expanded_variables "${1}"`"
#
parse_clone()
{
   local clone="$1"

   local dstdir

   parse_raw_clone "${clone}"
   process_raw_clone

   stashdir="${dstdir}"

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" ]
   then
      log_trace2 "URL:      \"${url}\""
      log_trace2 "NAME:     \"${name}\""
      log_trace2 "SCM:      \"${scm}\""
      log_trace2 "BRANCH:   \"${branch}\""
      log_trace2 "TAG:      \"${tag}\""
      log_trace2 "STASHDIR: \"${stashdir}\""
   fi

   # this is done  during auto already
   # case "${stashdir}" in
   #    ..*|~*|/*)
   #     fail "dstdir \"${dstdir}\" is invalid ($clone)"
   #    ;;
   # esac

   [ -z "${url}" ]      && internal_fail "url is empty ($clone)"
   [ -z "${name}" ]     && internal_fail "name is empty ($clone)"
   [ -z "${stashdir}" ] && internal_fail "stashdir is empty ($clone)"
   :
}


names_from_repository_file()
{
   local filename="$1"

   local clones

   local url        # url of clone
   local dstdir
   local name
   local branch
   local scm
   local tag

   clones="`read_setting "${filename}"`"

   IFS="
"
   for clone in ${clones}
   do
      IFS="${DEFAULT_IFS}"

      parse_raw_clone "${clone}"
      process_raw_clone

      if [ ! -z "${name}" ]
      then
         echo "${name}"
      fi
   done

   IFS="${DEFAULT_IFS}"
}


#
# read repository file, properly do expansions
# replace branch with override if needed
#
read_repository_file()
{
   local srcfile="$1"
   local delete_dstdir="$2"

   local srcbootstrap
   local clones
   local empty_expansion_is_error

   srcbootstrap="`dirname -- "${srcfile}"`"

   clones="`read_expanded_setting "$srcfile" "" "${srcbootstrap}"`"

   local url        # url of clone
   local dstdir
   local branch
   local scm
   local tag
   local name


   IFS="
"
   for clone in ${clones}
   do
      IFS="${DEFAULT_IFS}"

      if [ -z "${clone}" ]
      then
         continue
      fi

      parse_raw_clone "${clone}"
      process_raw_clone

      case "${url}" in
         */\.\./*|\.\./*|*/\.\.|\.\.)
            fail "Relative urls like \"${url}\" don't work (anymore).\nTry \"-y fetch --no-symlink-creation\" instead"
         ;;
      esac

      case "${scm}" in
         symlink*)
            fail "You can't specify symlink in the repositories file yourself. Use -y flag"
         ;;
      esac

      branch="${OVERRIDE_BRANCH:-${branch}}"
      branch="${branch:-master}"

      if [ "${delete_dstdir}" = "YES" ]
      then
         dstdir=""
      fi

      dstdir="`computed_stashdir "${name}" "${dstdir}"`"
      scm="${scm:-git}"

      if [ "${MULLE_FLAG_LOG_MERGE}" = "YES" ]
      then
         log_trace "${url};${dstdir};${branch};${scm};${tag}"
      fi

      echo "${url};${dstdir};${branch};${scm};${tag}"
   done

   IFS="${DEFAULT_IFS}"
}


ensure_reposdir_directory()
{
   local reposdir

   reposdir="$1"
   if [ ! -d "${reposdir}" ]
   then
      if [ "${COMMAND}" = "update" ]
      then
         fail "You must fetch first before updating"
      fi
      mkdir_if_missing "${reposdir}"
   fi
}


#
# Merge two "repositories" files contents. Find duplicates by matching
# against URL
#
merge_repository_contents()
{
   local contents="$1"
   local additions="$2"

   local clone
   local map
   local url
   local name

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
   then
      log_trace2 "Merging repositories \"${additions}\" into \"${contents}\""
   fi

   #
   # additions may contain dstdir
   # we replace this with
   #
   # 1. if we are a master, with the name of the url
   # 2. we erase it
   #
   map=""
   IFS="
"
   for clone in ${additions}
   do
      IFS="${DEFAULT_IFS}"

      url="`_url_part_from_clone "${clone}"`" || internal_fail "_url_part_from_clone \"${url}\""
      name="`_canonical_clone_name "${url}"`" || internal_fail "_canonical_clone_name \"${url}\""

      if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
      then
         log_trace2 "${name}: ${clone}"
      fi

      map="`assoc_array_set "${map}" "${name}" "${clone}"`"
   done

   IFS="
"
   for clone in ${contents}
   do
      IFS="${DEFAULT_IFS}"

      url="`_url_part_from_clone "${clone}"`" || internal_fail "_url_part_from_clone \"${clone}\""
      name="`_canonical_clone_name "${url}"`" || internal_fail "_canonical_clone_name \"${url}\""

      if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
      then
         log_trace2 "${name}: ${clone}"
      fi

      map="`assoc_array_set "${map}" "${name}" "${clone}"`"
   done
   IFS="${DEFAULT_IFS}"

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
   then
      log_trace2 "----------------------"
      log_trace2 "merged \"repositories\":"
      log_trace2 "----------------------"
      log_trace2 "`assoc_array_all_values "${map}"`"
      log_trace2 "----------------------"
   fi
   assoc_array_all_values "${map}"
}


merge_repository_files()
{
   local srcfile="$1"
   local dstfile="$2"
   local delete_dstdir="${3:-NO}"

   [ -z "${srcfile}" ] && internal_fail "srcfile is empty"
   [ -z "${dstfile}" ] && internal_fail "dstfile is empty"

   log_fluff "Copying expanded \"repositories\" from \"${srcfile}\""

   local contents
   local additions

   contents="`cat "${dstfile}" 2> /dev/null || :`"
   additions="`read_repository_file "${srcfile}" "${delete_dstdir}"`" || fail "Failed to read repository file \"${srcfile}\""
   additions="`echo "${additions}"| sed 's/;*$//'`"
   additions="`merge_repository_contents "${contents}" "${additions}"`"

   redirect_exekutor "${dstfile}" echo "${additions}"
}


#
# take a list of repositories
# unique them with another list of repositories by url
# output uniqued list
#
# another:  b;b
# input:    b
# output:   b;b

unique_repository_contents()
{
   local input="$1"
   local another="$2"

   local clone
   local map
   local name
   local output

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
   then
      log_trace2 "Uniquing \"${input}\" with \"${another}\""
   fi

   map=""
   IFS="
"
   for clone in ${another}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -z "${clone}" ]
      then
         url="`_url_part_from_clone "${clone}"`" || internal_fail "_url_part_from_clone \"${clone}\""
         name="`_canonical_clone_name "${url}"`" || internal_fail "_canonical_clone_name \"${url}\""
         map="`assoc_array_set  "${map}" "${name}" "${clone}"`"
      fi
   done

   output=""
   IFS="
"
   for clone in ${input}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -z "${clone}" ]
      then
         url="`_url_part_from_clone "${clone}"`" || internal_fail "_url_part_from_clone \"${clone}\""
         name="`_canonical_clone_name "${url}"`" || internal_fail "_canonical_clone_name \"${url}\""
         uniqued="`assoc_array_get "${map}" "${name}"`"
         output="`add_line "${output}" "${uniqued:-${clone}}"`"
      fi
   done
   IFS="${DEFAULT_IFS}"

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
   then
      log_trace2 "----------------------"
      log_trace2 "uniqued \"repositories\":"
      log_trace2 "----------------------"
      log_trace2 "${output}"
      log_trace2 "----------------------"
   fi

   echo "${output}"
}


#
# Take an expanded .bootstrap.auto file and put the
# entries in proper order, possibly removing duplicates
# along the way
#
sort_repository_file()
{
   log_debug "sort_repository_file" "$@"

   local stop
   local match

   [ -z "${MULLE_BOOTSTRAP_DEPENDENCY_RESOLVE_SH}" ] && . mulle-bootstrap-dependency-resolve.sh

   log_info "Resolving dependencies..."

   #
   # read from .auto
   #
   local clones
   local auxclones


   clones="`read_root_setting "repositories"`"
   auxclones="`read_root_setting "additional_repositories"`"

   if [ -z "${clones}" -a -z "${auxclones}" ]
   then
      return
   fi

   local refreshed
   local dependency_map
   local clone

   refreshed=""
   dependency_map=""

   #
   # add auxclones first, they and there dependencies will be sorted
   # first, which is useful, because we often don't know who'se
   # depending on them in a master situation.
   #
   IFS="
"
   for clone in ${auxclones} ${clones}
   do
      IFS="${DEFAULT_IFS}"

      match="`echo "${refreshed}" | fgrep -s -x "${clone}"`"
      if [ ! -z "${match}" ]
      then
         continue
      fi
      refreshed="${refreshed}
${clone}"

      if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
      then
         log_trace2 "Sort is dealing with \"${clone}\" now"
      fi

      # avoid superflous updates

      local branch
      local stashdir
      local name
      local scm
      local tag
      local url
      local clone
      local dstdir

      parse_clone "${clone}"

      dependency_map="`dependency_add "${dependency_map}" "__ROOT__" "${clone}"`"

      #
      # dependency management, it could be nicer, but isn't.
      # Currently matches only URLs
      #

      if [ ! -d "${stashdir}" ]
      then
         if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
         then
            log_trace2 "${stashdir} not fetched yet"
         fi
         continue
      fi

      local sub_repos
      local filename

      filename="${stashdir}/.bootstrap/repositories"

      sub_repos="`read_repository_file "${filename}" "" "${stashdir}/.bootstrap"`"

      if [ ! -z "${sub_repos}" ]
      then
         sub_repos="`unique_repository_contents "${sub_repos}" "${clones}"`"
         dependency_map="`dependency_add_array "${dependency_map}" "${clone}" "${sub_repos}"`"
         if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
         then
            log_trace2 "add \"${clone}\" to __ROOT__ as dependencies"
            log_trace2 "add [ ${sub_repos} ] to ${clone} as dependencies"
         fi
      else
         log_fluff "${name} has no repositories"
      fi
   done

   IFS="${DEFAULT_IFS}"

   #
   # output true repository dependencies
   #
   local repositories

   repositories="`dependency_resolve "${dependency_map}" "__ROOT__" | fgrep -v -x "__ROOT__"`"
   if [ ! -z "${repositories}" ]
   then
      if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
      then
         log_trace2 "------------------------"
         log_trace2 "resolved \"repositories\":"
         log_trace2 "------------------------"
         log_trace2 "${repositories}"
         log_trace2 "------------------------"
      fi
      echo "${repositories}" > "${BOOTSTRAP_DIR}.auto/repositories"
   fi
}


mulle_repositories_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

   log_debug "mulle_repositories_initialize"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_ARRAY_SH}" ]             && . mulle-bootstrap-array.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]          && . mulle-bootstrap-settings.sh
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ]         && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ]   && . mulle-bootstrap-common-settings.sh
   :
}

mulle_repositories_initialize
