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
MULLE_BOOTSTRAP_PATHS_SH="included"

paths_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE} paths [options] <types>

Output paths for various tool types. You can specify multiple types.

Options:
   -1             : output is a one-liner
   -f             : emit link directives for Frameworks
   -l             : emit link directives for libraries
   -m             : emit regardless of directory existence
   -q <char>      : specify quote character
   -s <char>      : specify PATH seperator character

Types:
   addictions     : output "addictions" path
   binpath        : output paths for binaries
   cppflags       : output CPPFLAGS
   cmakeflags     : output cmake flag definitions
   cmakepaths     : output cmake paths definitions
EOF

   if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
   then
       cat <<EOF >&2
   dependencies   : output "dependencies" path
EOF
   fi

   cat <<EOF >&2
   environment*   : output CPPFLAGS, LDFLAGS (default)
   frameworkpath  : output framework search paths PATH style
   headerpath     : output framework search paths PATH style
   ldflags        : output LDFLAGS
   librarypath    : output library search paths PATH style
   path           : output PATH

EOF
  exit 1
}


__collect_libraries()
{
   local i
   local name

   for i in "$1/"*
   do
      name="`basename "$i"`"
      case "${name}" in
         lib*.a|lib*.lib)
            echo "${name}" | sed 's/\.[^.]*$//' | sed 's/^lib//'
         ;;
      esac
   done
}


__collect_frameworks()
{
   local i
   local name

   for i in "$1/"*
   do
      name="`basename "$i"`"
      case "${name}" in
         *.framework)
            basename "${name}" | sed 's/\.[^.]*$//'
         ;;
      esac
   done
}


_collect_libraries()
{
   if [ "${OPTION_WITH_DEPENDENCIES}" ]
   then
      __collect_libraries "${DEPENDENCIES_DIR}/lib"
   fi

   if [ "${OPTION_WITH_ADDICTIONS}" ]
   then
      __collect_libraries "${ADDICTIONS_DIR}/lib"
   fi
}


_collect_frameworks()
{
   if [ "${OPTION_WITH_DEPENDENCIES}" ]
   then
      __collect_frameworks "${DEPENDENCIES_DIR}/Frameworks"
   fi

   if [ "${OPTION_WITH_ADDICTIONS}" ]
   then
      __collect_frameworks "${ADDICTIONS_DIR}/Frameworks"
   fi
}


collect_libraries()
{
   _collect_libraries "$@" | sort | sort -u
}


collect_frameworks()
{
   _collect_frameworks "$@" | sort | sort -u
}


#
# Construct FLAGS paths
#
_flags_emit_path()
{
   local directory="$1"

   if [ "${OPTION_WITH_MISSING_PATHS}" = "YES" -o -d "${directory}" ]
   then
      if [ "${OPTION_USE_ABSOLUTE_PATHS}" = "YES" ]
      then
         directory="`absolutepath "${directory}"`"
      fi
      echo "${directory}"
   fi
}


_flags_binpath_value()
{
   local pathline
   local line

   pathline="`_flags_emit_path "${DEPENDENCIES_DIR}/bin"`"
   line="`_flags_emit_path "${ADDICTIONS_DIR}/bin"`"

   add_path "${pathline}" "${line}"
}


_flags_emit_option()
{
   local prefix="$1"
   local directory="$2"

   if [ "${OPTION_WITH_MISSING_PATHS}" = "YES" -o -d "${directory}" ]
   then
      if [ "${OPTION_USE_ABSOLUTE_PATHS}" = "YES" ]
      then
         directory="`absolutepath "${directory}"`"
      fi
      echo "${prefix}${OPTION_QUOTE}${directory}${OPTION_QUOTE}"
   fi
}


_flags_cppflags_value()
{
   if [ "${OPTION_WITH_HEADERPATHS}" = "YES" ]
   then
      if [ "${OPTION_WITH_DEPENDENCIES}" = "YES" ]
      then
         _flags_emit_option "-I" "${DEPENDENCIES_DIR}/include"
      fi
      if [ "${OPTION_WITH_ADDICTIONS}" = "YES" ]
      then
         _flags_emit_option "-I" "${ADDICTIONS_DIR}/include"
      fi
   fi

   if [ "${OPTION_WITH_FRAMEWORKPATHS}" = "YES" -a "${OPTION_SUPPRESS_FRAMEWORK_CFLAGS}" = "NO" ]
   then
      if [ "${OPTION_WITH_DEPENDENCIES}" = "YES" ]
      then
         _flags_emit_option "-F" "${DEPENDENCIES_DIR}/Frameworks"
      fi
      if [ "${OPTION_WITH_ADDICTIONS}" = "YES" ]
      then
         _flags_emit_option "-F" "${ADDICTIONS_DIR}/Frameworks"
      fi
   fi
}


