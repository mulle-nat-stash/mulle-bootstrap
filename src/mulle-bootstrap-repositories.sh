#! /bin/sh
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
remember_stash_of_repository()
{
   local clone="$1" ; shift

   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   [ -z "${clone}" ]    && internal_fail "clone is missing"
   [ -z "${reposdir}" ] && internal_fail "reposdir is missing"
   [ -z "${name}" ]     && internal_fail "name is missing"
   [ -z "${stashdir}" ] && internal_fail "stashdir is missing"
   [ $# -ne 7  ]        && internal_fail "parameter error"

   local content
   local filepath

   mkdir_if_missing "${reposdir}"
   filepath="${reposdir}/${name}"

   content="${stashdir}
${clone}"  ## a clone line

   log_fluff "Remembering repository \"${name}\" via \"${filepath}\""

   redirect_exekutor "${filepath}" echo "${content}"
}


_clone_of_reposdir_file()
{
   tail -1 "${1}"
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


clone_of_embedded_repository()
{
   local reposdir="$1"
   local name="$2"

   clone_of_repository "${EMBEDDED_REPOS_DIR}" "${name}"
}


_stash_of_reposdir_file()
{
   head -1 "$1"
}


stash_of_repository()
{
   local reposdir="$1"
   local name="$2"

   [ -z "${reposdir}" ] && internal_fail "Empty reposdir"
   [ -z "${name}" ]     && internal_fail "Empty name"

   local reposfilepath

   reposfilepath="${reposdir}/${name}"
   if [ -f "${reposfilepath}" ]
   then
      _stash_of_reposdir_file "${reposfilepath}"
   else
      log_fluff "No stash found for ${name} in ${reposdir}"
   fi
}


all_repository_names()
{
   ls -1 "${REPOS_DIR}/" 2> /dev/null
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

      stash="`stash_of_repository "${reposdir}" "${name}"`"
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


all_repository_stashes()
{
   _all_repository_stashes "${REPOS_DIR}"
}



#
# Walkers
#

walk_check()
{
   local name="$1" ; shift
   local stashdir="$1"; shift
   local permissions="$1"; shift

   local match

   if [ $# -ne 0 ]
   then
      # cat is for -e
      match="`echo "$@" | fgrep -s -x "${name}"`"
      if [ "${match}" = "${name}" ]
      then
         return 1
      fi
   fi

   if [ -L "${stashdir}" ]
   then
      # cat is for -e
      match="`echo "${permissions}" | fgrep -s -x "symlink"`"
      if [ -z "${match}" ]
      then
         log_verbose "${stashdir} is a symlink, skipped"
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
            log_info "Repository expected in \"${stashdir}\" is not yet fetched, skipped"
            return 1
         fi
      fi
   fi

   return 0
}


_walk_repositories()
{
   local permissions
   local callback
   local reposdir
   local clones

   clones="$1"
   shift

   callback="$1"
   shift
   permissions="$1"
   shift
   reposdir="$1"
   shift

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

      parse_clone "${clone}"

      if ! walk_check "${name}" "${stashdir}" "${permissions}" "$@"
      then
         continue
      fi

      #
      # callbacks for deep embedded must be like
      # from project directory
      #
      (
         ${callback} "${reposdir}" \
                     "${name}" \
                     "${url}" \
                     "${branch}" \
                     "${scm}" \
                     "${tag}" \
                     "${stashdir}"
      ) || exit 1
   done

   IFS="${DEFAULT_IFS}"
}


walk_repositories()
{
   local settingname="$1";shift

   local clones

   clones="`read_root_setting "${settingname}"`"
   _walk_repositories "${clones}" "$@"
}


_walk_deep_embedded_repositories()
{
   local clones="$1"; shift
   local callback="$1" ; shift
   local permissions="$1" ; shift

   # rest are repository names or empty if all
   local match

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

      parse_clone "${clone}"

      if ! walk_check "${name}" "${stashdir}" "${permissions}" "$@"
      then
         continue
      fi

      # now grab embedded of that
      (
         local embedded_clones
         local filepath

         filepath="${BOOTSTRAP_DIR}.auto/.deep/${name}.d/embedded_repositories"
         embedded_clones="`_read_setting "${filepath}" "embedded_repositories"`"

         STASHES_ROOT_DIR="${stashdir}" ;
         reposdir="${REPOS_DIR}/.deep/${name}.d"
         _walk_repositories "${embedded_clones}" "${callback}" "${permissions}" "${reposdir}"
      ) || exit 1
   done

   IFS="${DEFAULT_IFS}"
}


walk_deep_embedded_repositories()
{
   local clones

   clones="`read_root_setting "repositories"`"
   _walk_deep_embedded_repositories "${clones}" "$@"
}


# deal with stuff like
# foo
# https://www./foo.git
# host:foo
#
_canonical_clone_name()
{
   local  url
   local name

   url="$1"
   # cut off scheme part
   case "$url" in
      *:*)
         url="`echo "$@" | sed 's/^\(.*\):\(.*\)/\2/'`"
      ;;
   esac

   name="`extension_less_basename "$url"`"

   case "${name}" in
      .*)
         fail "clone name can't start with a '.'"
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
   local url="$1"
   local name="$2"
   local dstdir="$3"

   # could move this to .auto stage too...

   local relpath

   relpath="${dstdir}"
   if [ -z "${relpath}" ]
   then
      relpath="`path_concat "${STASHES_DEFAULT_DIR}" "${name}"`"
   fi

   relpath="`path_concat "${STASHES_ROOT_DIR}" "${relpath}"`"

   path_relative_to_root_dir "${relpath}"
}


# this sets values to variables that should be declared
# in the caller!
#
#   # parse_clone
#   local name       # name of the clone
#   local url        # url of clone
#   local branch
#   local scm
#   local tag
#   local stashdir   # dir of repository (usually inside stashes)
#
parse_clone()
{
   local clone="$1"

   [ -z "${clone}" ] && internal_fail "parse_clone: clone is empty"

   local dstdir

   #
   # expansion is now done during already during .auto creation
   # clone="`expanded_variables "${1}"`"
   #
   IFS=";" read -r url dstdir branch scm tag <<< "${clone}"

   if [ "${OPTION_IGNORE_BRANCH}" = "YES" ]
   then
      branch=""
   fi

   case "${url}" in
      */\.\./*|\.\./*|*/\.\.|\.\.)
         fail "Relative urls like \"${url}\" don't work (anymore).\nTry \"-y fetch --no-symlink-creation\" instead"
      ;;
   esac

   name="`_canonical_clone_name "${url}"`"
   stashdir="`computed_stashdir "${url}" "${name}" "${dstdir}"`"

   # make sure destination doesn't stray outside of project
   case "${stashdir}" in
      ${DEPENDENCIES_DIR}*|${ADDICTIONS_DIR}*|${BOOTSTRAP_DIR}*)
         fail "${dstdir} is a suspicious path in \"${clone}\""
      ;;

      "")
         internal_fail "Diffpath is empty for \"${clone}\""
      ;;

      \.\.*)
         fail "Repository destination \"${dstdir}\" is outside of project directory ($diffpath) (\"${clone}\")"
      ;;
   esac

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" ]
   then
      log_trace2 "URL:      \"${url}\""
      log_trace2 "DSTDIR:   \"${dstdir}\""
      log_trace2 "NAME:     \"${name}\""
      log_trace2 "SCM:      \"${scm}\""
      log_trace2 "BRANCH:   \"${branch}\""
      log_trace2 "TAG:      \"${tag}\""
      log_trace2 "STASHDIR: \"${stashdir}\""
   fi

   [ "${url}" = "Already up-to-date." ] && internal_fail "fail"

   [ -z "${url}" ]      && internal_fail "url is empty ($clone)"
   [ -z "${name}" ]     && internal_fail "name is empty ($clone)"
   [ -z "${stashdir}" ] && internal_fail "stashdir is empty ($clone)"

   :
}


