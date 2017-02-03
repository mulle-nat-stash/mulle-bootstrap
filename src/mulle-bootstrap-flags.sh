#! /bin/sh
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
MULLE_BOOTSTRAP_FLAGS_SH="included"

flags_usage()
{
    cat <<EOF >&2
usage:
   mulle-bootstrap flags [options] <type>

   Options:
      -1             : output is a one-liner
      -a             : emit options, regardless of directory existence
      -c             : suppress -F output for cflags
      -l             : emit link directives for libraries
      -f             : emit link directives for Frameworks

   Output flags for various tool types. You can specify multiple types.

   Types:
      cflags         : output CFLAGS for gcc, clang and friends
      cxxflags       : output CXXFLAGS
      ldflags        : output LDFLAGS
      environment*   : output CFLAGS, CXXFLAGS, LDFLAGS (default)
      frameworkpath  : output framework search paths PATH style
      headerpath     : output framework search paths PATH style
      librarypath    : output library search paths PATH style
EOF
  exit 1
}


__collect_libraries()
{
   local i

   for i in "$1/"*
   do
      case "$i" in
         *.a|*.so|*.dylib|*.lib)
            echo "$i" | 's/\.[^.]*$//'
         ;;
      esac
   done
}


__collect_frameworks()
{
   local i

   for i in "$1/"*
   do
      case "$i" in
         *.framework)
            echo "$i" | 's/\.[^.]*$//'
         ;;
      esac
   done
}


_collect_libraries()
{
   local withheaderpaths="$1"
   local withlibrarypaths="$2"
   local withframeworkpaths="$3"
   local withlibraries="$4"
   local withframeworks="$5"
   local withaddictions="$6"
   local withdependencies="$7"
   local FUTURE="$8"

   if [ "${withdependencies}" ]
   then
      __collect_libraries "${DEPENDENCIES_DIR}/lib"
   fi

   if [ "${withaddictions}" ]
   then
      __collect_libraries "${ADDICTIONS_DIR}/lib"
   fi
}


