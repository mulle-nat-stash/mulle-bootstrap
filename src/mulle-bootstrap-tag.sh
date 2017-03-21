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

tag_usage()
{
   cat <<EOF >&2
usage:
   mulle-bootstrap tag [options] <tag>

   Options:
      -d   : delete tag
      -f   : force tag

      tag  : the tag for your fetched repositories
EOF
   exit 1
}


git_tag_unknown()
{
   local name
   local tag

   name="$1"
   tag="$2"

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
   if [ ! -z "${clean}" ]
   then
      log_error "Repository \"$name\" is not ready to be tagged yet."
      if [ "${MULLE_FLAG_LOG_TERSE}" != "YES" ]
      then
         git status -s >&2
      fi
      exit 1
   fi
}


ensure_repos_clean()
{
   #
   # Make sure that tagging is OK
   # all git repos must be clean
   #
   local i

   IFS="
"
   for i in `all_repository_directories_from_repos`
   do
      IFS="${DEFAULT_IFS}"

      # only tag what looks like a git repo
      if [ -d "${i}/.git" -o -d "${i}/refs" ]
      then
         (cd "${i}" ; git_must_be_clean "${i}" ) || exit 1
      fi
   done
   IFS="${DEFAULT_IFS}"
}


ensure_tags_unknown()
{
   local tag

   tag="$1"

   #
   # Make sure that tagging is OK
   # all git repos must be clean
   #
   local i

   IFS="
"
   for i in `all_repository_directories_from_repos`
   do
      IFS="${DEFAULT_IFS}"

      # only tag what looks like a git repo
      # make it scm_tag sometimes
      if [ -d "${i}/.git" -o -d "${i}/refs" ]
      then
         (cd "${i}" ; git_tag_unknown "${i}" "${tag}" ) || exit 1
      fi
   done

   IFS="${DEFAULT_IFS}"
}


tag()
{
   local tag

   tag="$1"
   [ $# -eq 0 ] || shift

   local i
   local name

   IFS="
"
   for i in `all_repository_directories_from_repos`
   do
      IFS="${DEFAULT_IFS}"

      if [ -d "${i}/.git" -o -d "${i}/refs" ]
      then
         name="`basename -- "${i}"`"
         if [ -z "${tag}" ]
         then
            log_info "### ${name}:"
            (cd "$i" ; exekutor git ${GITFLAGS} tag ${GITOPTIONS} "$@" ) || fail "tag failed"
         else
            log_info "Tagging \"${name}\" with \"${tag}\""
            (cd "$i" ; exekutor git ${GITFLAGS} tag ${GITOPTIONS} "$@" "${tag}" ) || fail "tag failed"
         fi
      fi
   done

   IFS="${DEFAULT_IFS}"
}


tag_main()
{
   log_debug "::: tag :::"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ]           && . mulle-bootstrap-scripts.sh
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ]      && . mulle-bootstrap-repositories.sh

   TAG_OPERATION="tag"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help)
            tag_usage
         ;;

         -f|--force)
            GITOPTIONS="`concat "${GITOPTIONS}" "$1"`"
            TAG_OPERATION="force tag"
         ;;

         -l|--list|-v|--verify)
            GITOPTIONS="`concat "${GITOPTIONS}" "$1"`"
            TAG_OPERATION="list/verify tags"
            UNCLEAN_OK=YES
         ;;

         -d|--delete)
            GITOPTIONS="`concat "${GITOPTIONS}" "$1"`"
            TAG_OPERATION="delete the tag of"
         ;;

         # no argument gitflags
         -n|-a|--annotate|-s|--sign|-create-reflog|--column)
            GITOPTIONS="`concat "${GITOPTIONS}" "$1"`"
         ;;
         # argument gitflags
         -*)
            GITOPTIONS="`concat "${GITOPTIONS}" "$1"`"
            shift
            GITOPTIONS="`concat "${GITOPTIONS}" "$1"`"
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   if [ -z "${UNCLEAN_OK}" ]
   then
      TAG=$1
      [ $# -eq 0 ] || shift

      if [ -z "${TAG}" ]
      then
         tag_usage
      fi

      if [ -z "${GITOPTIONS}" ]
      then
         ensure_tags_unknown "${TAG}"
      fi

      # clumsy compare
      if [ "${TAG_OPERATION}" != "delete the tag of" ]
      then
         ensure_repos_clean
      fi
   fi

   if dir_has_files "${REPOS_DIR}"
   then
      log_fluff "Will ${TAG_OPERATION} clones with ${TAG}"
   else
      log_verbose "There is nothing to tag."
      return 0
   fi

   run_root_settings_script "pre-tag"

   tag "${TAG}" "$@"

   run_root_settings_script "post-tag"
}
