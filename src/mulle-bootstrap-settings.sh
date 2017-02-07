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
MULLE_BOOTSTRAP_SETTINGS_SH="included"


config_usage()
{
    cat <<EOF >&2
usage:
   mulle-bootstrap config <name> [value]
EOF
  exit 1
}


setting_usage()
{
    cat <<EOF >&2
usage:
   mulle-bootstrap setting [-r <repository>] <name>
EOF
  exit 1
}


warn_user_setting()
{
   local path

   path="$1"

   if [ "$MULLE_BOOTSTRAP_NO_WARN_USER_SETTINGS" != "YES" ]
   then
      log_warning "Using `dirname -- "${path}"` for `basename -- "${path}"`"
   fi
}


warn_local_setting()
{
   local path

   path="$1"

   if [ "$MULLE_BOOTSTRAP_NO_WARN_LOCAL_SETTINGS" != "YES" ]
   then
      log_warning "Using `dirname -- "${path}"` for `basename -- "${path}"`"
   fi
}


warn_environment_setting()
{
   local name

   name="$1"
   if [ "$MULLE_BOOTSTRAP_NO_WARN_ENVIRONMENT_SETTINGS" != "YES" ]
   then
      # don't trace some boring ones
      if [ "${name}" != "MULLE_BOOTSTRAP_ANSWER" -a \
           "${name}" != "MULLE_BOOTSTRAP_VERBOSE" -a \
           "${name}" != "MULLE_BOOTSTRAP_TRACE" ]
      then
         log_warning "Using environment variable \"${name}\""
      fi
   fi
}


__read_setting()
{
   local path="$1"

   egrep -s -v '^#|^[ ]*$' "${path}"
}


_copy_no_clobber_setting_file()
{
   local dst="${1:-.}" ; shift
   local src="${1:-.}" ; shift

   if [ ! -f "${dst}" ]
   then
      exekutor cp ${COPYMOVEFLAGS} "${src}" "${dst}"
   else
      value1="`__read_setting "${src}"`"
      value2="`__read_setting "${dst}"`"

      if [ "${value1}" != "${value2}" ]
      then
         fail "\"${src}\" is incompatible with \"${dst}\", which is already present."
      fi
      log_fluff "Skipping \"${src}\" as it's already present."
   fi
}


#
# Base function, not be called outside of this file
#
_read_setting()
{
   local path="$1"
   local name="$2"

   [ ! -z "${path}" ] || fail "no path given to read_setting"
   [ ! -z "${name}" ] || fail "no name given to read_setting"

   local value

   # file not found = 2 (same as grep)

   if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" ]
   then
      local  yesno

      if [ ! -r "${path}" ]
      then
         yesno="not "
      fi

      log_trace2 "Looking for setting: ${path} (pwd=$PWD) : ${yesno}found"
   fi


   if [ "${READ_SETTING_RETURNS_PATH}" = "YES" ]
   then
      value="${path}"
      if [ ! -r "${path}" ]
      then
         return 2
      fi

      if [ "$MULLE_BOOTSTRAP_VERBOSE" = "YES"  ]
      then
         log_setting "${C_MAGENTA}${name}${C_SETTING} found as \"${path}\""
      fi

      echo "${value}"
      return 0
   fi

   local rval

   #
   # remove empty lines, remove comment lines
   #
   value="`__read_setting "${path}"`"
   rval=$?

   if [ $rval -eq 2 ]
   then
      return 2   # it's grep :)
   fi

   if [ "${MULLE_BOOTSTRAP_VERBOSE}" = "YES"  ]
   then
      local apath

      apath="`absolutepath "${path}"`"

      # make some boring names less prominent
      if [ "${name}" = "repositories" -o \
           "${name}" = "repositories.tmp" -o \
           "${name}" = "build_order" -o \
           "${name}" = "versions" -o \
           "${name}" = "embedded_repositories" -o \
           "${name}" = "MULLE_REPOSITORIES" -o \
           "${name}" = "MULLE_NAT_REPOSITORIES"  ]
      then
         log_setting "Setting ${C_MAGENTA}${name}${C_SETTING} found in \"${apath}\" as ${C_MAGENTA}${C_BOLD}${value}${C_SETTING}"
      else
         log_verbose "${C_SETTING}Setting ${C_MAGENTA}${name}${C_SETTING} found in \"${apath}\" as ${C_MAGENTA}${value}${C_SETTING}"
      fi
   fi

   echo "${value}"
}


read_setting()
{
   _read_setting "$@"
}


