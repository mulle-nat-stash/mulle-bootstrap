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
MULLE_BOOTSTRAP_COMMAND_SH="included"


suggest_binary_install()
{
   toolname="$1"

   log_warning "Suggested fix:"

   case "${toolname}" in
      mulle-cl*)
         case "${UNAME}" in
            darwin)
               log_info "brew install mulle-xcode-developer"
            ;;

            *)
               log_info "Visit https://mulle-objc.github.io/ for instructions how to install ${toolname}"
            ;;
         esac
      ;;

      *)
         case "${UNAME}" in
            darwin)
               log_info "brew install $1"
            ;;

            linux)
               if command -v "apt-get" > /dev/null 2>&1
               then
                  log_info "apt-get install $1"
               else
                  if command -v "yum" > /dev/null 2>&1
                  then
                     log_info "yum install $1"
                  else
                     fail "You need to install $1 manually"
                  fi
               fi
            ;;

            FreeBSD)
               if command -v "pkg" > /dev/null 2>&1
               then
                  log_info pkg install "$1"
               else
                  if command -v "pkg_add" > /dev/null 2>&1
                  then
                     log_info pkg_add -r "$1"
                  else
                     log_info "You need to install $1 manually"
                  fi
               fi
            ;;

            *)
               log_info "You need to install $1 manually"
            ;;
         esac
      ;;
   esac
}


platform_make()
{
   local compiler="$1"

   case "${UNAME}" in
      mingw)
         case "${compiler}" in
            ""|cl|cl.exe)
               echo "nmake"
            ;;
            *)
               echo "mingw32-make"
            ;;
         esac
      ;;

      *)
         echo "make"
      ;;
   esac
}


platform_cmake_generator()
{
   local make="$1"

   case "${UNAME}" in
      mingw)
         case "${make}" in
            n*|N*)
               defaultgenerator="NMake Makefiles"
            ;;
            mingw*|MINGW*)
               defaultgenerator="MinGW Makefiles"
            ;;
            *)
               defaultgenerator="MSYS Makefiles"
            ;;
         esac
      ;;

      *)
         echo "Unix Makefiles"
      ;;
   esac
}


#
# first find a project with matching name, otherwise find
# first nearest project
#
find_xcodeproj()
{
   local found
   local expect
   local depth

   found=""
   expect="$1"
   depth=1000
   #     IFS='\0'

   local match
   local new_depth

   #
   # don't go too deep in search
   #
   for i in `find . -maxdepth 2 -name "*.xcodeproj" -print`
   do
      match=`basename -- "${i}" .xcodeproj`
      if [ "$match" = "$expect" ]
      then
         echo "$i"
         return 0
      fi

      new_depth=`path_depth "$i"`
      if [ "$new_depth" -lt "$depth" ]
      then
         found="${i}"
         depth="$new_depth"
      fi
   done

   if [ ! -z "$found" ]
   then
      echo "${found}"
      return 0
   fi

   return 1
}


which_binary()
{
   local toolname

   toolname="$1"
   case "${UNAME}" in
      mingw)
         case "${toolname}" in
            *.exe)
            ;;

            *)
               toolname="${toolname}.exe"
            ;;
         esac
      ;;
   esac

   which "${toolname}" 2> /dev/null
}


# used by test scripts outside of mulle-bootstrap
assert_binary()
{
   local toolname
   local toolfamily

   toolname="$1"
   toolfamily="$2"

   [ -z "${toolname}" ] && internal_fail "toolname for \"${toolfamily}\" is empty"

   local path

   path=`which_binary "${toolname}"`
   if [ -z "${path}" ]
   then
      which_binary "${toolname}"
      fail "${toolname} is an unknown build tool (PATH=$PATH)"
   fi
   # echo "$path"
}


#
# toolname : ex. mulle-clang
# toolfamily: CC
# tooldefaultname: gcc
#
verify_binary()
{
   local toolname="$1"
   local toolfamily="$2"
   local tooldefaultname="$3"

   [ -z "${toolname}" ] && internal_fail "toolname for \"${toolfamily}\" is empty"

   local path

   path=`which_binary "${toolname}"`
   if [ ! -z "${path}" ]
   then
      echo "`basename ${path}`"
      return 0
   fi

   #
   # If the user (via config) specified a certain tool, then it not being
   # there is bad.
   # Otherwise it's maybe OK (f.e. only using xcodebuild not cmake)
   #
   toolname="`extension_less_basename "${toolname}"`"
   tooldefaultname="`extension_less_basename "${tooldefaultname}"`"

   if [ "${toolname}" != "${tooldefaultname}" ]
   then
      log_fail "${toolfamily} named \"${toolname}\" not found in PATH"
      suggest_binary_install "${toolname}"
      _bail
   else
      log_fluff "${toolfamily} named \"${toolname}\" not found in PATH"
   fi

   return 1
}



#
# command because it's like `command -v gcc`
#
command_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

   log_debug ":command_initialize:"
}

command_initialize
