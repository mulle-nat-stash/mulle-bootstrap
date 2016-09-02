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
#   POSSIBILITY OF SUCH DAMAGE.
MULLE_BOOTSTRAP_TAG_SH="included"


# tag this project, and all cloned dependencies
# the dependencies will get a different vendor tag
# based on the tag
#

[ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
[ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ] && . mulle-bootstrap-scripts.sh


tag_usage())
{
   cat <<EOF >&2
usage:
   mulle-bootstrap tag [-f] <tag>

   -d           : delete tag
   -f           : force tag

   tag          : the tag for your fetched repositories
EOF
   exit 1
}




git_tag_unknown()
{
   local name
   local tag

   name="${1}"
   tag="${2}"

   if [ ! -d .git ]
   then
      fail "\"${name}\" is not a git repository"
   fi

   git reflog "${tag}" -- > /dev/null  2>&1
   if [ "$?" -eq 0 ]
   then
      log_error "Repository \"$name\" is already tagged with \"$2\"."
      exit 1
   fi
}


git_must_be_clean()
{
   local name

   name="$1"

   if [ ! -d .git ]
   then
      fail "\"${name}\" is not a git repository"
   fi

   local clean

   clean=`git status -s`
   if [ "${clean}" != "" ]
   then
      log_error "Repository \"$name\" is not ready to be tagged yet."
      if [ "${MULLE_BOOTSTRAP_TERSE}" != "YES" ]
      then
         git status -s >&2
      fi
      exit 1
   fi
}


ensure_repos_clean()
{
   local clonesdir

   clonesdir="$1"

   #
   # Make sure that tagging is OK
   # all git repos must be clean
   #
   if dir_has_files "${clonesdir}"
   then
      for i in "${clonesdir}"/*
      do
         # only tag what looks like a git repo
         if [ -d "${i}/.git" -o -d "${i}/refs" ]
         then
            (cd "${i}" ; git_must_be_clean "${i}" ) || exit 1
         fi
      done
   fi
}


ensure_tags_unknown()
{
   local tag
   local clonesdir

   clonesdir="$1"
   tag="$2"

   #
   # Make sure that tagging is OK
   # all git repos must be clean
   #
   if dir_has_files "${clonesdir}"
   then
      for i in "${clonesdir}"/*
      do
         # only tag what looks like a git repo
         if [ -d "${i}/.git" -o -d "${i}/refs" ]
         then
            (cd "${i}" ; git_tag_unknown "${i}" "${tag}" ) || exit 1
         fi
      done
   fi
}


tag()
{
   local clonesdir
   local tag

   clonesdir="$1"
   [ $# -eq 0 ] || shift
   tag="$1"
   [ $# -eq 0 ] || shift

   local i

   if dir_has_files "${clonesdir}"
   then
      for i in "${clonesdir}"/*
      do
         if [ -d "$i" ]
         then
            if [ -d "${i}/.git" -o -d "${i}/refs" ]
            then
               log_info "Tagging \"`basename -- "${i}"`\" with \"${tag}\""
               (cd "$i" ; exekutor git tag $GIT_FLAGS "$@" "${tag}" ) || fail "tag failed"
            fi
         fi
      done
   fi
}


main_tag()
{
   log_fluff "::: tag :::"

   GIT_FLAGS=
   TAG_OPERATION="tag"

   while :
   do
      if [ "$1" = "-h" -o "$1" = "--help" ]
      then
         tag_usage
      fi

      if [ "$1" = "-f" ]
      then
         GIT_FLAGS="${GIT_FLAGS} ${1}"
         TAG_OPERATION="force tag"
         [ $# -eq 0 ] || shift
         continue
      fi

      if [ "$1" = "-d" ]
      then
         GIT_FLAGS="${GIT_FLAGS} ${1}"
         TAG_OPERATION="delete the tag of"
         [ $# -eq 0 ] || shift
         continue
      fi

      break
   done


   TAG=${1}
   [ $# -eq 0 ] || shift

   if [ -z "${TAG}" ]
   then
      tag_usage
   fi

   if [ -z "${GIT_FLAGS}" ]
   then
      ensure_tags_unknown "${CLONES_SUBDIR}" "${TAG}"
   fi
   ensure_repos_clean "${CLONES_SUBDIR}"

   if dir_has_files "${CLONES_SUBDIR}"
   then
      echo "Will ${TAG_OPERATION} clones with ${TAG}" >&2
   else
      log_info "There is nothing to tag."
      return 0
   fi

   run_fetch_settings_script "pre-tag"

   tag "${CLONES_SUBDIR}" "${TAG}" "$@"

   run_fetch_settings_script "pre-tag"
}