_flags_ldflags_value()
{
   if [ "${OPTION_WITH_LIBRARYPATHS}" = "YES" ]
   then
      if [ "${OPTION_WITH_DEPENDENCIES}" = "YES" ]
      then
         _flags_emit_option "-L" "${DEPENDENCIES_DIR}/lib"
      fi
      if [ "${OPTION_WITH_ADDICTIONS}" = "YES" ]
      then
         _flags_emit_option "-L" "${ADDICTIONS_DIR}/lib"
      fi
   fi

   if [ "${OPTION_WITH_FRAMEWORKPATHS}" = "YES" -a "${OPTION_SUPPRESS_FRAMEWORK_LDFLAGS}" = "NO" ]
   then
      if [ "${OPTION_WITH_DEPENDENCIES}" = "YES" ]
      then
         _flags_emit_option "-F" "${DEPENDENCIES_DIR}/Frameworks"
      fi
      if [ "${OPTION_WITH_ADDICTIONS}" = "YES" ]
      then
         _flags_emit_option "-F" "${ADDICTIONS_DIR}/Frameworks"
      fi
   fi

   if [ "${OPTION_WITH_LIBRARIES}" = "YES" ]
   then
      local i

      IFS="
"
      for i in `collect_libraries`
      do
         IFS="${DEFAULT_IFS}"
         echo "${OPTION_QUOTE}-l$i${OPTION_QUOTE}"
      done
      IFS="${DEFAULT_IFS}"
   fi


   if [ "${OPTION_WITH_FRAMEWORKS}" = "YES" ]
   then
      local i

      IFS="
"
      for i in `collect_frameworks`
      do
         IFS="${DEFAULT_IFS}"
         echo "-framework ${OPTION_QUOTE}$i${OPTION_QUOTE}"
      done
      IFS="${DEFAULT_IFS}"
   fi
}


_flags_cflags_value()
{
   _flags_cppflags_value "$@"
   _flags_ldflags_value "$@"
}


#
# Construct search paths
#
_flags_add_search_path()
{
   local result="$1"
   local searchpath="$2"

   if [ "${OPTION_WITH_MISSING_PATHS}" = "YES" -o -d "${searchpath}" ]
   then
      if [ "${OPTION_USE_ABSOLUTE_PATHS}" = "YES" ]
      then
         searchpath="`absolutepath "${searchpath}"`"
      fi
      add_path "${result}" "${searchpath}"
   else
      echo "${result}"
   fi
}


_flags_frameworkpath_value()
{
   local result

   if [ "${OPTION_WITH_FRAMEWORKPATHS}" = "YES" ]
   then
      if [ "${OPTION_WITH_DEPENDENCIES}" = "YES" ]
      then
         result="`_flags_add_search_path "${result}" "${DEPENDENCIES_DIR}/Frameworks"`"
      fi
      if [ "${OPTION_WITH_ADDICTIONS}" = "YES" ]
      then
         result="`_flags_add_search_path "${result}" "${ADDICTIONS_DIR}/Frameworks"`"
      fi
   fi

   if [ ! -z "${result}" ]
   then
      echo "${result}"
   fi
}


_flags_headerpath_value()
{
   local result

   if [ "${OPTION_WITH_HEADERPATHS}" = "YES" ]
   then
      if [ "${OPTION_WITH_DEPENDENCIES}" = "YES" ]
      then
         result="`_flags_add_search_path "${result}" "${DEPENDENCIES_DIR}/include"`"
      fi
      if [ "${OPTION_WITH_ADDICTIONS}" = "YES" ]
      then
         result="`_flags_add_search_path "${result}" "${ADDICTIONS_DIR}/include"`"
      fi
   fi

   if [ ! -z "${result}" ]
   then
      echo "${result}"
   fi
}


