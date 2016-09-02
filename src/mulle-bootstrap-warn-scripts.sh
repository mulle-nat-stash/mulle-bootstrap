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


[ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
[ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh


warn_scripts()
{
   local scripts
   local phases
   local ack
   local i
   local old

   if [ -d "$1" ]
   then
      scripts="`find "$1" -name "*.sh" \( -perm +u+x -o -perm +g+x -o -perm +o+x \) -type f -print`"
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

   if [ ! -z "$2" ]
   then
       exekutor [ -e "$2" ] || fail "Expected directory \"$2\" is missing.
(hint: use fetch instead of update to track renames)"

      if dir_has_files "$2"
      then
         phases="`(find "$2"/* -name "project.pbxproj" -exec grep -q 'PBXShellScriptBuildPhase' '{}' \; -print)`"
         if [ ! -z "${phases}" ]
         then
            log_warning "This repository contains xcode projects with shellscript phases"

            ack=`which_binary ack`
            if [ -z "${ack}" ]
            then
               log_warning "$phases" >&2

               log_info "To view them inline install \"ack\""
               case "`uname`" in
                  Darwin|Linux)
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

   if  [ "${DONT_ASK_AFTER_WARNING}" != "YES" ]
   then
      if [ "$phases" != "" -o "$scripts" != "" ]
      then
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
      fi
   fi
}


warn_scripts_main()
{
   if [ "${MULLE_BOOTSTRAP_ANSWER}" != "YES"  ]
   then
      warn_scripts "$@"
   else
      log_verbose "Script checking by autoanswer YES disabled"
   fi
}
