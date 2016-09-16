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

# deal with stuff like
# foo
# https://www./foo.git
# host:foo
#

canonical_clone_name()
{
   local  url

   url="$1"


   # cut off scheme part

   case "$url" in
      *:*)
         url="`echo "$@" | sed 's/^\(.*\):\(.*\)/\2/'`"
         ;;
   esac

   extension_less_basename "$url"
}


count_clone_components()
{
  echo "$@" | tr ';' '\012' | wc -l | awk '{ print $1 }'
}


url_from_clone()
{
   echo "$@" | cut '-d;' -f 1
}


_name_part_from_clone()
{
   echo "$@" | cut '-d;' -f 2
}


_branch_part_from_clone()
{
   echo "$@" | cut '-d;' -f 3
}


_scm_part_from_clone()
{
   echo "$@" | cut '-d;' -f 4
}


canonical_name_from_clone()
{
   local url
   local name
   local branch

   url="`url_from_clone "$@"`"
   name="`_name_part_from_clone "$@"`"

   if [ ! -z "${name}" -a "${name}" != "${url}" ]
   then
      canonical_clone_name "${name}"
      return
   fi

   canonical_clone_name "${url}"
}


branch_from_clone()
{
   local count

   count="`count_clone_components "$@"`"
   if [ "$count" -ge 3 ]
   then
      _branch_part_from_clone "$@"
   fi
}


scm_from_clone()
{
   local count

   count="`count_clone_components "$@"`"
   if [ "$count" -ge 4 ]
   then
      _scm_part_from_clone "$@"
   fi
}


embedded_repository_directory_in_repos()
{
   local filename
   local owd

   filename="$1"
   owd="$2"

   local embedded
   local linkfile
   local relpath
   local old
   local owd

   relpath="${CLONESFETCH_SUBDIR}/.embedded/${filename}"
   if [ -f "${relpath}" ]
   then
      linkfile="`cat "${relpath}"`"
      embedded="`(cd "${CLONESFETCH_SUBDIR}/.embedded" ; absolutepath "${linkfile}")`"
      embedded="`simplify_path "${embedded}"`"
      embedded="`relative_path_between "${embedded}" "${owd}"`"
      if [ -d "${embedded}" ]
      then
         echo "${embedded}"
      fi
   fi
}


embedded_repository_directories_from_repos()
{
   local filename
   local embedded
   local linkfile
   local relpath
   local old
   local owd

   owd="`pwd -P`"

   old="${IFS}"
   IFS="
"
   for filename in `ls -1 "${CLONESFETCH_SUBDIR}/.embedded/" 2> /dev/null`
   do
      IFS="${old}"

      embedded_repository_directory_in_repos "${filename}" "${owd}"
   done

   IFS="${old}"
}


repository_directories_from_repos()
{
   local filename
   local old

   old="${IFS}"
   IFS="
"
   for filename in `ls -1 "${CLONESFETCH_SUBDIR}" 2> /dev/null`
   do
      case "${filename}" in
         .*)
         ;;

         *)
            echo "${CLONESFETCH_SUBDIR}/$filename"
         ;;
      esac
   done

   IFS="${old}"
}


# this sets valuse to variables that should be declared
# in the caller!
#
#   local name
#   local url
#   local branch
#   local scm
#   local tag
#
__parse_expanded_clone()
{
   local clone

   clone="${1}"

   name="`canonical_name_from_clone "${clone}"`"
   url="`url_from_clone "${clone}"`"
   branch="`branch_from_clone "${clone}"`"
   scm="`scm_from_clone "${clone}"`"
   tag="`read_repo_setting "${name}" "tag"`" #repo (sic)


   case "${name}" in
      /*|~*|..*|.*)
         fail "destination name of ${clone} looks fishy"
      ;;
   esac
}


__parse_clone()
{
   local clone

   clone="`expanded_setting "${1}"`"

   __parse_expanded_clone "${clone}"
}


# this sets values to variables that should be declared
# in the caller!
#
#   local name
#   local url
#   local branch
#   local scm
#   local tag
#   local subdir
#
__parse_embedded_clone()
{
   local clone

   clone="`expanded_setting "${1}"`"

   __parse_expanded_clone "${clone}"

   subdir="`_name_part_from_clone "${clone}"`"
   subdir="`simplify_path "${subdir}"`"
   case "${subdir}" in
      /*|~*|..*|.*)
         fail "destination directory of ${clone} looks fishy"
      ;;

      "")
         subdir="${name}"
      ;;
   esac
}


ensure_clones_directory()
{
   if [ ! -d "${CLONESFETCH_SUBDIR}" ]
   then
      if [ "${COMMAND}" = "update" ]
      then
         fail "install first before upgrading"
      fi
      mkdir_if_missing "${CLONESFETCH_SUBDIR}"
   fi
}


mulle_repositories_inititalize()
{
  [ -z "${MULLE_BOOTSTRAP_BUILD_ENVIRONMENT_SH}" ] && . mulle-bootstrap-build-environment.sh
  [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh
  [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
}

mulle_repositories_inititalize