#
# this has to be flexible, because fetch and build settings read differently
#
_read_bootstrap_setting()
{
   local name

   name="$1"

   [ $# -ne 1 ]     && internal_fail "parameterization error"
   [ -z "${name}" ] && internal_fail "empty name in _read_bootstrap_setting"

   local value
   local suffix

   #
   # to access unmerged data (needed for embedded repos)
   #
   if [ "${MULLE_BOOTSTRAP_SETTINGS_NO_AUTO}" = "YES" ]
   then
      suffix=""
   else
      suffix=".auto"
   fi

   value="`_read_setting "${BOOTSTRAP_DIR}${suffix}/${name}" "${name}"`"
   if [ $? -ne 0 ]
   then
      return 2
   fi

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

   [ -z "$name" ] && internal_fail "empty name in _read_environment_setting"

   envname="MULLE_BOOTSTRAP_`echo "${name}" | tr '[:lower:]' '[:upper:]'`"

   if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" ]
   then
      log_trace2 "Looking for setting \"${name}\" as environment variable \"${envname}\""
   fi

   value="`printenv "${envname}"`"
   if [ "${value}" = "" ]
   then
      return 2
   fi

   if [ "${MULLE_BOOTSTRAP_TRACE_SETTINGS}" = "YES" ]
   then
      log_trace "Setting ${C_MAGENTA}${C_BOLD}${name}${C_TRACE} found in environment variable \"${envname}\" as ${C_MAGENTA}${C_BOLD}${value}${C_TRACE}"
   fi

   warn_environment_setting "${envname}"

   echo "${value}"
   return 0
}


_read_home_setting()
{
   local name
   local value
   local default

   [ $# -ne 1  ] && internal_fail "parameterization error"

   name="$1"

   [ -z "$name" ] && internal_fail "empty name in _read_home_setting"

   if [ "${MULLE_BOOTSTRAP_TRACE_SETTINGS}" = "YES" ]
   then
      log_trace2 "Looking for setting \"${name}\" in \"~/.mulle-bootstrap\""
   fi

   value="`_read_setting "${HOME}/.mulle-bootstrap/${name}" "${name}"`"
   if [ $? -ne 0 ]
   then
      return 2
   fi

   if [ "${MULLE_BOOTSTRAP_TRACE_SETTINGS}" = "YES" ]
   then
      log_trace "Setting ${C_MAGENTA}${C_BOLD}${name}${C_TRACE} found in \"~/.mulle-bootstrap\" as ${C_MAGENTA}${C_BOLD}${value}${C_TRACE}"
   fi
   warn_user_setting "${HOME}/.mulle-bootstrap/${name}"

   echo "$value"
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

   [ -z "$name" ] && internal_fail "empty name in read_config_setting"

   #
   # always lowercase config names
   #
   name=`echo "${name}" | tr '[:lower:]' '[:upper:]'`

   local value

   value="`_read_environment_setting "${name}"`"
   if [ $? -ne 0 ]
   then
      value="`_read_setting "${BOOTSTRAP_DIR}.local/config/${name}" "${name}"`"
      if [ $? -ne 0 ]
      then
         value="`_read_home_setting "${name}"`"
         if [ $? -ne 0 ]
         then
            if [ ! -z "${default}" ]
            then
               log_setting "Setting ${C_MAGENTA}${name}${C_SETTING} set to default ${C_MAGENTA}${default}${C_SETTING}"
            fi
            value="${default}"
         fi
      fi
   fi

   echo "$value"

   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set -x
   fi
}


#
# values in "overrides" override those inherited by repositories
# values in "settings" are overriden by those inherited by repositories
#
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

   [ -z "$name" ] && internal_fail "empty parameter in read_config_setting"

   local value

   value="`_read_bootstrap_setting "${package}.build/${name}"`"
   if [ $? -ne 0 ]
   then
      if [ ! -z "${default}" ]
      then
         log_setting "Build Setting ${C_MAGENTA}${package}${C_SETTING} for ${C_MAGENTA}${C_BOLD}${name}${C_VERBOSE} set to default ${C_MAGENTA}${default}${C_SETTING}"
      fi
      value="${default}"
   fi

   echo "$value"

   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set -x
   fi
#   [ "${value}" = "${default}" ]
#
#   return $?
}


read_root_setting()
{
   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set +x
   fi

   local default
   local name

   name="$1"
   default="$2"

   [ -z "$name" ] && internal_fail "empty name in read_root_setting"

   local value
   local rval

   value="`_read_bootstrap_setting "${name}"`"
   if [ $? -ne 0 ]
   then
      if [ ! -z "${default}" ]
      then
         log_setting "Root setting for ${C_MAGENTA}${name}${C_SETTING} set to default ${C_MAGENTA}${default}${C_SETTING}"
      fi
      value="${default}"
   fi

   echo "$value"

   if [ "${MULLE_BOOTSTRAP_SETTINGS_FLIP_X}" = "YES" ]
   then
      set -x
   fi
#   [ "${value}" = "${default}" ]
#
#   return $?
}



####
# Used for finding script files
#
find_root_setting_file()
{
   READ_SETTING_RETURNS_PATH="YES" read_root_setting "$@"
}


find_build_setting_file()
{
   READ_SETTING_RETURNS_PATH="YES" read_build_setting "$@"
}


####
# Functions building on read_ functions
#
read_yes_no_build_setting()
{
   local value

   value="`read_build_setting "$1" "$2" "$3"`"
   is_yes "$value" "$1/$2"
}


read_yes_no_config_setting()
{
   local value

   value="`read_config_setting "$1" "$2"`"
   is_yes "$value" "$1"
}


read_sane_config_path_setting()
{
   local name
   local value
   local default

   name="$1"
   default="$2"

   value="`read_config_setting "${name}" "${default}"`"
   if [ $? -eq 0 ]
   then
      assert_sane_subdir_path "${value}"
      echo "$value"
   fi
}


merge_settings_in_front()
{
   local settings1
   local settings2
   local result
   local name

   name="`basename -- "$1"`"
   settings1="`_read_setting "$1" "${name}"`"
   settings2="`_read_setting "$2" "${name}"`"

   result="${settings2}"

   local line

   # https://stackoverflow.com/questions/742466/how-can-i-reverse-the-order-of-lines-in-a-file/744093#744093

   IFS="
"
   for line in `echo "${settings1}" | sed -n '1!G;h;$p'`
   do
      result="`echo "${result}" | grep -v -x "${line}"`"
      result="${line}
${result}"
   done

   IFS="${DEFAULT_IFS}"

   if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" -o "$MULLE_BOOTSTRAP_TRACE_MERGE" = "YES"  ]
   then
      log_trace2 "----------------------"
      log_trace2 "Merged settings: $1, $2"
      log_trace2 "----------------------"
      log_trace2 "${result}"
      log_trace2 "----------------------"
   fi
   echo "${result}"
}


###
#
#

all_build_flag_keys()
{
   local package

   package="$1"

   local keys1
   local keys2

   keys1=`(cd "${BOOTSTRAP_DIR}.auto/overrides" 2> /dev/null || exit 1 ; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys2=`(cd "${BOOTSTRAP_DIR}.auto/${package}.build" 2> /dev/null || exit 1 ; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys3=`(cd "${BOOTSTRAP_DIR}.auto/settings" 2> /dev/null || exit 1 ; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`

   echo "${keys1}
${keys2}
${keys3}
" | sort | sort -u | egrep -v '^[ ]*$'
   return 0
}

#
# "config" interface sorta like git config
# obviously need to "vet" the keys sometime
#
config_read()
{
   read_config_setting "$1"
}


config_write()
{
   mkdir_if_missing "${BOOTSTRAP_DIR}.local/config"
   exekutor echo "$2" > "${BOOTSTRAP_DIR}.local/config/$1"
}


config_delete()
{
   if [ -f "${BOOTSTRAP_DIR}.local/config/$1" ]
   then
      exekutor rm "${BOOTSTRAP_DIR}.local/config/$1"
   fi
}


config_main()
{
   local name
   local value
   local command

   command="read"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            config_usage
         ;;

         -d)
            command="delete"
         ;;

         -n|--off|--no|--NO)
            command="write"
            value=
         ;;

         -y|--on|--yes|--YES)
            command="write"
            value="YES"
         ;;

         -*)
            log_error "${MULLE_BOOTSTRAP_FAIL_PREFIX}: Unknown option $1"
            config_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   name="$1"
   [ $# -ne 0 ] && shift

   if [ -z "${name}" ]
   then
      config_usage
   fi

   if [ $# -ne 0 ]
   then
      [ "${command}" != "read" ] && config_usage

      command="write"
      value="$1"
      shift
   fi

   case "${command}" in
      read)
         value="`config_read "${name}"`"
         if [ -z "${value}" ]
         then
            value="`eval echo "$"${name}`"
         fi
         if [ ! -z "${value}" ]
         then
            echo "${value}"
         fi
      ;;

      delete)
         config_delete "${name}"
         create_file_if_missing "${REPOS_DIR}/.bootstrap_fetch_needed"
      ;;

      write)
         config_write "${name}" "${value}"
         create_file_if_missing "${REPOS_DIR}/.bootstrap_fetch_needed"
      ;;
   esac
}



