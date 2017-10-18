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
MULLE_BOOTSTRAP_LOG_SH="included"


log_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE} log [options] <dependency>

   Show build logs for a dependency.

Options:
   -l : list log files, don't cat them

EOF
  exit 1
}



log_main()
{
   log_debug ":log_main:"

   local OPTION_LIST="NO"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            log_usage
         ;;

         -l|--list)
            OPTION_LIST="YES"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown option $1"
            log_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh

   [ $# -ne 1 ] && log_usage

   dependency="$1"

   build_complete_environment

   [ -z "${CLONESBUILD_DIR}" ] && internal_fail "CLONESBUILD_DIR is empty"
   [ -z "${BUILDLOGS_DIR}" ] && internal_fail "BUILDLOGS_DIR is empty"

   if [ ! -d "${CLONESBUILD_DIR}" ]
   then
      log_info "Nothing has been built yet"
      return 0
   fi

   local something
   local filename
   local tool
   local configuration
   local sdk
   local info
   local i

   something="NO"
   IFS="
"
   for i in `ls -1 "${BUILDLOGS_DIR}/${dependency}"-*.log`
   do
      IFS="${DEFAULTIFS}"
      something="YES"

      if [ "${OPTION_LIST}" = "YES" ]
      then
         log_info "${i}"
      else
         filename="`basename -- "${i}" .log`"
         tool="${filename##*.}"
         info="${filename%.*}"
         info="$(sed s'/^.*--\(.*\)/\1/' <<< "${info}")"
         configuration="$(cut -d'-' -f 1 <<< "${info}")"
         sdk="$(cut -d'-' -f 2 <<< "${info}")"

         log_info "Log of ${C_RESET_BOLD}${tool:-unknown tool}${C_INFO} for \
${C_MAGENTA}${C_BOLD}${configuration:-Release}${C_INFO} build with SDK \
${C_MAGENTA}${C_BOLD}${sdk:-Default}${C_INFO} in \"${CLONESBUILD_DIR}/${dependency}\" ..."
         cat "$i"
      fi
   done
   IFS="${DEFAULTIFS}"

   if [ "${something}" = "NO" ]
   then
      log_info "${dependency} has not been built yet (or maybe  you mistyped the name ?)"
      return 0
   fi
}
