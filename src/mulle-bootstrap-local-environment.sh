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
   while [ "$x" != "Y" -a \
           "$x" != "YES" -a \
           "$x" != "ALL" -a \
           "$x" != "N"  -a  \
           "$x" != "NO"  -a \
           "$x" != "NONE" -a \
           "$x" != "" ]
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


# figure out if we need to run refresh
build_needed()
{
   if [ ! -f "${CLONESFETCH_SUBDIR}/.build_done" ]
   then
      log_fluff "Need build because ${CLONESFETCH_SUBDIR}/.build_done does not exist."
      return 0
   fi

   if [ "${CLONESFETCH_SUBDIR}/.build_done" -ot "${CLONESFETCH_SUBDIR}/.refresh_done" ]
   then
      log_fluff "Need build because \"${CLONESFETCH_SUBDIR}/.build_done\" is older than \"${CLONESFETCH_SUBDIR}/.refresh_done\""
      return 0
   fi

   return 1
}


fetch_needed()
{
   if [ ! -f "${CLONESFETCH_SUBDIR}/.fetch_done" ]
   then
      log_fluff "Need fetch because ${CLONESFETCH_SUBDIR}/.fetch_done does not exist."
      return 0
   fi

   if [ "${CLONESFETCH_SUBDIR}/.fetch_done" -ot "${CLONESFETCH_SUBDIR}/.refresh_done" ]
   then
      log_fluff "Need fetch because \"${CLONESFETCH_SUBDIR}/.fetch_done\" is older than \"${CLONESFETCH_SUBDIR}/.refresh_done\""
      return 0
   fi

   return 1
}


refresh_needed()
{
   if [ ! -d "${BOOTSTRAP_SUBDIR}.auto" ]
   then
     log_fluff "Need refresh because ${BOOTSTRAP_SUBDIR}.auto does not exist."
     return 0
   fi

   if [ ! -f "${CLONESFETCH_SUBDIR}/.refresh_done" ]
   then
      log_fluff "Need refresh because ${CLONESFETCH_SUBDIR}/.refresh_done does not exist."
      return 0
   fi

   if [ "${CLONESFETCH_SUBDIR}/.refresh_done" -ot "${BOOTSTRAP_SUBDIR}/embedded_repositories" ]
   then
      log_fluff "Need refresh because \"${BOOTSTRAP_SUBDIR}/embedded_repositories\" is modified"
      return 0
   fi

   if [ "${CLONESFETCH_SUBDIR}/.refresh_done" -ot "${BOOTSTRAP_SUBDIR}/repositories" ]
   then
      log_fluff "Need refresh because \"${BOOTSTRAP_SUBDIR}/repositories\" is modified"
      return 0
   fi

   if [ "${CLONESFETCH_SUBDIR}/.refresh_done" -ot "${BOOTSTRAP_SUBDIR}.local/embedded_repositories" ]
   then
      log_fluff "Need refresh because \"${BOOTSTRAP_SUBDIR}.local/embedded_repositories\" is modified"
      return 0
   fi

   if [ "${CLONESFETCH_SUBDIR}/.refresh_done" -ot "${BOOTSTRAP_SUBDIR}.local/repositories" ]
   then
      log_fluff "Need refresh because \"${BOOTSTRAP_SUBDIR}.local/repositories\" is modified"
      return 0
   fi

   return 1
}


#
# version must be <= min_major.min_minor
#
check_version()
{
   local version
   local min_major
   local min_minor

   version="$1"
   min_major="$2"
   min_minor="$3"

   local major
   local minor

   if [ -z "${version}" ]
   then
      return 0
   fi

   major="`echo "${version}" | head -1 | cut -d. -f1`"
   if [ "${major}" -lt "${min_major}" ]
   then
      return 0
   fi

   if [ "${major}" -ne "${min_major}" ]
   then
      return 1
   fi

   minor="`echo "${version}" | head -1 | cut -d. -f2`"
   [ "${minor}" -le "${min_minor}" ]
}


assert_mulle_bootstrap_version()
{
   local version

   # has to be read before .auto is setup
   version="`_read_setting "${BOOTSTRAP_SUBDIR}/version"`"
   if check_version "$version" "${MULLE_BOOTSTRAP_VERSION_MAJOR}" "${MULLE_BOOTSTRAP_VERSION_MINOR}"
   then
      return
   fi

   fail "This ${BOOTSTRAP_SUBDIR} requires mulle-bootstrap version ${version} at least, you have ${MULLE_BOOTSTRAP_VERSION}"
}


