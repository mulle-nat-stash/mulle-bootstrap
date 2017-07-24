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
MULLE_BOOTSTRAP_CORE_OPTIONS_SH="included"


## core option parsing
# not used by mulle-bootstrap itself at the moment

#
# variables called flag. because they are indirectly set by flags
#
core_dump_env()
{
   log_trace "FULL trace started"
   log_trace "ARGS:${C_TRACE2} ${MULLE_ARGUMENTS}"
   log_trace "PWD :${C_TRACE2} `pwd -P 2> /dev/null`"
   log_trace "ENV :${C_TRACE2} `env | sort`"
   log_trace "LS  :${C_TRACE2} `ls -a1F`"
}


core_setup_trace()
{
   case "${1}" in
      VERBOSE)
         MULLE_FLAG_LOG_VERBOSE="YES"
      ;;

      FLUFF)
         MULLE_FLAG_LOG_FLUFF="YES"
         MULLE_FLAG_LOG_VERBOSE="YES"
         MULLE_FLAG_LOG_EXEKUTOR="YES"
      ;;

      TRACE)
         MULLE_FLAG_LOG_SETTINGS="YES"
         MULLE_FLAG_LOG_EXEKUTOR="YES"
         MULLE_FLAG_LOG_FLUFF="YES"
         MULLE_FLAG_LOG_VERBOSE="YES"
         core_dump_env
      ;;

      1848)
         MULLE_FLAG_LOG_SETTINGS="YES"
         MULLE_FLAG_LOG_FLUFF="YES"
         MULLE_FLAG_LOG_VERBOSE="YES"
         MULLE_FLAG_VERBOSE_BUILD="YES"

         core_dump_env

         if [ "${MULLE_TRACE_POSTPONE}" != "YES" ]
         then
            log_trace "1848 trace (set -x) started"
            set -x
            PS4="+ ${ps4string} + "
         fi
      ;;
   esac
}


core_technical_option_usage()
{
   cat <<EOF
   -n        : dry run
   -s        : be silent
   -v        : be verbose
EOF

   if [ ! -z "${MULLE_TRACE}" ]
   then
      cat <<EOF
   -ld       : additional debug output
   -le       : external command execution log output
   -t        : enable shell trace
   -tpwd     : emit shortened PWD during trace
   -vv       : be more verbose
   -vvv      : be very verbose
EOF
   fi
}


core_technical_flags()
{
   case "$1" in
      -n|--dry-run)
         MULLE_FLAG_EXEKUTOR_DRY_RUN="YES"
      ;;

      -ld|--log-debug)
         MULLE_FLAG_LOG_DEBUG="YES"
      ;;

      -le|--log-execution)
         MULLE_FLAG_LOG_EXEKUTOR="YES"
      ;;

      -t|--trace)
         MULLE_TRACE="1848"
         ps4string='${BASH_SOURCE[1]##*/}:${LINENO}'
      ;;

      -tfpwd|--trace-full-pwd)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"
         ps4string='${BASH_SOURCE[1]##*/}:${LINENO} \"\w\"'
      ;;

      -tp|--trace-profile)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"

         case "${UNAME}" in
            "")
               internal_fail "UNAME must be set by now"
            ;;
            linux)
               ps4string='$(date "+%s.%N (${BASH_SOURCE[1]##*/}:${LINENO})")'
            ;;
            *)
               ps4string='$(date "+%s (${BASH_SOURCE[1]##*/}:${LINENO})")'
            ;;
         esac
      ;;

      -tpo|--trace-postpone)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"
         MULLE_TRACE_POSTPONE="YES"
      ;;

      -tpwd|--trace-pwd)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"
         ps4string='${BASH_SOURCE[1]##*/}:${LINENO} \".../\W\"'
      ;;

      -tx|--trace-options)
         set -x
      ;;

      -v|--verbose)
        [ "${MULLE_TRACE}" = "1848" ] && log_warning "${MULLE_EXECUTABLE_FAIL_PREFIX}: -v after -t invalidates -t"

         MULLE_TRACE="VERBOSE"
      ;;

      -vv|--very-verbose)
        [ "${MULLE_TRACE}" = "1848" ] && log_warning "${MULLE_EXECUTABLE_FAIL_PREFIX}: -vv after -t invalidates -t"

         MULLE_TRACE="FLUFF"
      ;;

      -vvv|--very-very-verbose)
        [ "${MULLE_TRACE}" = "1848" ] && log_warning "${MULLE_EXECUTABLE_FAIL_PREFIX}: -vvv after -t invalidates -t"

         MULLE_TRACE="TRACE"
      ;;

      -s|--silent)
         MULLE_TRACE=
         MULLE_FLAG_LOG_TERSE="YES"
      ;;

      *)
         return 1
      ;;
   esac

   return 0
}



core_options_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh
}

core_options_initialize

:
