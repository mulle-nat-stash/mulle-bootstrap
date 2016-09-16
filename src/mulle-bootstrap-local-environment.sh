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
#
MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH="included"


# returns 0 if said yes
user_say_yes()
{
   local  x

   x="${MULLE_BOOTSTRAP_ANSWER:-ASK}"
   while [ "$x" != "Y" -a "$x" != "YES" -a  "$x" != "N"  -a  "$x" != "NO"  -a "$x" != "" ]
   do
      printf "${C_WARNING}%b${C_RESET} (y/${C_GREEN}N${C_RESET}) > " "$*" >&2
      read x
      x=`echo "${x}" | tr '[a-z]' '[A-Z]'`
   done

   if [ "${x}" = "ALL" ]
   then
      MULLE_BOOTSTRAP_ANSWER="YES"
      x="YES"
   fi
   if [ "${x}" = "NONE" ]
   then
      MULLE_BOOTSTRAP_ANSWER="NO"
      x="NO"
   fi

   [ "$x" = "Y" -o "$x" = "YES" ]
   return $?
}


get_core_count()
{
   count="`nproc 2> /dev/null`"
   if [ -z "$count" ]
   then
      count="`sysctl -n hw.ncpu 2> /dev/null`"
   fi

   if [ -z "$count" ]
   then
      count=2
   fi
   echo $count
}


local_environment_initialize()
{
   #
   # read local environment
   # source this file
   #
   BOOTSTRAP_SUBDIR=.bootstrap
   # can't rename this because of embedded reposiories
   CLONES_SUBDIR=.repos
   # future: shared dependencies folder for many projects
   #RELATIVE_ROOT=""

   CLONESFETCH_SUBDIR="${CLONES_SUBDIR}"
   DEPENDENCY_SUBDIR="${RELATIVE_ROOT}dependencies"
   ADDICTION_SUBDIR="${RELATIVE_ROOT}addictions"

   #
   # simplify UNAME from MINGW64_NT-10.0 to MINGW
   # others should be ok
   #

   log_fluff "${UNAME} detected"
   case "${UNAME}" in
      mingw)
         # be verbose by default on MINGW because its so slow
         if [ -z "${MULLE_BOOTSTRAP_TRACE}" ]
         then
           MULLE_BOOTSTRAP_VERBOSE="YES"
         fi

         if [ -z "${MULLE_BOOTSTRAP_SKIP_INITIAL_REFRESH}" ]
         then
           MULLE_BOOTSTRAP_SKIP_INITIAL_REFRESH="YES"
         fi

         PATH_SEPARATOR=';'
      ;;

      "")
         fail "UNAME not set"
      ;;

      *)
         PATH_SEPARATOR=':'
      ;;
   esac
}

local_environment_initialize