_flags_librarypath_value()
{
   local result

   if [ "${OPTION_WITH_LIBRARYPATHS}" = "YES" ]
   then
      if [ "${OPTION_WITH_DEPENDENCIES}" = "YES" ]
      then
         if [ "${OPTION_WITH_MISSING_PATHS}" = "YES" -o -d "${DEPENDENCIES_DIR}/lib" ]
         then
            result="`_flags_add_search_path "${result}" "${DEPENDENCIES_DIR}/lib"`"
         fi
      fi
      if [ "${OPTION_WITH_ADDICTIONS}" = "YES" ]
      then
         result="`_flags_add_search_path "${result}" "${ADDICTIONS_DIR}/lib"`"
      fi
   fi

   if [ ! -z "${result}" ]
   then
      echo "${result}"
   fi
}


_flags_do_cmake_flags()
{
   local result="$1"

   local values
   local line

   values="`_flags_cppflags_value`"
   if [ ! -z "${values}" ]
   then
      values="`echo "${values}" | tr '\012' ' ' | sed 's/ *$//'`"
      line="-DCMAKE_C_FLAGS=\"${values}\""
      result="`add_line "${result}" "${line}"`"

      line="-DCMAKE_CXX_FLAGS=\"${values}\""
      result="`add_line "${result}" "${line}"`"
   fi

   values="`_flags_ldflags_value`"
   if [ ! -z "${values}" ]
   then
      values="`echo "${values}" | tr '\012' ' ' | sed 's/ *$//'`"
      line="-DCMAKE_EXE_LINKER_FLAGS=\"${values}\""
      result="`add_line "${result}" "${line}"`"

      line="-DCMAKE_SHARED_LINKER_FLAGS=\"${values}\""
      result="`add_line "${result}" "${line}"`"
   fi

   printf "%s" "$result"
}


_flags_do_cmake_paths()
{
   local result="$1"

   local values
   local line

   values="`_flags_headerpath_value`"
   if [ ! -z "${values}" ]
   then
      line="-DCMAKE_INCLUDE_PATH =\"${values}\""
      result="`add_line "${result}" "${line}"`"
   fi

   values="`_flags_librarypath_value`"
   if [ ! -z "${values}" ]
   then
      line="-DCMAKE_LIBRARY_PATH=\"${values}\""
      result="`add_line "${result}" "${line}"`"
   fi

   # does CMAKE_FRAMEWORK_PATH even exist ?
   values="`_flags_frameworkpath_value`"
   if [ ! -z "${values}" ]
   then
      line="-DCMAKE_FRAMEWORK_PATH=\"${values}\""
      result="`add_line "${result}" "${line}"`"
   fi

   printf "%s" "$result"
}



_flags_do_path()
{
   local result="$1"

   local values
   local line

   values="`_flags_binpath_value`"
   if [ ! -z "${values}" ]
   then
      line="PATH='${values}:${PATH}'"
      result="`add_line "${result}" "${line}"`"
   fi

   printf "%s" "$result"
}


_flags_do_environment()
{
   local result="$1"

   local values
   local line

   values="`_flags_cppflags_value`"
   if [ ! -z "${values}" ]
   then
      values="`echo "${values}" | tr '\012' ' ' | sed 's/ *$//'`"
      line="CPPFLAGS=\"${values}\""
      result="`add_line "${result}" "${line}"`"
   fi

   values="`_flags_ldflags_value`"
   if [ ! -z "${values}" ]
   then
      values="`echo "${values}" | tr '\012' ' ' | sed 's/ *$//'`"
      line="LDFLAGS=\"${values}\""
      result="`add_line "${result}" "${line}"`"
   fi

   printf "%s" "$result"
}


