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

[ ! -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && echo "double inclusion of logging" >&2 && exit 1
MULLE_BOOTSTRAP_LOGGING_SH="included"


#
# need this for scripts also
#
if [ -z "${UNAME}" ] 
then
   UNAME="`uname | cut -d_ -f1 | sed 's/64$//'`"
fi


# Escape sequence and resets, should use tput here instead of ANSI


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
         trap 'printf "${C_RESET}"' TERM EXIT
         ;;
   esac
fi


C_ERROR="${C_RED}${C_BOLD}"
log_error()
{
   printf "${C_ERROR}%b${C_RESET}\n" "$*" >&2
}


C_WARNING="${C_MAGENTA}${C_BOLD}"
log_warning()
{
   if [ "${MULLE_BOOTSTRAP_TERSE}" != "YES" ]
   then
      printf "${C_WARNING}%b${C_RESET}\n" "$*" >&2
   fi
}


C_INFO="${C_CYAN}${C_BOLD}"
log_info()
{
   if [ "${MULLE_BOOTSTRAP_TERSE}" != "YES" ]
   then
      printf "${C_INFO}%b${C_RESET}\n" "$*" >&2
   fi
}


C_VERBOSE="${C_GREEN}${C_BOLD}"
log_verbose()
{
   if [ "${MULLE_BOOTSTRAP_VERBOSE}" = "YES"  ]
   then
      printf "${C_VERBOSE}%b${C_RESET}\n" "$*" >&2
   fi
}


C_FLUFF="${C_GREEN}${C_BOLD}"
log_fluff()
{
   if [ "${MULLE_BOOTSTRAP_FLUFF}" = "YES"  ]
   then
      printf "${C_FLUFF}%b${C_RESET}\n" "$*" >&2
   fi
}


C_TRACE="${C_FLUFF}${C_FAINT}"
log_trace()
{
   printf "${C_TRACE}%b${C_RESET}\n" "$*" >&2
}


C_TRACE2="${C_RESET}${C_FAINT}"
log_trace2()
{
   printf "${C_TRACE2}%b${C_RESET}\n" "$*" >&2
}


#
# some common fail log functions
#
fail()
{
   log_error "$@"
   if [ ! -z "${MULLE_BOOTSTRAP_PID}" ]
   then
      kill -INT "${MULLE_BOOTSTRAP_PID}"  # kill myself (especially, if executing in subshell)
      if [ $$ -ne ${MULLE_BOOTSTRAP_PID} ]
      then
         kill -INT $$  # actually useful
      fi
   fi
   exit 1        # paranoia
   # don't ask me why the fail message is printed twice
}


internal_fail()
{
   fail "${C_RED}*** internal error: ${C_BR_RED}$*"
}
