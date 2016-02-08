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

. mulle-bootstrap-functions.sh


warn_user_setting()
{
   local file

   file="$1"
   if [ "$MULLE_BOOTSTRAP_NO_WARN_USER_SETTINGS" != "YES" ]
   then
      log_warning "Using `dirname -- "${file}"` for `basename -- "${file}"`"
   fi
}


warn_local_setting()
{
   local file

   file="$1"
   if [ "$MULLE_BOOTSTRAP_NO_WARN_LOCAL_SETTINGS" != "YES" ]
   then
      log_warning "Using `dirname -- "${file}"` for `basename -- "${file}"`"
   fi
}


warn_environment_setting()
{
   local name

   name="$1"
   if [ "$MULLE_BOOTSTRAP_NO_WARN_ENVIRONMENT_SETTINGS" != "YES" ]
   then
      # don't trace some boring ones
      if [ "${name}" != "MULLE_BOOTSTRAP_ANSWER" -a "${name}" != "MULLE_BOOTSTRAP_VERBOSE" ]
      then
         log_warning "Using environment variable \"${name}\""
      fi
   fi
}

#
# Base functions, not be called outside of this file
#
_read_setting()
{
   local file
   local value
   local flag

   file="$1"
   [ ! -z "${file}" ] || fail "no path given to read_setting"

   # file not found = 2 (same as grep)

   [ -r "${file}" ]
   flag=$?

   if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" ]
   then
      local  yesno

      yesno="not found"
      if [ $flag -eq 0 ]
      then
         yesno="found"
      fi
      log_trace2 "Looking for setting: ${file} (pwd=$PWD) : $yesno"
   fi

   if [ $flag -eq 1 ]
   then
      return 2
   fi

   if [ "${READ_SETTING_RETURNS_PATH}" = "YES" ]
   then
      value="${file}"
      if [ "$MULLE_BOOTSTRAP_VERBOSE" = "YES"  ]
      then
         local os
         os="`uname`"
         log_fluff "${C_MAGENTA}`basename -- "${file}" ".${os}"`${C_FLUFF} found as \"${file}\""
      fi
   else
      value=`egrep -v '^#|^[ ]*$' "${file}"`
      if [ "${MULLE_BOOTSTRAP_VERBOSE}" = "YES"  ]
      then
         local os
         os="`uname`"
         log_fluff "Setting ${C_MAGENTA}`basename -- "${file}" ".${os}"`${C_FLUFF} found in \"${file}\" as ${C_MAGENTA}${value}${C_FLUFF}"
      fi
   fi

   case "${file}" in
      *.local/*)
         warn_local_setting "${file}"
      ;;
   esac

   echo "${value}"
}


#
# this knows intentionally no default, you cant have an empty
# local setting
#
_read_environment_setting()
{
   local name
   local value
   local envname

   [ $# -ne 1  ] && internal_fail "parameterization error"

   name="$1"

   [ "$name" = "" ] && internal_fail "missing parameters in _read_local_setting"

   envname="MULLE_BOOTSTRAP_`echo "${name}" | tr '[:lower:]' '[:upper:]'`"

   if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" ]
   then
      log_trace2 "Looking for setting \"${name}\" as environment variable \"${envname}\""
   fi

   value=`printenv "${envname}"`
   if [ "${value}" = "" ]
   then
      return 2
   fi

   if [ "${MULLE_BOOTSTRAP_VERBOSE}" = "YES" ]
   then
      log_trace "Setting ${C_MAGENTA_BOLD}${name}${C_TRACE} found in environment variable \"${envname}\" as ${C_MAGENTA_BOLD}${value}${C_TRACE}"
   fi

   warn_environment_setting "${envname}"

   echo "${value}"
   return 0
}


_read_local_setting()
{
   local name
   local value
   local default

   [ $# -ne 1  ] && internal_fail "parameterization error"

   name="$1"

   [ "$name" = "" ] && internal_fail "missing parameters in _read_local_setting"

   if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" ]
   then
      log_trace2 "Looking for setting \"${name}\" in \"~/.mulle-bootstrap\""
   fi

   value="`_read_setting "${HOME}/.mulle-bootstrap/${name}"`"
   if [ $? -ne 0 ]
   then
      return 2
   fi

   if [ "${MULLE_BOOTSTRAP_VERBOSE}" = "YES" ]
   then
      log_trace "Setting ${C_MAGENTA_BOLD}${name}${C_TRACE} found in \"~/.mulle-bootstrap\" as ${C_MAGENTA_BOLD}${value}${C_TRACE}"
   fi
   warn_user_setting "${HOME}/.mulle-bootstrap/${name}"

   echo "$value"
}


#
# this has to be flexible, because fetch and build settings read differently
#
_read_bootstrap_setting()
{
   local name
   local value
   local suffix

   name="$1"
   shift

   [ $# -gt 0 ]      || internal_fail "parameterization error"
   [ ! -z "${name}" ] || internal_fail "missing parameters in _read_bootstrap_setting"

   while [ $# -gt 0 ]
   do
      suffix="${1}"
      shift

      value="`_read_setting "${BOOTSTRAP_SUBDIR}${suffix}/${name}"`"
      if [ $? -eq 0 ]
      then
         echo "${value}"
         return 0
      fi
   done

   return 2
}


_read_repo_setting()
{
   local name
   local package

   package="$1"
   name="$2"

   [ ! -z "$name" ]    || internal_fail "empty name in _read_repo_setting( $*)"
   [ ! -z "$package" ] || internal_fail "empty package in _read_repo_setting( $*)"

   # need to conserve return value 2 if empty
   _read_bootstrap_setting  "settings/${package}/${name}" ".local" "" ".auto"
}


_read_build_setting()
{
   _read_bootstrap_setting "$1" ".local/settings" "/settings" ".auto/settings"
}


####
#
# Functions building on _read_ functions
#
read_config_setting()
{
   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set +x
   fi

   local name
   local default

   [ $# -lt 1 -o $# -gt 2 ] && internal_fail "parameterization error"

   name="$1"
   default="$2"

   local value

   value="`_read_environment_setting "${name}"`"
   if [ $? -ne 0 ]
   then
      value=`_read_bootstrap_setting "${name}" ".local/config" "/config" ".auto/config"`
      if [ $? -ne 0 ]
      then
         value=`_read_local_setting "${name}"`
         if [ $? -ne 0 ]
         then
            value="${default}"
         fi
      fi
   fi

   echo "$value"

   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set -x
   fi

   [ "${value}" = "${default}" ]
   return $?
}


read_build_setting()
{
   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set +x
   fi

   local name
   local default
   local package

   [ $# -lt 2 -o $# -gt 3 ] && internal_fail "parameterization error"

   package="$1"
   name="$2"
   default="$3"

   local value

   value=`_read_repo_setting "${package}" "${name}"`
   if [ $? -ne 0 ]
   then
      value=`_read_build_setting "${name}"`
      if [ $? -ne 0 ]
      then
         value="${default}"
      fi
   fi
   echo "$value"

   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set -x
   fi

   [ "${value}" = "${default}" ]
   return $?
}


read_repo_setting()
{
   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set +x
   fi

   local name
   local default
   local package

   [ $# -lt 2 -o $# -gt 3 ] && internal_fail "parameterization error"

   package="$1"
   name="$2"
   default="$3"

   local value

   value="`_read_repo_setting "${package}" "${name}"`"
   if [ $? -ne 0 ]
   then
      value="${default}"
   fi

   echo "$value"

   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set -x
   fi

   [ "${value}" = "${default}" ]
   return $?
}


read_build_root_setting()
{
   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set +x
   fi

   local value
   local name
   local default

   [ $# -lt 1 -o $# -gt 2 ] && internal_fail "parameterization error"

   name="$1"
   default="$2"

   value="`_read_build_setting "${name}" ".auto" ".local" ""`"
   if [ $? -ne 0 ]
   then
      value="${default}"
   fi

   echo "$value"

   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set -x
   fi

   [ "${value}" = "${default}" ]
   return $?
}


read_fetch_setting()
{
   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set +x
   fi

   local value
   local default
   local name

   name="$1"
   default="$2"

   local os

   value="`_read_bootstrap_setting "${name}" ".auto" ".local"`"
   if [ $? -ne 0 ]
   then
      os="`uname`"
      value="`_read_bootstrap_setting "${name}.${os}" ""`"
      if [ $? -ne 0 ]
      then
         value="`_read_bootstrap_setting "${name}" ""`"
         if [ $? -ne 0 ]
         then
           value="${default}"
         fi
      fi
   fi

   echo "$value"

   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set -x
   fi

   [ "${value}" = "${default}" ]
   return $?
}


####
# Functions building on read_ functions
#
read_yes_no_build_setting()
{
   local value

   value=`read_build_setting "$1" "$2" "$3"`
   is_yes "$value" "$1/$2"
}


read_yes_no_config_setting()
{
   local value

   value=`read_config_setting "$1" "$2"`
   is_yes "$value" "$1"
}



read_sane_config_path_setting()
{
   local name
   local value
   local default

   name="$1"
   default="$2"

   value=`read_config_setting "${name}"`
   if [ $? -ne 0 ]
   then
      assert_sane_subdir_path "${value}"
   else
      if [ "$value" = "" ]
      then
         value="${default}"
      fi
   fi

   echo "$value"

   [ "${value}" = "${default}" ]
   return $?
}



###
#
#

all_build_flag_keys()
{
   local keys1
   local keys2
   local keys3
   local keys4
   local keys5
   local keys6
   local package

   package="$1"

   [ ! -z "$package" ] || internal_fail "script error"

   keys1=`(cd "${BOOTSTRAP_SUBDIR}.local/settings/${package}" 2> /dev/null || exit 1; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys2=`(cd "${BOOTSTRAP_SUBDIR}/settings/${package}" 2> /dev/null || exit 1 ; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys3=`(cd "${BOOTSTRAP_SUBDIR}.auto/settings/${package}" 2> /dev/null || exit 1 ; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys4=`(cd "${BOOTSTRAP_SUBDIR}.local" 2> /dev/null || exit 1 ; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys5=`(cd "${BOOTSTRAP_SUBDIR}"  2> /dev/null || exit 1 ; \
           ls -1  | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys6=`(cd "${BOOTSTRAP_SUBDIR}.auto"  2> /dev/null || exit 1 ; \
           ls -1  | egrep '\b[A-Z][A-Z_0-9]+\b')`

   echo "${keys1}
${keys2}
${keys3}
${keys4}
${keys5}
${keys6}" | sort | sort -u | egrep -v '^[ ]*$'
   return 0
}


# read some config stuff now

MULLE_BOOTSTRAP_NO_WARN_LOCAL_SETTINGS="`read_config_setting "no_warn_local_setting"`"
MULLE_BOOTSTRAP_NO_WARN_USER_SETTINGS="`read_config_setting "no_warn_user_setting"`"
MULLE_BOOTSTRAP_NO_WARN_ENVIRONMENT_SETTINGS="`read_config_setting "no_warn_environment_setting"`"
