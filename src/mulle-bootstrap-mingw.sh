#! /usr/bin/env bash
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
MULLE_BOOTSTRAP_MINGW_SH="included"


find_msvc_executable()
{
   local exe
   local name

   exe="${1:-cl.exe}"
   name="${2:-compiler}"

   local path
   local compiler

   IFS=":"
   for path in $PATH
   do
      IFS="${DEFAULT_IFS}"

      case "${path}" in
         /usr/*|/bin)
            continue;
         ;;

         *)
            executable="${path}/${exe}"
            if [ -x "${executable}" ]
            then
               log_fluff "MSVC ${name} found as ${C_RESET}${executable}"
               echo "${executable}"
               break
            fi
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"
}


mingw_mangle_compiler()
{
   local compiler

   compiler="$1"
   case "${compiler}" in
      *clang) # mulle-clang|clang
         compiler="${compiler}-cl"
      ;;

      *)
         compiler="cl"
         log_fluff "Using default compiler cl"
      ;;
   esac
   echo "${compiler}"
}


#
# fix path fckup
#
setup_mingw_buildenvironment()
{
   local linker

   if [ -z "${LIBPATH}" -o  -z "${INCLUDE}" ] && [ -z "${DONT_USE_VS}" ]
   then
      fail "environment variables INCLUDE and LIBPATH not set, start MINGW inside IDE environment"
   fi

   linker="`find_msvc_executable "link.exe" "linker"`"
   if [ ! -z "${linker}" ]
   then
      LD="${linker}"
      export LD
      log_verbose "Environment variable ${C_INFO}LD${C_VERBOSE} set to ${C_RESET}\"${LD}\""
   else
      log_fluff "MSVC link.exe not found"
   fi

   local preprocessor

   preprocessor="`find_msvc_executable "mulle-mingw-cpp.sh" "preprocessor"`"
   if [ ! -z "${preprocessor}" ]
   then
      CPP="${preprocessor}"
      export CPP
      log_verbose "Environment variable ${C_INFO}CPP${C_VERBOSE} set to ${C_RESET}\"${CPP}\""
   else
      log_fluff "mulle-mingw-cpp.sh not found"
   fi
}


#
# mingw32-make can't have sh.exe in its path
#
mingw_buildpath()
{
   local i
   local fetchpath

   IFS=":"
   for i in $PATH
   do
      IFS="${DEFAULT_IFS}"

      if [ -x "${i}/sh.exe" ]
      then
         log_fluff "Removed \"$i\" from build PATH because it contains sh"
         continue
      fi

      if [ -z "${fetchpath}" ]
      then
         fetchpath="${i}"
      else
         fetchpath="${fetchpath}:${i}"
      fi
   done

   IFS="${DEFAULT_IFS}"

   echo "${fetchpath}"
}


mingw_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh
   log_debug ":mingw_initialize:"
}

mingw_initialize