_collect_frameworks()
{
   local withheaderpaths="$1"
   local withlibrarypaths="$2"
   local withframeworkpaths="$3"
   local withlibraries="$4"
   local withframeworks="$5"
   local withaddictions="$6"
   local withdependencies="$7"
   local FUTURE="$8"

   if [ "${withdependencies}" ]
   then
      __collect_frameworks "${DEPENDENCIES_DIR}/Frameworks"
   fi

   if [ "${withaddictions}" ]
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

_flags_emit_option()
{
   local prefix="$1"
   local directory="$2"

   if [ "${FUTURE}" = "YES" -o -d "${directory}" ]
   then
      if [ "${ABSOLUTE_PATHS}" = "YES" ]
      then
         directory="`absolutepath "${directory}"`"
      fi
      echo "${prefix}'${directory}'"
   fi
}


_flags_cflags_value()
{
   local withheaderpaths="$1"
   local withlibrarypaths="$2"
   local withframeworkpaths="$3"
   local withlibraries="$4"
   local withframeworks="$5"
   local withaddictions="$6"
   local withdependencies="$7"

   if [ "${withheaderpaths}" = "YES" ]
   then
      if [ "${withdependencies}" = "YES" ]
      then
         _flags_emit_option "-I" "${DEPENDENCIES_DIR}/include"
      fi
      if [ "${withaddictions}" = "YES" ]
      then
         _flags_emit_option "-I" "${ADDICTIONS_DIR}/include"
      fi
   fi

   if [ "${withframeworkpaths}" = "YES" -a -z "${COMBINE}" ]
   then
      if [ "${withdependencies}" = "YES" ]
      then
         _flags_emit_option "-F" "${DEPENDENCIES_DIR}/Frameworks"
      fi
      if [ "${withaddictions}" = "YES" ]
      then
         _flags_emit_option "-F" "${ADDICTIONS_DIR}/Frameworks"
      fi
   fi
}


_flags_cxxflags_value()
{
   _flags_cflags_value "$@"
}


_flags_ldflags_value()
{
   local withheaderpaths="$1"
   local withlibrarypaths="$2"
   local withframeworkpaths="$3"
   local withlibraries="$4"
   local withframeworks="$5"
   local withaddictions="$6"
   local withdependencies="$7"

   if [ "${withlibrarypaths}" = "YES" ]
   then
      if [ "${withdependencies}" = "YES" ]
      then
         _flags_emit_option "-L" "${DEPENDENCIES_DIR}/lib"
      fi
      if [ "${withaddictions}" = "YES" ]
      then
         _flags_emit_option "-L" "${ADDICTIONS_DIR}/lib"
      fi
   fi

   if [ "${withframeworkpaths}" = "YES" ]
   then
      if [ "${withdependencies}" = "YES" ]
      then
         _flags_emit_option "-F" "${DEPENDENCIES_DIR}/Frameworks"
      fi
      if [ "${withaddictions}" = "YES" ]
      then
         _flags_emit_option "-F" "${ADDICTIONS_DIR}/Frameworks"
      fi
   fi

   if [ "${withlibraries}" = "YES" ]
   then
      local i

      IFS="
"
      for i in `collect_libraries`
      do
         IFS="${DEFAULT_IFS}"
         echo "'-l$i'"
      done
      IFS="${DEFAULT_IFS}"
   fi


   if [ "${withframeworks}" = "YES" ]
   then
      local i

      IFS="
"
      for i in `collect_frameworks`
      do
         IFS="${DEFAULT_IFS}"
         echo "-framework '$i'"
      done
      IFS="${DEFAULT_IFS}"
   fi
}


#
# Construct search paths
#
_flags_add_search_path()
{
   local result="$1"
   local searchpath="$2"

   if [ "${FUTURE}" = "YES" -o -d "${searchpath}" ]
   then
      if [ "${ABSOLUTE_PATHS}" = "YES" ]
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
   local withheaderpaths="$1"
   local withlibrarypaths="$2"
   local withframeworkpaths="$3"
   local withlibraries="$4"
   local withframeworks="$5"
   local withaddictions="$6"
   local withdependencies="$7"

   local result

   if [ "${withframeworkpaths}" = "YES" ]
   then
      if [ "${withdependencies}" = "YES" ]
      then
         result="`_flags_add_search_path "${result}" "${DEPENDENCIES_DIR}/Frameworks"`"
      fi
      if [ "${withaddictions}" = "YES" ]
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
   local withheaderpaths="$1"
   local withlibrarypaths="$2"
   local withframeworkpaths="$3"
   local withlibraries="$4"
   local withframeworks="$5"
   local withaddictions="$6"
   local withdependencies="$7"

   local result

   if [ "${withheaderpaths}" = "YES" ]
   then
      if [ "${withdependencies}" = "YES" ]
      then
         result="`_flags_add_search_path "${result}" "${DEPENDENCIES_DIR}/include"`"
      fi
      if [ "${withaddictions}" = "YES" ]
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
   local withheaderpaths="$1"
   local withlibrarypaths="$2"
   local withframeworkpaths="$3"
   local withlibraries="$4"
   local withframeworks="$5"
   local withaddictions="$6"
   local withdependencies="$7"

   if [ "${withlibrarypaths}" = "YES" ]
   then
      if [ "${withdependencies}" = "YES" ]
      then
         if [ "${FUTURE}" = "YES" -o -d "${DEPENDENCIES_DIR}/lib" ]
         then
            result="`_flags_add_search_path "${result}" "${DEPENDENCIES_DIR}/lib"`"
         fi
      fi
      if [ "${withaddictions}" = "YES" ]
      then
         result="`_flags_add_search_path "${result}" "${ADDICTIONS_DIR}/lib"`"
      fi
   fi

   if [ ! -z "${result}" ]
   then
      echo "${result}"
   fi
}


flags_main()
{
   local types
   local separator
   local withheaderpaths
   local withlibrarypaths
   local withframeworkpaths
   local withlibraries
   local withframeworks
   local withaddictions
   local withdependencies
   local FUTURE
   local COMBINE
   local ABSOLUTE_PATHS

   log_fluff ":flags_main:"

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh

   withheaderpaths="YES"
   withlibrarypaths="YES"
   withaddictions="YES"
   ABSOLUTE_PATHS="YES"

   case "${UNAME}" in
      darwin)
         withframeworks="YES"
         withframeworkpaths="YES"
      ;;
   esac

   if [ "${MULLE_BOOTSTRAP_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      withdependencies="YES"
   fi

   separator="\n"
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            flags_usage
         ;;

         -1|--one-line)
            separator=" "
         ;;

         -c|--COMBINE)
            COMBINE="YES"
         ;;

         -d|--dependencies)
            withdependencies="YES"
         ;;

         -f|--frameworks)
            withframeworks="YES"
            withframeworkpaths="YES"
         ;;

         -l|--libraries)
            withlibrarypaths="YES"
            withlibraries="YES"
         ;;

         -m|--missing)
            FUTURE="YES"
         ;;

         -r|--relative-paths)
            ABSOLUTE_PATHS="NO"
         ;;

         -na|--no-addictions)
            withaddictions="NO"
         ;;

         -nh|--no-header-paths)
            withheaderpaths="NO"
         ;;

         -nl|--no-library-paths)
            withlibrarypaths="NO"
         ;;

         -nf|--no-framework-paths)
            withframeworkpaths="NO"
         ;;

         -*)
            log_error "${MULLE_BOOTSTRAP_FAIL_PREFIX}: Unknown config option $1"
            flags_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh

   build_complete_environment

   local type
   local values
   local result

   result=""
   type="${1:-environment}"

   while [ ! -z "${type}" ]
   do
      [ $# -ne 0 ] && shift

      case "${type}" in
         "cflags"|"cxxflags"|"ldflags"|"frameworkpath"|"headerpath"|"librarypath")
            values="`_flags_${type}_value "${withheaderpaths}"  \
                                          "${withlibrarypaths}" \
                                          "${withframeworkpaths}" \
                                          "${withlibraries}"   \
                                          "${withframeworks}"  \
                                          "${withaddictions}" \
                                          "${withdependencies}"`"
            result="`add_line "${result}" "${values}"`"
         ;;


         "environment")
            values="`_flags_cflags_value "${withheaderpaths}"  \
                                         "${withlibrarypaths}" \
                                         "${withframeworkpaths}" \
                                         "${withlibraries}"   \
                                         "${withframeworks}"  \
                                         "${withaddictions}" \
                                         "${withdependencies}"`"
            values="`echo "${values}" | tr '\012' ' '`"
            result="`add_line "${result}" "CFLAGS='${values}'"`"

            values="`_flags_cxxflags_value "${withheaderpaths}"  \
                                           "${withlibrarypaths}" \
                                           "${withframeworkpaths}" \
                                           "${withlibraries}"   \
                                           "${withframeworks}"  \
                                           "${withaddictions}" \
                                           "${withdependencies}"`"
            values="`echo "${values}" | tr '\012' ' '`"
            result="`add_line "${result}" "CXXFLAGS='${values}'"`"

            values="`_flags_ldflags_value "${withheaderpaths}"  \
                                          "${withlibrarypaths}" \
                                          "${withframeworkpaths}" \
                                          "${withlibraries}"   \
                                          "${withframeworks}"  \
                                          "${withaddictions}" \
                                          "${withdependencies}"`"
            values="`echo "${values}" | tr '\012' ' '`"
            result="`add_line "${result}" "LDFLAGS='${values}'"`"
         ;;

         *)
            log_error "${MULLE_BOOTSTRAP_FAIL_PREFIX}: Unknown type \"$type\""
            flags_usage
         ;;
      esac

      type="$1"
   done

   if [ ! -z "${result}" ]
   then
      if [ "${separator}" = " " ]
      then
         echo "${result}" | tr '\012' ' '
         echo ""
      else
         echo "${result}"
      fi
   fi
}

