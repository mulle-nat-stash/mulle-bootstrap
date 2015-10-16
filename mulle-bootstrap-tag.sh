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


# tag this project, and all cloned dependencies
# the dependencies will get a different vendor tag
# based on the tag
#

. mulle-bootstrap-local-environment.sh
. mulle-bootstrap-scripts.sh


name=`basename "${PWD}"`


usage()
{
   cat <<EOF
usage: tag [tag] [vendortag] [vendorprefix]

   tag          : the tag for your repository ($name)
   vendortag    : the tag used for tagging the fetched repositories
   vendorprefix : prefix for the vendortag, if vendortag is "-"
EOF
}


check_and_usage_and_help()
{
   if [ "$TAG" = "" -o "$TAG" = "-h" -o "$TAG" = "--help" -o "$VENDOR_TAG" = "" ]
   then
      usage >&2
      exit 1
   fi
}


project=`find_xcodeproj "${name}"`
AGVTAG=

if [ "${project}" != "" ]
then
   log_fluff "Trying agvtool to figure out current version"
   dir=`dirname "${project}"`
   [ -x "${dir}" ] || fail "${dir} is not accesible"

   AGVTAG=`(cd "${dir}" ; agvtool what-version -terse ) 2> /dev/null`
   if [ $? -ne 0 ]
   then
      log_fluff "agvtool failed"
      AGVTAG=
   else
      log_info "Current version: ${AGVTAG}"
   fi
fi


TAG=${1:-"$AGVTAG"}
[ $# -eq 0 ] || shift

VENDOR_TAG="$1"
[ $# -eq 0 ] || shift

VENDOR_PREFIX="$1"
[ $# -eq 0 ] || shift


if [ -z "${VENDOR_TAG}" -o "${VENDOR_TAG}" = "-" ]
then
   if [ -z "${VENDOR_PREFIX}" ]
   then
      VENDOR_PREFIX=`basename "${PWD}"`
      VENDOR_PREFIX="${VENDOR_PREFIX%%.*}"  # remove vile extension :)
   fi

   if [ "${VENDOR_PREFIX}" = "-" ]
   then
      VENDOR_TAG="${TAG}"
   else
      VENDOR_TAG="${VENDOR_PREFIX}-${TAG}"
   fi

   check_and_usage_and_help

   log_info "Set vendortag to \"${VENDOR_TAG}\""
else
   check_and_usage_and_help
fi

REPO="."


git_must_be_clean()
{
   local name
   local clean

   name="${1:-${PWD}}"

   if [ ! -d .git ]
   then
      fail "\"${name}\" is not a git repository"
   fi

   clean=`git status -s`
   if [ "${clean}" != "" ]
   then
      fail "repository $name is tainted"
   fi
}


ensure_repos_clean()
{
   #
   # Make sure that tagging is OK
   # all git repos must be clean
   #
   (cd "${REPO}" ; git_must_be_clean "${REPO}" ) || exit 1

   if  dir_has_files "${CLONES_SUBDIR}"
   then
      for i in "${CLONES_SUBDIR}"/*
      do
         # only tag what looks like a git repo
         if [ -d "${i}/.git" -o -d "${i}/refs" ]
         then
            (cd "${i}" ; git_must_be_clean "${i}" ) || exit 1
         fi
      done
   fi
}


tag()
{
   local i
   local script

   run_fetch_settings_script "pre-tag"

   script=`find_fetch_setting_file "bin/tag.sh"`
   if [ -x "$script" ]
   then
      run_script "$script" "${TAG}" "${REPO}" || exit 1
   else
      log_info "Tagging \"`basename "${REPO}"`\" with \"${TAG}\""
      ( cd "${REPO}" ; exekutor git tag "${TAG}" ) || exit 1

      if  dir_has_files "${CLONES_SUBDIR}"
      then
         for i in "${CLONES_SUBDIR}"/*
         do
            if [ -d "$i" ]
            then
               if [ -d "${i}/.git" -o -d "${i}/refs" ]
               then
                  log_info "Tagging \"`basename "${i}"`\" with \"${VENDOR_TAG}\""
                  (cd "$i" ; exekutor git tag "${VENDOR_TAG}" ) || fail "tag failed"
               fi
            fi
         done
      fi
   fi

   run_fetch_settings_script "pre-tag"
}


main()
{
   log_fluff "::: tag :::"

   ensure_repos_clean

   echo "Will tag `basename "${PWD}"` with ${TAG}" >&2
   if  dir_has_files "${CLONES_SUBDIR}"
   then
      echo "Will tag clones with ${VENDOR_TAG}" >&2
   fi

   user_say_yes "Is this OK ?"
   if [ $? -eq 0 ]
   then
      tag
   fi
}

main "$@"