#
# expands ${setting} and ${setting:-foo}
#
_expanded_variables()
{
   local string

   string="$1"

   local key
   local value
   local prefix
   local suffix
   local next
   local default
   local tmp


   key="`echo "${string}" | sed -n 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\2/p'`"
   if [ -z "${key}" ]
   then
      echo "$1"
      return
   fi

   prefix="`echo "${string}" | sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\1/'`"
   suffix="`echo "${string}" | sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\3/'`"

   tmp="`echo "${key}" | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)[:][-]\(.*\)$/\1/p'`"
   if [ ! -z "${tmp}" ]
   then
      default="`echo "${key}" | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)[:][-]\(.*\)$/\2/p'`"
      key="${tmp}"
   fi

   value="`read_fetch_setting "${key}" "${default}"`"
   next="${prefix}${value}${suffix}"
   if [ "${next}" = "${string}" ]
   then
      fail "${string} expands to itself"
   fi

   _expanded_variables "${next}"
}


expanded_variables()
{
   local memo
   local value

   # a hack ?

   memo="${MULLE_BOOTSTRAP_SETTINGS_NO_AUTO}"
   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="NO"

   value="`_expanded_variables "$1"`"

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="${memo}"

   if [ "$1" != "${value}" ]
   then
      log_fluff "Expanded \"$1\" to \"${value}\""
   fi

   echo "$value"
}


source_environment_file()
{
   local filename

   filename="$1"
   if [ ! -r "${filename}" ]
   then
      log_fluff "Environment file ${filename} not found"
      return 1
   fi

   local lines
   local line
   local key
   local value

   log_fluff "Environment file ${filename} exists"

   lines="`egrep -s -v '^#|^[ ]*$' "${filename}"`"
   IFS="
"
   for line in $lines
   do
      IFS="${DEFAULT_IFS}"

      key="`echo "${line}" | cut -d= -f1`"
      value="`echo "${line}" | cut -d= -f2`"

      value="`expanded_variables "${value}"`"
      case "${key}" in
         *\`*|*\$*|*\!*)
            fail "Illegal characters in $key of $filename"
         ;;
      esac
      case "${value}" in
         *\`*|*\$*|*\!*)
            fail "Illegal characters in $value of $filename"
         ;;
      esac
      log_verbose "Environment variable $key defined as $value"

      eval "${key}=${value}; export ${key}"
   done

   IFS="${DEFAULT_IFS}"

   return 0
}


#
# source environment
#
source_environment()
{
   local flag

   flag=""

   if source_environment_file "${HOME}/.mulle-bootstrap/environment"
   then
      flag="${MULLE_BOOTSTRAP_FLUFF}"
   fi

   if source_environment_file "${BOOTSTRAP_SUBDIR}.auto/environment"
   then
      flag="${MULLE_BOOTSTRAP_FLUFF}"
   else
      if source_environment_file "${BOOTSTRAP_SUBDIR}.local/environment"
      then
         flag="${MULLE_BOOTSTRAP_FLUFF}"
      else
         if source_environment_file "${BOOTSTRAP_SUBDIR}/environment"
         then
            flag="${MULLE_BOOTSTRAP_FLUFF}"
         fi
      fi
   fi

   if [ "${flag}" = "YES" ]
   then
      log_fluff "Environment:"
      env >&2
   fi
}


local_environment_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

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

   log_fluff "${UNAME} detected"
   case "${UNAME}" in
      mingw)
         # be verbose by default on MINGW because its so slow
         if [ -z "${MULLE_BOOTSTRAP_TRACE}" ]
         then
           MULLE_BOOTSTRAP_VERBOSE="YES"
         fi

         # be optimistic because it's too slow on windows
         if [ -z "${MULLE_BOOTSTRAP_OPTIMISTIC}" ]
         then
           MULLE_BOOTSTRAP_OPTIMISTIC="YES"
         fi

         PATH_SEPARATOR=';'
         USR_LOCAL_LIB=~/lib
         USR_LOCAL_INCLUDE=~/include
      ;;

      "")
         fail "UNAME not set"
      ;;

      *)
         PATH_SEPARATOR=':'
         USR_LOCAL_LIB=/usr/local/lib
         USR_LOCAL_INCLUDE=/usr/local/include
      ;;
   esac
}


local_environment_main()
{
#  don't do it, so far it's been overkill
#   source_environment
   :
}

local_environment_initialize
