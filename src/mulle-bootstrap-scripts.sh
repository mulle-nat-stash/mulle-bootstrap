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

   
   value="`READ_SETTING_RETURNS_PATH="YES" read_repo_setting "$@"`"
   flag=$?

   echo "$value"
   return $flag
}


find_build_root_setting_file()
{
   local value
   local flag

   value="`READ_SETTING_RETURNS_PATH="YES" read_build_root_setting "$@"`"
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


run_build_root_settings_script()
{
   local  name

   scriptname="$1"
   shift

   [ -z "$scriptname" ] && internal_fail "scriptname is empty"

   local script

   script="`find_build_root_setting_file "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
   fi
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
   CLONES_SUBDIR="${owd}/${CLONES_SUBDIR}" \
   CLONESBUILD_SUBDIR="${owd}/${CLONESBUILD_SUBDIR}" \
   DEPENDENCY_SUBDIR="${owd}/${DEPENDENCY_SUBDIR}" \
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
      log_verbose "script \${script}\" not executed, because ${srcdir} does not exist"
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


run_fetch_settings_script()
{
   local  scriptname

   scriptname="$1"
   shift

   [ -z "$scriptname" ] && internal_fail "scriptname is empty"

   local script

   script="`find_fetch_setting_file "bin/${scriptname}.sh"`"
   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
      return $?
   fi
   return 0
}


scripts_initialize()
{
   log_fluff ":scripts_initialize:"
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh
}

scripts_initialize
