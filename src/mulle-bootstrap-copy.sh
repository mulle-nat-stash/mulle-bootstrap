#! /bin/sh
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
   local ext

   ext="$1"

   if [ ! -z "${ext}" ]
   then
      case "${UNAME}" in
         darwin|freebsd)
            echo "-s/\.$1//"
         ;;

         *)
            echo "--transform /\.$1//"
         ;;
      esac
   fi
}


#
# dstdir need not exist
# srcdir must exist
# ext can be empty
# noclobber can be empty or YES
#
copy_files_stripping_extension()
{
   local srcdir
   local dstdir
   local ext

   dstdir="$1"
   shift
   srcdir="$1"
   shift
   ext="$1"
   shift
   noclobber="$1"
   shift

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
   (
      cd "${srcdir}" ;
      if [ -z "${ext}" ]
      then
         find . \( -type f -a ! -name "*.*" \) -print
      else
         find . \( -type f -a -name "*.${ext}" \) -print
      fi |
         tar -c `tar_remove_extension "${ext}"` -f - -T -
   ) |
   (
      cd "${dstdir}" ;
      if [ -z "${noclobber}" ]
      then
         tar xf - $*
      else
         tar xf - -k 2> /dev/null
         :
      fi
   )
}


#
# dstdir need not exist
# srcdir must exist
#
inherit_files()
{
   local dstdir

   dstdir="$1"

   mkdir_if_missing "${dstdir}"

   # prefer to copy os-specific first, "-k" won't overwrite
   exekutor copy_files_stripping_extension "$@" "${UNAME}" "YES" || fail "copy"
   exekutor copy_files_stripping_extension "$@" ".sh.${UNAME}" "YES" || fail "copy"

   # then to copy generic, again "-k" won't overwrite
   exekutor copy_files_stripping_extension "$@" "" "YES" || fail "copy"
   exekutor copy_files_stripping_extension "$@" ".sh" "YES" || fail "copy"
}


#
# dstdir need not exist
# srcdir must exist
#
override_files()
{
   local dstdir

   dstdir="$1"

   mkdir_if_missing "${dstdir}"

   # first copy generic, clobber what's there
   exekutor copy_files_stripping_extension "$@"       || fail "copy"
   exekutor copy_files_stripping_extension "$@" ".sh" || fail "copy"

   # then copy os-specific to clobber generics
   exekutor copy_files_stripping_extension "$@" "${UNAME}" || fail "copy"
   exekutor copy_files_stripping_extension "$@" ".sh.${UNAME}" || fail "copy"
}


# make sure functions are present

copy_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

   log_fluff ":copy_initialize:"

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
}

copy_initialize
