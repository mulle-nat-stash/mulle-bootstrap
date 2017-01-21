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
      if  [ "${MULLE_BOOTSTRAP_TRACE_SCRIPT_CALLS}" = "YES" ]
      then
         echo "ARGV=" "$@" >&2
         echo "DIRECTORY=$PWD/$3" >&2
         echo "ENVIRONMENT=" >&2
         echo "{" >&2
         env | sed 's/^\(.\)/   \1/' >&2
         echo "}" >&2
      fi
      exekutor "${script}" "$@" || fail "script \"${script}\" did not run successfully"
   else
      if [ ! -e "${script}" ]
      then
         fail "script \"${script}\" not found ($PWD)"
      else
         fail "script \"${script}\" not executable"
      fi
   fi
}


run_log_script()
{
   echo "$@"
   run_script "$@"
}


find_fetch_setting_file()
{
   local value
   local flag

   value="`READ_SETTING_RETURNS_PATH="YES" read_fetch_setting "$@"`"
   flag=$?

   echo "$value"
   return $flag
}


find_repo_setting_file()
{
   local value
   local flag


   value="`READ_SETTING_RETURNS_PATH="YES" read_build_setting "$@"`"
   flag=$?

   echo "$value"
   return $flag
}


find_build_setting_file()
{
   local value
   local flag

   value="`READ_SETTING_RETURNS_PATH="YES" read_build_setting "$@"`"
   flag=$?

   echo "$value"
   return $flag
}



# run in subshell
run_fake_environment_script()
{
   local srcdir
   local script

   srcdir="$1"
   shift
   script="$1"
   shift

   ( owd="`pwd -P`"; cd "${srcdir}" ;
   REPOS_DIR="${owd}/${REPOS_DIR}" \
   CLONESBUILD_SUBDIR="${owd}/${CLONESBUILD_SUBDIR}" \
   DEPENDENCIES_DIR="${owd}/${DEPENDENCIES_DIR}" \
   ADDICTIONS_DIR="${owd}/${ADDICTIONS_DIR}" \
   run_script "${owd}/${script}" "$@" ) || exit 1
}


# repo setting scripts are treated as if inherrited
run_repo_settings_script()
{
   local name
   local scriptname
   local srcdir

   name="$1"
   shift
   srcdir="$1"
   shift
   scriptname="$1"
   shift

   exekutor [ -e "$srcdir" ] || internal_fail "directory srcdir \"${srcdir}\" is wrong ($PWD)"
   [ ! -z "$name" ]          || internal_fail "name is empty"
   [ ! -z "$scriptname" ]    || internal_fail "scriptname is empty"

   local script

   script="`find_repo_setting_file "${name}" "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      run_fake_environment_script "${srcdir}" "${script}" "$@" || exit 1
   fi
}


run_build_settings_script()
{
   local srcdir
   local name
   local scriptname
   local url

   name="$1"
   shift
   url="$1"
   shift
   srcdir="$1"
   shift
   scriptname="$1"
   shift

   # can happen, if system libs override
   if [ ! -e "$srcdir" ]
   then
      log_verbose "script \"${scriptname}\" not executed, because ${srcdir} does not exist"
      return 0
   fi

   [ ! -z "$name" ]           || internal_fail "name is empty"
   [ ! -z "$url" ]            || internal_fail "url is empty"
   [ ! -z "$scriptname" ]     || internal_fail "scriptname is empty"

   local script

   script="`find_build_setting_file "${name}" "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      run_script "${script}" "${name}" "${url}" "${srcdir}" "$@" || exit 1
   fi
}


#
# various scripts runner for fetch, designed to source in the build
# environment (slow on mingw, if needed)
#
fetch__run_script()
{
   [ -z "${MULLE_BOOTSTRAP_BUILD_ENVIRONMENT_SH}" ] && . mulle-bootstrap-build-environment.sh
   build_complete_environment

   run_script "$@"
}


fetch__run_fetch_settings_script()
{
   local  scriptname

   scriptname="$1"
   shift

   [ -z "$scriptname" ] && internal_fail "scriptname is empty"

   local script

   script="`find_fetch_setting_file "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      fetch__run_script "${script}" "$@"
      return $?
   fi
   return 0
}


fetch__run_build_settings_script()
{
   local srcdir
   local name
   local scriptname
   local url

   name="$1"
   shift
   url="$1"
   shift
   srcdir="$1"
   shift
   scriptname="$1"
   shift

   # can happen, if system libs override
   if [ ! -e "$srcdir" ]
   then
      log_verbose "script \"${scriptname}\" not executed, because ${srcdir} does not exist"
      return 0
   fi

   [ ! -z "$name" ]           || internal_fail "name is empty"
   [ ! -z "$url" ]            || internal_fail "url is empty"
   [ ! -z "$scriptname" ]     || internal_fail "scriptname is empty"

   local script

   script="`find_build_setting_file "${name}" "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      fetch__run_script "${script}" "${name}" "${url}" "${srcdir}" "$@" || exit 1
   fi
}


fetch__run_repo_settings_script()
{
   local name
   local scriptname
   local srcdir

   name="$1"
   shift
   srcdir="$1"
   shift
   scriptname="$1"
   shift

   exekutor [ -e "$srcdir" ] || internal_fail "directory srcdir \"${srcdir}\" is wrong ($PWD)"
   [ ! -z "$name" ]          || internal_fail "name is empty"
   [ ! -z "$scriptname" ]    || internal_fail "scriptname is empty"

   local script

   script="`find_repo_setting_file "${name}" "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      [ -z "${MULLE_BOOTSTRAP_BUILD_ENVIRONMENT_SH}" ] && . mulle-bootstrap-build-environment.sh
      build_complete_environment

      run_fake_environment_script "${srcdir}" "${script}" "$@" || exit 1
   fi
}


scripts_initialize()
{
   log_fluff ":scripts_initialize:"
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh
}

scripts_initialize
