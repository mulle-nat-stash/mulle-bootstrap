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
MULLE_BOOTSTRAP_SHELL_SH="included"


setting_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE} shell [options]

Options:
   -m   : set CPPFLAGS and LDFLAGS in environment for make

EOF
  exit 1
}


shell_main()
{
   local env_string
   local cmd_string
   local prompt_string

   local OPTION_MAKE_FLAGS="NO"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help)
            shell_usage
         ;;

         -m|--make)
            OPTION_MAKE_FLAGS="YES"
         ;;


         # argument gitflags
         -*)
            fail "unknown option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   #
   # could pimp this up with CPPFLAGS and LDFLAGS too
   # but do I want this ?
   #
   local options

   options="run"
   if [ "${OPTION_MAKE_FLAGS}" = "YES" ]
   then
      options="${options} make"
   fi

   env_string="`mulle-bootstrap paths -m -1 -q "'" ${options}`"
   cmd_string="${SHELL:-/usr/bin/env bash}"

   case "${cmd_string}" in
      *bash|*dash)
         prompt_string="`mulle-bootstrap project-path`"
         prompt_string="PS1='\u@\h[`basename -- "${prompt_string}"`] \W$ '"
      ;;
   esac

   eval_exekutor ${env_string} "${prompt_string}" "'${cmd_string}'"
}


#
# read some config stuff now
#
shell_initialize()
{
   log_debug ":shell_initialize:"

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
}


shell_initialize
