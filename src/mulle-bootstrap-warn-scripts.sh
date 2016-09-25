#! /bin/sh
#
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
MULLE_BOOTSTRAP_WARN_SCRIPTS_SH="included"


warn_scripts()
{
   local bootstrapdir
   local repodir

   bootstrapdir="$1"
   repodir="$2"

   local scripts
   local phases
   local ack
   local i
   local old

   log_info "warn_scripts $1:$2:${DONT_ASK_AFTER_WARNING}:${MULLE_BOOTSTRAP_ANSWER}"

   if [ -d "${bootstrapdir}" ]
   then
      scripts="`find "${bootstrapdir}" -name "*.sh" \( -perm +u+x -o -perm +g+x -o -perm +o+x \) -type f -print`"
      if [ ! -z "${scripts}" ]
      then
         log_warning "this .bootstrap contains shell scripts:"
         old="${IFS:-" "}"
         IFS="
"
         echo "${C_BOLD}--------------------------------------------------------${C_RESET}" >&2
         for i in $scripts
         do
            echo "${C_BOLD}$i:${C_RESET}" >&2
            echo "${C_BOLD}--------------------------------------------------------${C_RESET}" >&2
            cat "$i" >&2
            echo "${C_BOLD}--------------------------------------------------------${C_RESET}" >&2
         done
         echo "" >&2
         IFS="${old}"
      fi
   fi

   case "${UNAME}" in
      darwin)
         if [ ! -z "${repodir}" ]
         then
             exekutor [ -e "${repodir}" ] || fail "Expected directory \"${repodir}\" is missing.
(hint: use fetch instead of update to track renames)"

            if dir_has_files "${repodir}"
            then
               phases="`(find "${repodir}"/* -name "project.pbxproj" -exec grep -q 'PBXShellScriptBuildPhase' '{}' \; -print)`"
               if [ ! -z "${phases}" ]
               then
                  log_warning "This repository contains xcode projects with shellscript phases"

                  ack=`which_binary ack`
                  if [ -z "${ack}" ]
                  then
                     log_warning "$phases" >&2

                     log_info "To view them inline install \"ack\""
                     case "${UNAME}" in
                        darwin|linux)
                           log_info "   brew install ack" >&2
                           ;;
                     esac
                  else
                     ack -A1 "shellPath|shellScript" `echo "${phases}" | tr '\n' ' '` >&2
                  fi
                  echo "" >&2
               fi
            fi
         fi
      ;;
   esac

   if [ -z "$phases" -a -z "$scripts" ]
   then
      return 0
   fi

   if [ "${DONT_ASK_AFTER_WARNING}" = "YES" ]
   then
      return 0
   fi

   user_say_yes "You should probably inspect them before continuing.
Abort now ?"
   if [ $? -eq 0 ]
   then
       log_error "The bootstrap is in an inconsistent state. It would be good
to run
     ${C_RESET}mulle-bootstrap clean dist${C_ERROR}
now."
       return 1
   fi
}


warn_scripts_main()
{
   log_fluff "::: warn_scripts begin :::"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh

   local  dont_warn_scripts

   #
   # if MULLE_BOOTSTRAP_ANSWER is YES
   # then don't warn either
   #
   dont_warn_scripts="`read_config_setting "dont_warn_scripts" "${MULLE_BOOTSTRAP_ANSWER:-NO}"`"

   if [ "${dont_warn_scripts}" = "YES"  ]
   then
      log_verbose "Script checking disabled"
   else
      warn_scripts "$@"
   fi

   log_fluff "::: warn_scripts end :::"
}
