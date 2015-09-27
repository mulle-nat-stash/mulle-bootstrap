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

name=`basename "${PWD}"`

project=`find_xcodeproj "${name}"`
AGVTAG=
if [ "${project}" != "" ]
then
   dir=`dirname "${project}"`
   AGVTAG=`(cd "${dir}" ; agvtool what-version -terse ) 2> /dev/null`
   if [ $? -ne 0 ]
   then
      AGVTAG=
   fi
fi


TAG=${1:-${AGVTAG}}
shift
VENDOR_PREFIX="${1:-${name}}"
shift
REPO=${1:-"."}
shift

if [ "$TAG" = "" ]
then
   fail "no tag specified"
fi

#
# remove file extension from directory, that would
# indicate the "branch" like foo.release vs. foo.dev
#
VENDOR_PREFIX=${VENDOR_PREFIX%%.*}

OUR_VENDOR_TAG="${1:-${VENDOR_PREFIX}-${TAG}}"
shift


git_must_be_clean()
{
   local name
   local clean

   name="${1:-${PWD}}"

   if [ ! -d .git ]
   then
      fail "$name is not a git repository"
   fi

   clean=`git status -s`
   if [ "$clean" != "" ]
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


pretag_script()
{
   #
   # Run pre-tag scripts if present
   #
   script=`read_fetch_setting "bin/pre-tag.sh"`
   if [ -x "${script}" ]
   then
      "${script}" || exit 1
   fi
}


tag()
{
   local i
   local script

   script=`read_fetch_setting "bin/tag.sh"`
   if [ -x "$script" ]
   then
      "$script" "${TAG}" "${REPO}" || exit 1
   else
      ( cd "${REPO}" ; git tag "${TAG}" ) || exit 1

      if  dir_has_files "${CLONES_SUBDIR}"
      then
         for i in "${CLONES_SUBDIR}"/*
         do
            if [ -d "$i" ]
            then
               if [ -d "${i}/.git" -o -d "${i}/refs" ]
               then
                  (cd "$i" ; git tag "${OUR_VENDOR_TAG}" ) || exit 1
               fi
            fi
         done
      fi
   fi
}


posttag_script()
{
   #
   # Run post-tag scripts if present
   #
   script=`read_fetch_setting "bin/post-tag.sh"`
   if [ -x "${script}" ]
   then
      "${script}" || exit 1
   fi
}


main()
{
   ensure_repos_clean

   echo "Tagging `basename "${PWD}"` with ${TAG}" >&2
   if  dir_has_files "${CLONES_SUBDIR}"
   then
      echo "Tagging clones with ${VENDOR_PREFIX}" >&2
   fi
   echo "press RETURN to continue, CTRL-C to abort" >&2
   read

   pretag_script
   tag
   posttag_script
}

main