#
# walk over clones given as parameters
# call callback
#
walk_clones()
{
   local callback=$1; shift
   local reposdir=$1; shift

   local name
   local url
   local branch
   local scm
   local tag
   local stashdir
   local clone

   IFS="
"
   for clone in $*
   do
      IFS="${DEFAULT_IFS}"

      parse_clone "${clone}"

      "${callback}" "${reposdir}" \
                    "${name}" \
                    "${url}" \
                    "${branch}" \
                    "${scm}" \
                    "${tag}" \
                    "${stashdir}"
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
         fail "fetch first before updating"
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

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_MERGE_LOG" = "YES"  ]
   then
      log_trace2 "Merging \"${additions}\" into \"${contents}\""
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

      url="`_url_part_from_clone "${clone}"`"
      map="`assoc_array_set "${map}" "${url}" "${clone}"`"
   done

   IFS="
"
   for clone in ${contents}
   do
      IFS="${DEFAULT_IFS}"

      url="`_url_part_from_clone "${clone}"`"
      map="`assoc_array_set "${map}" "${url}" "${clone}"`"
   done
   IFS="${DEFAULT_IFS}"

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_MERGE_LOG" = "YES"  ]
   then
      log_trace2 "----------------------"
      log_trace2 "merged \"repositories\":"
      log_trace2 "----------------------"
      log_trace2 "`assoc_array_all_values "${map}"`"
      log_trace2 "----------------------"
   fi
   assoc_array_all_values "${map}"
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
   local output

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_MERGE_LOG" = "YES"  ]
   then
      log_trace2 "Uniquing \"${input}\" with \"${another}\""
   fi

   map=""
   IFS="
"
   for clone in ${another}
   do
      IFS="${DEFAULT_IFS}"

      url="`_url_part_from_clone "${clone}"`"
      map="`assoc_array_set  "${map}" "${url}" "${clone}"`"
   done

   output=""
   IFS="
"
   for clone in ${input}
   do
      IFS="${DEFAULT_IFS}"

      url="`_url_part_from_clone "${clone}"`"
      uniqued="`assoc_array_get "${map}" "${url}"`"
      output="`add_line "${output}" "${uniqued:-${clone}}"`"
   done
   IFS="${DEFAULT_IFS}"

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_MERGE_LOG" = "YES"  ]
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
   local clones
   local stop
   local refreshed
   local match
   local dependency_map
   local clone

   [ -z "${MULLE_BOOTSTRAP_DEPENDENY_RESOLVE_SH}" ] && . mulle-bootstrap-dependency-resolve.sh

   refreshed=""
   dependency_map=""

   #
   # read from .auto
   #
   clones="`read_root_setting "repositories"`"
   if [ -z "${clones}" ]
   then
      return
   fi

   IFS="
"
   for clone in ${clones}
   do
      IFS="${DEFAULT_IFS}"

      match="`echo "${refreshed}" | fgrep -s -x "${clone}"`"
      if [ ! -z "${match}" ]
      then
         continue
      fi
      refreshed="${refreshed}
${clone}"

      if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_MERGE_LOG" = "YES"  ]
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
         if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_MERGE_LOG" = "YES"  ]
         then
            log_trace2 "${stashdir} not fetched yet"
         fi
         continue
      fi

      local sub_repos
      local filename

      filename="${stashdir}/.bootstrap/repositories"
      sub_repos="`_read_expanded_setting "${filename}" "repositories" "" "${stashdir}/.bootstrap"`"
      if [ ! -z "${sub_repos}" ]
      then
         sub_repos="`unique_repository_contents "${sub_repos}" "${clones}"`"
         dependency_map="`dependency_add_array "${dependency_map}" "${clone}" "${sub_repos}"`"
         if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_MERGE_LOG" = "YES"  ]
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
      if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_MERGE_LOG" = "YES"  ]
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

   log_fluff ":mulle_repositories_initialize:"

   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   :
}

mulle_repositories_initialize
