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
MULLE_BOOTSTRAP_LOGGING_SH="included"


MULLE_BOOTSTRAP_LOGGING_VERSION="3.0"

#
# WARNING! THIS FILE IS A LIBRARY USE BY OTHER PROJECTS
#          DO NOT CASUALLY RENAME, REORGANIZE STUFF
#
log_printf()
{
   local format="$1" ; shift

   if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
   then
      printf "${format}" "$@" >&2
   else
      printf "${format}" "$@" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
   fi
}


log_error()
{
   log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX} error: %b${C_RESET}\n" "$*"
}


log_fail()
{
   log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX} fatal error: %b${C_RESET}\n" "$*"
}


log_warning()
{
   if [ "${MULLE_FLAG_LOG_TERSE}" != "YES" ]
   then
      log_printf "${C_WARNING}${MULLE_EXECUTABLE_FAIL_PREFIX} warning: %b${C_RESET}\n" "$*"
   fi
}


log_info()
{
   if [ "${MULLE_FLAG_LOG_TERSE}" != "YES" ]
   then
      log_printf "${C_INFO}%b${C_RESET}\n" "$*"
   fi
}


log_verbose()
{
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES"  ]
   then
      log_printf "${C_VERBOSE}%b${C_RESET}\n" "$*"
   fi
}


log_fluff()
{
   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES"  ]
   then
      log_printf "${C_FLUFF}%b${C_RESET}\n" "$*"
   fi
}


# setting is like fluff but different color scheme
log_setting()
{
   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES"  ]
   then
      log_printf "${C_SETTING}%b${C_RESET}\n" "$*"
   fi
}

# for debugging, not for user. same as fluff
log_debug()
{
   if [ "${MULLE_FLAG_LOG_DEBUG}" = "YES"  ]
   then
      case "${UNAME}" in
         linux)
            log_printf "${C_BR_RED}$(date "+%s.%N") %b${C_RESET}\n" "$*"
         ;;
         *)
            log_printf "${C_BR_RED}$(date "+%s") %b${C_RESET}\n" "$*"
         ;;
      esac
   fi
}


log_trace()
{
   case "${UNAME}" in
      linux)
         log_printf "${C_TRACE}$(date "+%s.%N") %b${C_RESET}\n" "$*"
         ;;

      *)
         log_printf "${C_TRACE}$(date "+%s") %b${C_RESET}\n" "$*"
      ;;
   esac
}


log_trace2()
{
   case "${UNAME}" in
      linux)
         log_printf "${C_TRACE2}$(date "+%s.%N") %b${C_RESET}\n" "$*"
         ;;

      *)
         log_printf "${C_TRACE2}$(date "+%s") %b${C_RESET}\n" "$*"
      ;;
   esac
}


#
# some common fail log functions
#

stacktrace()
{
   local i=1
   local line

   while line="`caller $i`"
   do
      log_info "$i: #${line}"
      ((i++))
   done
}


_bail()
{
#   should kill process group...
#   kills calling shell too though
#   kill 0

#   if [ ! -z "${MULLE_EXECUTABLE_PID}" ]
#   then
#      kill -INT "${MULLE_EXECUTABLE_PID}"  # kill myself (especially, if executing in subshell)
#      if [ $$ -ne ${MULLE_EXECUTABLE_PID} ]
#      then
#         kill -INT $$  # actually useful
#      fi
#   fi
   sleep 1
   exit 1
}



fail()
{
   if [ ! -z "$*" ]
   then
      log_fail "$*"
   fi
   _bail
}


internal_fail()
{
   log_printf "${C_ERROR}${MULLE_EXECUTABLE_FAIL_PREFIX} *** internal error ***: %b${C_RESET}\n" "$*"
   stacktrace
   _bail
}


#
# here because often needed :-/
# this puts a space between items
#
concat()
{
   local i
   local s

   for i in "$@"
   do
      if [ -z "${i}" ]
      then
         continue
      fi

      if [ -z "${s}" ]
      then
         s="${i}"
      else
         s="${s} ${i}"
      fi
   done

   echo "${s}"
}

comma_concat()
{
   local i
   local s

   for i in "$@"
   do
      if [ -z "${i}" ]
      then
         continue
      fi

      if [ -z "${s}" ]
      then
         s="${i}"
      else
         s="${s}:${i}"
      fi
   done

   echo "${s}"
}



# Escape sequence and resets, should use tput here instead of ANSI
logging_initialize()
{
   DEFAULT_IFS="${IFS}" # as early as possible

   #
   # need this for scripts also
   #
   if [ -z "${UNAME}" ]
   then
      UNAME="`uname | cut -d_ -f1 | sed 's/64$//' | tr 'A-Z' 'a-z'`"
   fi

   if [ "${MULLE_BOOTSTRAP_NO_COLOR}" != "YES" ]
   then
      case "${UNAME}" in
         *)
            C_RESET="\033[0m"

            # Useable Foreground colours, for black/white white/black
            C_RED="\033[0;31m"     C_GREEN="\033[0;32m"
            C_BLUE="\033[0;34m"    C_MAGENTA="\033[0;35m"
            C_CYAN="\033[0;36m"

            C_BR_RED="\033[0;91m"
            C_BOLD="\033[1m"
            C_FAINT="\033[2m"

            C_RESET_BOLD="${C_RESET}${C_BOLD}"
            trap 'printf "${C_RESET}" >&2 ; exit 1' TERM INT
            ;;
      esac
   fi


   C_ERROR="${C_RED}${C_BOLD}"
   C_WARNING="${C_RED}${C_BOLD}"
   C_INFO="${C_CYAN}${C_BOLD}"
   C_VERBOSE="${C_GREEN}${C_BOLD}"
   C_FLUFF="${C_GREEN}${C_BOLD}"
   C_SETTING="${C_GREEN}${C_FAINT}"
   C_TRACE="${C_FLUFF}${C_FAINT}"
   C_TRACE2="${C_RESET}${C_FAINT}"

   if [ ! -z "${MULLE_BOOTSTRAP_LIBEXEC_TRACE}" ]
   then
      local exedir
      local exedirpath

      exedir="`dirname "${BASH_SOURCE}"`"
      exedirpath="`( cd "${exedir}" ; pwd -P )`" || fail "failed to get pwd"
      echo "${MULLE_EXECUTABLE} libexec: ${exedirpath}" >&2
   fi
}

logging_initialize "$@"

:
