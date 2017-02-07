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

   log_fluff "Remember repository \"${name}\" via \"${filepath}\""

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
   local reposdir
   local name

   reposdir="$1"
   name="$2"

   clone_of_repository "${reposdir}/.embedded" "${name}"
}


_stash_of_reposdir_file()
{
   head -1 "$1"
}


stash_of_repository()
{
   local reposdir
   local name

   reposdir="$1"
   name="$2"

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


#
# Collect all stashes for embedded, normal and deep_embedded
#
_all_repository_stashes()
{
   local reposdir

   reposdir="$1"

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


all_embedded_repository_stashes()
{
   _all_repository_stashes "${REPOS_DIR}/.embedded"
}


all_deep_embedded_repository_stashes()
{
   local reposdir
   local stashes
   local stash

   IFS="
"
   stashes="`all_repository_stashes "${reposdir}"`"
   for stash in ${stashes}
   do
      IFS="${DEFAULT_IFS}"

      reposdir="stash/${REPOS_DIR}"
      all_embedded_repository_stashes "${reposdir}"
   done

   IFS="${DEFAULT_IFS}"
}


#
# but not deep embedded...
#
all_stashes()
{
   local reposdir
   local dstprefix

   reposdir="$1"
   dstprefix="$2"

   all_repository_stashes "${reposdir}"
   all_embedded_repository_stashes "${reposdir}" "${dstprefix}"
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


walk_repositories()
{
   local settingname
   local permissions
   local callback
   local reposdir

   settingname="$1"
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

   clones="`read_root_setting "${settingname}"`"

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
         if [ ! -z "${WALK_DIR_PWD}" ]
         then
            cd "${WALK_DIR_PWD}"
         fi

         ${callback} "${WALK_DIR_PREFIX}${reposdir}" \
                     "${name}" \
                     "${url}" \
                     "${branch}" \
                     "${scm}" \
                     "${tag}" \
                     "${WALK_DIR_PREFIX}${stashdir}"
      ) || exit 1
   done

   IFS="${DEFAULT_IFS}"
}


walk_deep_embedded_repositories()
{
   local settingname
   local permissions

   callback="$1"
   shift
   permissions="$1"
   shift

   # rest are repository names or empty if all
   local match

   # parse_clone
   local name
   local url
   local branch
   local scm
   local tag
   local stashdir

   clones="`read_root_setting "repositories"`"

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
         WALK_DIR_PREFIX="${stashdir}/"
         WALK_DIR_PWD="${PWD}"
         cd "${stashdir}" ;
         STASHES_DIR="" ;
         walk_repositories "embedded_repositories" "${callback}" "${permissions}" "${REPOS_DIR}/.embedded"
      ) || exit 1
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


_stashdir_part_from_clone()
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


# this sets values to variables that should be declared
# in the caller!
#
#   # parse_clone
#   local name   # name of the clone
#   local url    # url of clone
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

   clone="`expanded_variables "${1}"`"
   IFS=";" read -r url dstdir branch scm tag <<< "${clone}"

   if [ "${IGNORE_BRANCH}" = "YES" ]
   then
      branch=""
   fi

   case "${url}" in
      */\.\./*|\.\./*|*/\.\.|\.\.)
         fail "Relative urls like \"${url}\" don't work (anymore).\nTry \"-y fetch --no-symlink-creation\" instead"
      ;;
   esac

   local relpath

   name="`_canonical_clone_name "${url}"`"
   relpath="${dstdir}"
   if [ -z "${dstdir}" ]
   then
      relpath="`path_concat "${STASHES_DIR}" "${name}"`"
   fi

   stashdir="`path_relative_to_root_dir "${relpath}"`" || exit 1

   # make sure destination doesn't stray outside of project
   case "${stashdir}" in
      ${DEPENDENCIES_DIR}*|${ADDICTIONS_DIR}*|${BOOTSTRAP_DIR}*)
         fail "${relpath} is a suspicious path in \"${clone}\""
      ;;

      "")
         internal_fail "Diffpath is empty for \"${clone}\""
      ;;

      \.\.*)
         fail "Repository destination \"${stashdir}\" is outside of project directory ($diffpath) (\"${clone}\")"
      ;;
   esac

   if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" ]
   then
      log_trace2 "URL:      \"${url}\""
      log_trace2 "DSTDIR:   \"${dstdir}\""
      log_trace2 "NAME:     \"${name}\""
      log_trace2 "SCM:      \"${scm}\""
      log_trace2 "BRANCH:   \"${branch}\""
      log_trace2 "TAG:      \"${tag}\""
      log_trace2 "STASHDIR: \"${stashdir}\""
   fi

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


mulle_repositories_initialize()
{
   log_fluff ":mulle_repositories_initialize:"

   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   :
}

mulle_repositories_initialize
