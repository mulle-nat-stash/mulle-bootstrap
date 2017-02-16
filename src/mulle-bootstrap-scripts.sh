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
#
MULLE_BOOTSTRAP_SCRIPTS_SH="included"


run_script()
{
   local script

   script="$1"
   shift

   [ ! -z "$script" ] || internal_fail "script is empty"

   if [ -x "${script}" ]
   then
      log_verbose "Executing script ${C_RESET_BOLD}${script}${C_VERBOSE} $1 ..."
      if  [ "${MULLE_FLAG_LOG_SCRIPTS}" = "YES" ]
      then
         echo "ARGV=" "$@" >&2
         echo "DIRECTORY=$PWD/$3" >&2
         echo "ENVIRONMENT=" >&2
         echo "{" >&2
         env | sed 's/^\(.\)/   \1/' >&2
         echo "}" >&2
      fi
      exekutor "${script}" "$@"  >&2 || fail "script \"${script}\" did not run successfully"
   else
      if [ ! -e "${script}" ]
      then
         fail "Script \"${script}\" not found ($PWD)"
      else
         fail "Script \"${script}\" not executable"
      fi
   fi
}


run_root_settings_script()
{
   local scriptname="$1" ; shift

   local script

   script="`find_root_setting_file "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
   fi
}


run_build_settings_script()
{
   local scriptname="$1" ; shift
   local name="$1" ; shift

   local script

   script="`find_build_setting_file "${name}" "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
   fi
}


#
# various scripts runner for fetch, designed to source in the build
# environment (slow on mingw, if needed)
#
fetch__run_root_settings_script()
{
   local scriptname="$1" ; shift

   local script

   script="`find_root_setting_file "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      build_complete_environment

      run_script "${script}" "$@"
   fi
}


fetch__run_build_settings_script()
{
   local scriptname="$1" ; shift
   local name="$1" ; shift

   local script

   script="`find_build_setting_file "${name}" "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      build_complete_environment

      run_script "${script}" "$@"
   fi
}


scripts_initialize()
{
   log_debug ":scripts_initialize:"
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]        && . mulle-bootstrap-settings.sh
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   :
}

scripts_initialize