paths_main()
{
   local types

   # semi-local
   local OPTION_SUPPRESS_FRAMEWORK_CFLAGS="NO"
   local OPTION_SUPPRESS_FRAMEWORK_LDFLAGS="NO"
   local OPTION_USE_ABSOLUTE_PATHS="YES"
   local OPTION_WITH_ADDICTIONS="YES"
   local OPTION_WITH_DEPENDENCIES="NO"
   local OPTION_WITH_FRAMEWORKPATHS="NO"
   local OPTION_WITH_FRAMEWORKS="NO"
   local OPTION_WITH_HEADERPATHS="YES"
   local OPTION_WITH_LIBRARIES="NO"
   local OPTION_WITH_LIBRARYPATHS="YES"
   local OPTION_WITH_MISSING_PATHS="NO"
   local OPTION_PATH_SEPARATOR=":"
   local OPTION_QUOTE="'"
   local OPTION_LINE_SEPERATOR="\n"

   log_debug ":paths_main:"

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh

   OPTION_WITH_HEADERPATHS="YES"
   OPTION_WITH_LIBRARYPATHS="YES"
   OPTION_WITH_ADDICTIONS="YES"
   OPTION_USE_ABSOLUTE_PATHS="YES"

   case "${UNAME}" in
      darwin)
         OPTION_WITH_FRAMEWORKS="YES"
         OPTION_WITH_FRAMEWORKPATHS="YES"
      ;;
   esac

   if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      OPTION_WITH_DEPENDENCIES="YES"
   fi

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            paths_usage
         ;;

         -1|--one-line)
            OPTION_LINE_SEPERATOR=" "
         ;;

         -d|--dependencies)
            OPTION_WITH_DEPENDENCIES="YES"
         ;;

         -f|--frameworks)
            OPTION_WITH_FRAMEWORKS="YES"
            OPTION_WITH_FRAMEWORKPATHS="YES"
         ;;

         -l|--libraries)
            OPTION_WITH_LIBRARYPATHS="YES"
            OPTION_WITH_LIBRARIES="YES"
         ;;

         -m|--missing)
            OPTION_WITH_MISSING_PATHS="YES"
         ;;

         -na|--no-addictions)
            OPTION_WITH_ADDICTIONS="NO"
         ;;

         -nc|-no-cflags-frameworks)
            OPTION_SUPPRESS_FRAMEWORK_CFLAGS="YES"
         ;;

         -nd|-no-ldflags-frameworks)
            OPTION_SUPPRESS_FRAMEWORK_LDFLAGS="YES"
         ;;

         -nf|--no-framework-paths)
            OPTION_WITH_FRAMEWORKPATHS="NO"
         ;;

         -nh|--no-header-paths)
            OPTION_WITH_HEADERPATHS="NO"
         ;;

         -nl|--no-library-paths)
            OPTION_WITH_LIBRARYPATHS="NO"
         ;;

         -q|--quote)
            shift
            [ $# -eq 0 ] && fail "quote missing"

            OPTION_QUOTE="$1"
         ;;

         -s|--separator)
            shift
            [ $# -eq 0 ] && fail "separator missing"

            OPTION_PATH_SEPARATOR="$1"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown option $1"
            paths_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   [ -z "${DEPENDENCIES_DIR}" ] && internal_fail "missing DEPENDENCIES_DIR"
   [ -z "${ADDICTIONS_DIR}" ]   && internal_fail "missing ADDICTIONS_DIR"

   local type
   local values
   local result

   result=""
   type="${1:-environment}"


   local memo

   # hacque
   PATH_SEPARATOR="${OPTION_PATH_SEPARATOR}"

   while [ ! -z "${type}" ]
   do
      [ $# -ne 0 ] && shift

      case "${type}" in
         addictions)
            values="`_flags_emit_path "${ADDICTIONS_DIR}"`"
            result="`add_line "${result}" "${values}"`"
         ;;

         dependencies)
            values="`_flags_emit_path "${DEPENDENCIES_DIR}"`"
            result="`add_line "${result}" "${values}"`"
         ;;

         "cflags"|"cppflags"|"ldflags"|"binpath"|"frameworkpath"|"headerpath"|"librarypath")
            values="`_flags_${type}_value`"
            result="`add_line "${result}" "${values}"`"
         ;;

         "cmakeflags")
            result="`_flags_do_cmake_flags "${result}"`"
         ;;

         "cmakepaths")
            result="`_flags_do_cmake_paths "${result}"`"
         ;;

         "path")
            result="`_flags_do_path "${result}"`"
         ;;

         "environment")
            result="`_flags_do_environment "${result}"`"
         ;;

         *)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown type \"$type\""
            paths_usage
         ;;
      esac

      type="$1"
   done

   if [ ! -z "${result}" ]
   then
      if [ "${OPTION_LINE_SEPERATOR}" = " " ]
      then
         printf "%s" "${result}" | tr '\012' ' '  | sed 's/ *$//'
         printf "\n"
      else
         printf "%s\n" "${result}"
      fi
   fi
}
