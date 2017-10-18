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
   local exe="${1:-cl.exe}"
   local name="${2:-compiler}"
   local searchpath="${3:-$PATH}"

   local path
   local compiler

   IFS=":"
   for path in ${searchpath}
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


# used by tests
mingw_demangle_path()
{
   echo "$1" | sed 's|^/\(.\)|\1:|' | sed s'|/|\\|g'
}



mingw_eval_demangle_path()
{
   echo "$1" | sed 's|^/\(.\)|\1:|' | sed s'|/|\\\\|g'
}


#
# mingw wille demangle first -I/c/users but not the next one
# but when one -I looks demangled, it doesn't demangle the first
# one. It's so complicated
#
mingw_eval_demangle_paths()
{
#   if [ $# -eq 0 ]
#   then
#      return
#   fi
#
#   echo "$1"
#   shift

   while [ $# -ne 0 ]
   do
      mingw_eval_demangle_path "$1"
      shift
   done
}


# used by anyone ?
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



# used by tests, probably old and wrong
mingw_mangle_compiler_exe()
{
   local compiler

   compiler="$1"
   case "${compiler}" in
      mulle-clang|clang)
         compiler="${compiler}-cl"
         echo "Using ${compiler} on mingw for $2" >&2
      ;;

      mulle-clang-*|clang-*)
      ;;

      *)
         compiler="cl.exe"
         echo "Using default compiler cl for $2" >&2
      ;;
   esac
   echo "${compiler}"
}



#
# fix path fckup
#
setup_mingw_buildenvironment()
{
   log_debug "setup_mingw_buildenvironment"

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
   local searchpath

   searchpath="`dirname -- "${MULLE_EXECUTABLE_PATH}"`:$PATH"
   preprocessor="`find_msvc_executable "mulle-mingw-cpp.sh" "preprocessor" "${searchpath}"`"
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
# mingw32-make can't have sh.exe in its path, so remove it
#
mingw_buildpath()
{
   local i
   local buildpath
   local vspath

   IFS=":"
   for i in $PATH
   do
      IFS="${DEFAULT_IFS}"

      if [ -x "${i}/sh.exe" ]
      then
         log_fluff "Removed \"$i\" from build PATH because it contains sh"
         continue
      fi

      if [ -z "${buildpath}" ]
      then
         buildpath="${i}"
      else
         buildpath="${buildpath}:${i}"
      fi
   done

   echo "${buildpath}"
}


#
# mingw likes to put it's stuff in front, obscuring Visual Studio
# executables this function resorts this (used in mulle-tests)
#
mingw_visualstudio_buildpath()
{
   local i
   local buildpath
   local vspath

   IFS=":"
   for i in $PATH
   do
      IFS="${DEFAULT_IFS}"

      case "$i" in
         *"/Microsoft Visual Studio"*)
            if [ -z "${vspath}" ]
            then
               vspath="${i}"
            else
               vspath="${vspath}:${i}"
            fi
         ;;

         *)
            if [ -z "${buildpath}" ]
            then
               buildpath="${i}"
            else
               buildpath="${buildpath}:${i}"
            fi
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"

   if [ ! -z "${vspath}" ]
   then
      if [ -z "${buildpath}" ]
      then
         buildpath="${vspath}"
      else
         buildpath="${vspath}:${buildpath}"
      fi
   fi

   echo "${buildpath}"
}


mingw32_make_buildpath()
{
   mingw_buildpath
}


mingw_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh
   log_debug ":mingw_initialize:"
}

mingw_initialize

