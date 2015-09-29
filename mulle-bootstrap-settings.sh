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
   local name

   file="$1"
   if [ "${DONT_WARN_RECURSION}" = "" -a "$MULLE_BOOTSTRAP_WARN_LOCAL_SETTINGS" = "YES" ]
   then
      echo "Using `dirname "${file}"` for `basename "${file}"`" >& 2
   fi
}


warn_local_setting()
{
   local name

   name="$1"
   if [ "${DONT_WARN_RECURSION}" = "" -a "$MULLE_BOOTSTRAP_WARN_LOCAL_SETTINGS" = "YES" ]
   then
      echo "Using `dirname "${file}"` for `basename "${file}"`" >& 2
   fi
}


read_setting()
{
   local file
   local value

   file="$1"
   [ ! -z "${file}" ] || fail "no path given to read_setting"

   # file not found = 2 (same as grep)

   if [ "$MULLE_BOOTSTRAP_TRACE_ACCESS_SETTINGS" = "YES" ]
   then
      log_trace2 "Looking for setting: ${file}"
   fi

   if [ ! -r "${file}" ]
   then
      return 2
   fi

   value=`egrep -v '^#|^[ ]*$' "${file}"`
   if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" ]
   then
      log_trace "setting `basename "${file}"` found in `dirname "${file}"` as \"${value}\""
   fi
   set +x
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
_read_local_setting()
{
   local name
   local value
   local envname

   name="$1"

   [ "$name" = "" ] && internal_fail "missing parameters in _read_local_setting"

   envname=`echo "${name}" | tr '[:lower:]' '[:upper:]'`
   value=`printenv "MULLE_BOOTSTRAP_${envname}"`

   if [ "${value}" != "" ]
   then
      echo "${value}"
      return 1
   else
      value="`read_setting "${BOOTSTRAP_SUBDIR}.local/${name}"`"
      if [ $? -ne 0 ]
      then
         value="`read_setting "${HOME}/.mulle-bootstrap/${name}"`"
         if [ $? -ne 0 ]
         then
             warn_user_setting "${HOME}/.mulle-bootstrap/${name}"
         fi
      fi
   fi
   echo "${value}"
}


read_local_setting()
{
   local name
   local value
   local default

   [ $# -lt 1 -o $# -gt 2 ] && internal_fail "parameterization error"

   name="$1"
   default="$2"

   value=`_read_local_setting "$name"`
   if [ "${value}" = "" ]
   then
      value="${default}"
   fi

   echo "$value"

   [ "${value}" = "${default}" ]
   return $?
}


#
# this has to be flexible, because fetch and build settings read differently
#
_read_bootstrap_setting()
{
   local name
   local value
   local default
   local suffix1
   local suffix2
   local suffix3

   name="$1"
   suffix1="$2"
   suffix2="$3"
   suffix3="$4"
   default="$5"

   [ $# -lt 4 -o $# -gt 5 ] && internal_fail "parameterization error"
   [ "$name" = "" ] && internal_fail "missing parameters in _read_bootstrap_setting"

   value="`read_setting "${BOOTSTRAP_SUBDIR}${suffix1}/${name}"`"
   if [ $? -ne 0 ]
   then
      value="`read_setting "${BOOTSTRAP_SUBDIR}${suffix2}/${name}"`"
      if [ $? -ne 0 ]
      then
         value="`read_setting "${BOOTSTRAP_SUBDIR}${suffix3}/${name}"`"
         if [ $? -ne 0 ]
         then
            if [ $# -eq 4 ]
            then
               return 2
            fi
            value="${default}"
         fi
      fi
   fi

   echo "$value"

   [ "${value}" = "${default}" ]
   return $?
}


read_repo_setting()
{
   local name
   local value
   local default
   local value

   [ $# -lt 2 -o $# -gt 3 ] && internal_fail "parameterization error"

   package="$1"
   name="$2"
   default="$3"

   [ "$name" = "" -o "$package" = "" ] && internal_fail "missing parameters in read_repo_setting"

   # need to conserve return value 2 if empty
   if [ $# -eq 2 ]
   then
      _read_bootstrap_setting  "settings/${package}/${name}" ".local" "" ".auto"
   else
      _read_bootstrap_setting  "settings/${package}/${name}" ".local" "" ".auto" "${default}"
   fi
}


#
# the default
#
read_config_setting()
{
   local name
   local value
   local default

   [ $# -lt 1 -o $# -gt 2 ] && internal_fail "parameterization error"

   name="$1"
   default="$2"

   value=`_read_bootstrap_setting "${name}" ".local/config" "config" ".auto/config"`
   if [ "${value}" = "" ]
   then
      value=`read_local_setting "${name}" "${default}"`
   fi

   echo "$value"

   [ "${value}" = "${default}" ]
   return $?
}


read_fetch_setting()
{
   _read_bootstrap_setting "$1" ".auto" ".local" "" "$2"
}


_read_build_setting()
{
   _read_bootstrap_setting "$1" ".local/settings" "/settings" ".auto/settings" "$2"
}


read_build_setting()
{
   local name
   local value
   local default

   package="$1"
   name="$2"
   default="$3"

   [ $# -lt 2 -o $# -gt 3 ] && internal_fail "parameterization error"
   [ "$name" = "" -o "$package" = "" ] && internal_fail "empty parameters in read_build_setting"

   value=`read_repo_setting "${package}" "${name}"`
   if [ $? -gt 1 ]
   then
      if [ $# -eq 2 ]
      then
          value=`_read_build_setting "${name}"`
      else
          value=`_read_build_setting "${name}" "${default}"`
      fi

      if [ $? -gt 1 ]
      then
         return 2
      fi
   fi
   echo "$value"

   [ "${value}" = "${default}" ]
   return $?
}


read_build_root_setting()
{
   _read_build_setting "$@"
}


read_yes_no_build_setting()
{
   local value

   value=`read_build_setting "$1" "$2" "$3"`
   is_yes "$value" "$1/$2"
}

read_sane_config_path_setting()
{
   local name
   local value
   local default

   name="$1"
   default="$2"

   value=`read_config_setting "${name}"`
   if [ "$?" -ne 0 ]
   then
      assert_sane_path "${value}"
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

   [ "$package" = "" ] && fail "script error"

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

