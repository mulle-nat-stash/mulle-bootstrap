#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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
MULLE_BOOTSTRAP_COPY_SH="included"


tar_remove_extension()
{
   local ext="$1"

   if [ ! -z "${ext}" ]
   then
      case "${UNAME}" in
         darwin|freebsd)
            echo "-s/\.$1\$//"
         ;;

         linux)
            echo "--transform s/\.$1\$//"
         ;;

         *)
            echo "--transform /\.$1\$//"
         ;;
      esac
   fi
}


#
# dstdir need not exist
# srcdir must exist
# ext can be empty
# noclobber can be empty=NO,NO or YES
#
_archive_files()
{
   local srcdir="$1"
   local ext="$2"
   local taroptions="$3"

   (
      exekutor cd "${srcdir}" ;
      if [ -z "${ext}" ]
      then
         exekutor find . \( -type f -a ! -name "*.*" \) -print
      else
         exekutor find . \( -type f -a -name "*.${ext}" \) -print
      fi |
         exekutor tar -c ${taroptions} -f - -T -
   ) || exit 1
}



_unarchive_files()
{
   local dstdir="$1"
   local noclobber="$2"

   [ -d "${dstdir}" ] || fail "${dstdir} does not exist"

   (
      exekutor cd "${dstdir}" ;
      if [ "${noclobber}" = "NO" ]
      then
         exekutor tar -x ${TARFLAGS} -f -
      else
         exekutor tar -x ${TARFLAGS} -k -f -
      fi
      :  # ignore trashy tar rval
   )  2> /dev/null
}


_copy_files()
{
   local taroptions="$1" ; shift
   local dstdir="$1" ; shift
   local srcdir="$1" ; shift
   local ext="$1" ; shift
   local noclobber="${1:-YES}" ; shift

   [ -d "${srcdir}" ] || internal_fail "${srcdir} does not exist"
   [ -d "${dstdir}" ] || internal_fail "${dstdir} does not exist"

   if [ -z "${ext}" ]
   then
      log_fluff "Copying extensionless files from \"${srcdir}\" to \"${dstdir}\""
   else
      log_fluff "Copying .${ext} files from \"${srcdir}\" to \"${dstdir}\""
   fi

   #
   # copy over files only, let tar remove extension
   #
   _archive_files "${srcdir}" "${ext}" "${taroptions}" | _unarchive_files "${dstdir}" "${noclobber}"
}


copy_files_stripping_last_extension()
{
   local ext="$3"
   local lastext="`echo "${ext}" | sed 's/\.[^.]*$//'`"

   _copy_files "`tar_remove_extension "${lastext}"`" "$@"
}


copy_files_keeping_extension()
{
   _copy_files "" "$@"
}



#
# dstdir need not exist
# srcdir must exist
#
inherit_files()
{
   local dstdir="$1"
   # local srcdir="$2"
   # local ext="$3"
   # local noclobber="$4"

   dstdir="$1"

   [ $# -eq 2 ] || internal_fail "parameter error"

   mkdir_if_missing "${dstdir}"

   # prefer to copy os-specific first, "-k" won't overwrite
   copy_files_stripping_last_extension "$@" "${UNAME}" "YES" || fail "copy"

   # then to copy generic, again "-k" won't overwrite
   copy_files_keeping_extension "$@" "" "YES" || fail "copy"
}


inherit_scripts()
{
   local dstdir="$1"
   # local srcdir="$2"
   # local ext="$3"
   # local noclobber="$4" default YES

   dstdir="$1"

   [ $# -eq 2 ] || internal_fail "parameter error"

   mkdir_if_missing "${dstdir}"

   # prefer to copy os-specific first, "-k" won't overwrite
   copy_files_stripping_last_extension "$@" "sh.${UNAME}" "YES" || fail "copy"

   # then to copy generic, again "-k" won't overwrite
   copy_files_keeping_extension "$@" "sh" "YES" || fail "copy"
}


#
# dstdir need not exist
# srcdir must exist
#
override_files()
{
   local dstdir="$1"
   local srcdir="$2"
   local ext="$3"
   # local noclobber="$4"

   [ $# -eq 2 ] || internal_fail "parameter error"

   mkdir_if_missing "${dstdir}"

   # first copy generic, clobber what's there
   copy_files_keeping_extension "${dstdir}" "${srcdir}" "" "NO"      || fail "copy"

   # then copy os-specific to clobber generics
   copy_files_stripping_last_extension "${dstdir}" "${srcdir}" "${UNAME}" "NO" || fail "copy"
}


override_scripts()
{
   local dstdir="$1"
   # local srcdir="$2"
   # local ext="$3"
   # local noclobber="$4"

   [ $# -eq 2 ] || internal_fail "parameter error"

   mkdir_if_missing "${dstdir}"

   # first copy generic, clobber what's there
   copy_files_keeping_extension "$@" "sh" || fail "copy"

   # then copy os-specific to clobber generics
   copy_files_stripping_last_extension "$@" "sh.${UNAME}" || fail "copy"
}

# make sure functions are present

copy_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

   log_debug ":copy_initialize:"

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
}

copy_initialize
