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

   x="${MULLE_FLAG_ANSWER:-ASK}"

   while :
   do
      case "$x" in
         [Aa][Ll][Ll])
            MULLE_FLAG_ANSWER="YES"
            return 0
         ;;

         [Yy]*)
            return 0
         ;;

         [Nn][Oo][Nn][Ee])
            MULLE_FLAG_ANSWER="NONE"
            return 1
         ;;

         [Nn]*)
            return 1
         ;;
      esac

      printf "${C_WARNING}%b${C_RESET} (y/${C_GREEN}N${C_RESET}) > " "$*" >&2
      read x
   done
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


add_path()
{
   local line
   local path

   [ -z "${PATH_SEPARATOR}" ] && fail "PATH_SEPARATOR is undefined"

   line="$1"
   path="$2"

   case "${UNAME}" in
      mingw)
         path="`echo "${path}" | tr '/' '\\' 2> /dev/null`"
      ;;
   esac

   if [ -z "${line}" ]
   then
      echo "${path}"
   else
      echo "${line}${PATH_SEPARATOR}${path}"
   fi
}


unpostpone_trace()
{
   if [ ! -z "${MULLE_TRACE_POSTPONE}" -a "${MULLE_TRACE}" = "1848" ]
   then
      set -x
      PS4="+ ${ps4string} + "
   fi
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


# figure out if we need to run refresh
build_needed()
{
   if [ ! -f "${REPOS_DIR}/.bootstrap_build_done" ]
   then
      log_fluff "Need build because \"${REPOS_DIR}/.bootstrap_build_done\" does not exist."
      return 0
   fi

   if [ "${REPOS_DIR}/.bootstrap_build_done" -ot "${REPOS_DIR}/.bootstrap_fetch_done" ]
   then
      log_fluff "Need build because \"${REPOS_DIR}/.bootstrap_fetch_done\" is younger"
      return 0
   fi

   return 1
}


fetch_needed()
{
   if [ ! -f "${REPOS_DIR}/.bootstrap_fetch_done" ]
   then
      log_fluff "Need fetch because \"${REPOS_DIR}/.bootstrap_fetch_done\" does not exist."
      return 0
   fi

   if [ "${REPOS_DIR}/.bootstrap_fetch_done" -ot "${BOOTSTRAP_SUBDIR}" ]
   then
      log_fluff "Need fetch because \"${BOOTSTRAP_SUBDIR}\" is modified"
      return 0
   fi

   if [ "${REPOS_DIR}/.bootstrap_fetch_done" -ot "${BOOTSTRAP_SUBDIR}.local" ]
   then
      log_fluff "Need fetch because \"${BOOTSTRAP_SUBDIR}.local\" is modified"
      return 0
   fi

   return 1
}


assert_mulle_bootstrap_version()
{
   local version

   # has to be read before .auto is setup
   version="`read_setting "${BOOTSTRAP_DIR}/version" "version"`"

   if check_version "$version" "${MULLE_BOOTSTRAP_VERSION_MAJOR}" "${MULLE_BOOTSTRAP_VERSION_MINOR}"
   then
      return
   fi

   fail "This ${BOOTSTRAP_DIR} requires mulle-bootstrap version ${version} at least, you have ${MULLE_BOOTSTRAP_VERSION}"
}


#
# expands ${setting} and ${setting:-foo}
#
_expanded_variables()
{
   local string="$1"
   local altbootstrap="$2"

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
      echo "${string}"
      return
   fi

   prefix="`echo "${string}" | sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\1/'`"
   suffix="`echo "${string}" | sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\3/'`"

   default="" # crazy linux bug, where local vars are reused ?
   tmp="`echo "${key}" | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)[:][-]\(.*\)$/\1/p'`"
   if [ ! -z "${tmp}" ]
   then
      default="`echo "${key}" | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)[:][-]\(.*\)$/\2/p'`"
      key="${tmp}"
   fi

   if [ ! -z "${altbootstrap}" ]
   then
      default="`(
         BOOTSTRAP_DIR="${altbootstrap}"
         MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="YES"

         read_root_setting "${key}" "${default}"
      )`"
   fi

   value="`read_root_setting "${key}"`"
   if [ -z "${value}" ]
   then
      if [ -z "${default}" ]
      then
         log_warning "\$\{${key}\} expanded to the empty string"
      else
         log_setting "Root setting for ${C_MAGENTA}${key}${C_SETTING} set to default ${C_MAGENTA}${default}${C_SETTING}"
         value="${default}"
      fi
   fi

   next="${prefix}${value}${suffix}"
   if [ "${next}" = "${string}" ]
   then
      fail "${string} expands to itself"
   fi

   _expanded_variables "${next}" "${altbootstrap}"
}


expanded_variables()
{
   local value

   value="`_expanded_variables "$@"`"

   if [ "$1" != "${value}" ]
   then
      if [ -z "${value}" ]
      then
         log_warning "Expanded \"$1\" to empty string"
      else
         log_fluff "Expanded \"$1\" to \"${value}\""
      fi
   fi

   echo "$value"
}


# source_environment_file()
# {
#    local filename

#    filename="$1"
#    if [ ! -r "${filename}" ]
#    then
#       log_fluff "Environment file ${filename} not found"
#       return 1
#    fi

#    local lines
#    local line
#    local key
#    local value

#    log_fluff "Environment file ${filename} exists"

#    lines="`egrep -s -v '^#|^[ ]*$' "${filename}"`"
#    IFS="
# "
#    for line in $lines
#    do
#       IFS="${DEFAULT_IFS}"

#       key="`echo "${line}" | cut -d= -f1`"
#       value="`echo "${line}" | cut -d= -f2`"

#       value="`expanded_variables "${value}"`"
#       case "${key}" in
#          *\`*|*\$*|*\!*)
#             fail "Illegal characters in $key of $filename"
#          ;;
#       esac
#       case "${value}" in
#          *\`*|*\$*|*\!*)
#             fail "Illegal characters in $value of $filename"
#          ;;
#       esac
#       log_verbose "Environment variable $key defined as $value"

#       eval "${key}=${value}; export ${key}"
#    done

#    IFS="${DEFAULT_IFS}"

#    return 0
# }


# #
# # source environment
# #
# source_environment()
# {
#    local flag

#    flag=""

#    if source_environment_file "${HOME}/.mulle-bootstrap/environment"
#    then
#       flag="${MULLE_FLAG_LOG_FLUFF}"
#    fi

#    if source_environment_file "${BOOTSTRAP_DIR}.auto/environment"
#    then
#       flag="${MULLE_FLAG_LOG_FLUFF}"
#    else
#       if source_environment_file "${BOOTSTRAP_DIR}.local/environment"
#       then
#          flag="${MULLE_FLAG_LOG_FLUFF}"
#       else
#          if source_environment_file "${BOOTSTRAP_DIR}/environment"
#          then
#             flag="${MULLE_FLAG_LOG_FLUFF}"
#          fi
#       fi
#    fi

#    if [ "${flag}" = "YES" ]
#    then
#       log_fluff "Environment:"
#       env >&2
#    fi
# }


is_bootstrap_project()
{
   local  masterpath="${1:-.}"

   [ -d "${masterpath}/${BOOTSTRAP_DIR}" -o -d "${masterpath}/${BOOTSTRAP_DIR}.local" ]
}


is_master_bootstrap_project()
{
   local  masterpath="${1:-.}"

   [ -f "${masterpath}/${BOOTSTRAP_DIR}.local/is_master" ]
}


is_minion_bootstrap_project()
{
   local  minionpath="${1:-.}"

   [ -f "${minionpath}/${BOOTSTRAP_DIR}.local/is_minion" ]
}


#
# read local environment
# source this file
#
local_environment_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

   # name of the bootstrap folder, maybe changes this to .bootstrap9 for
   # some version ?
   BOOTSTRAP_DIR=".bootstrap"

   # can't reposition this because of embedded reposiories
   REPOS_DIR="${BOOTSTRAP_DIR}.repos"

   # can't reposition this because of embedded reposiories
   EMBEDDED_REPOS_DIR="${BOOTSTRAP_DIR}.repos/.embedded"

   # where regular repos are cloned to, when there is no path given
   STASHES_DEFAULT_DIR="stashes"

   # used by embedded repositories to change location
   STASHES_ROOT_DIR=""

   # our "sandbox" root, probably not changeable
   ROOT_DIR="`pwd -P`"

   # where we look for symlink sources
   DEFAULT_CACHES_DIR="`dirname -- "${ROOT_DIR}"`"


   log_fluff "${UNAME} detected"
   case "${UNAME}" in
      mingw)
         # be verbose by default on MINGW because its so slow
         if [ -z "${MULLE_TRACE}" ]
         then
           MULLE_FLAG_LOG_VERBOSE="YES"
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
   log_fluff ":local_environment_main:"
   # source_environment

   if [ "${MULLE_FLAG_EXECUTOR_DRY_RUN}" = "YES" ]
   then
      log_trace "Dry run is active."
   fi

   :
}


local_environment_initialize