setting_main()
{
   local name
   local value
   local command
   local repository

   command="read"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            config_usage
         ;;

         -r|--repository)
            shift
            [ $# -ne 0 ] || fail "repository name missing"
            repository="$1"
         ;;

         -*)
            log_error "${MULLE_BOOTSTRAP_FAIL_PREFIX}: Unknown option $1"
            config_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   name="$1"
   [ $# -ne 0 ] && shift

   if [ -z "${name}" -o $# -ne 0 ]
   then
      setting_usage
   fi

   case "${command}" in
      read)
         if [ -z "${repository}" ]
         then
            value="`read_root_setting "$name"`"
         else
            value="`read_build_setting "${repository}" "$name"`"
         fi

         if [ -z "${value}" ]
         then
            value="`eval echo "$"${name}`"
         fi

         if [ ! -z "${value}" ]
         then
            echo "${value}"
         fi
      ;;
   esac
}


# read some config stuff now

settings_initialize()
{
   log_fluff ":settings_initialize:"

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh

   MULLE_BOOTSTRAP_NO_WARN_LOCAL_SETTINGS="`read_config_setting "no_warn_local_setting"`"
   MULLE_BOOTSTRAP_NO_WARN_USER_SETTINGS="`read_config_setting "no_warn_user_setting"`"
   MULLE_BOOTSTRAP_NO_WARN_ENVIRONMENT_SETTINGS="`read_config_setting "no_warn_environment_setting"`"
}

settings_initialize

