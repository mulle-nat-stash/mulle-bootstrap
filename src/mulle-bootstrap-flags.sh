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
      -m             : emit regardless of directory existence
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
   if [ "${WITH_DEPENDENCIES}" ]
   then
      __collect_libraries "${DEPENDENCIES_DIR}/lib"
   fi

   if [ "${WITH_ADDICTIONS}" ]
   then
      __collect_libraries "${ADDICTIONS_DIR}/lib"
   fi
}


_collect_frameworks()
{
   if [ "${WITH_DEPENDENCIES}" ]
   then
      __collect_frameworks "${DEPENDENCIES_DIR}/Frameworks"
   fi

   if [ "${WITH_ADDICTIONS}" ]
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
   if [ "${WITH_HEADERPATHS}" = "YES" ]
   then
      if [ "${WITH_DEPENDENCIES}" = "YES" ]
      then
         _flags_emit_option "-I" "${DEPENDENCIES_DIR}/include"
      fi
      if [ "${WITH_ADDICTIONS}" = "YES" ]
      then
         _flags_emit_option "-I" "${ADDICTIONS_DIR}/include"
      fi
   fi

   if [ "${WITH_FRAMEWORKPATHS}" = "YES" -a -z "${COMBINE}" ]
   then
      if [ "${WITH_DEPENDENCIES}" = "YES" ]
      then
         _flags_emit_option "-F" "${DEPENDENCIES_DIR}/Frameworks"
      fi
      if [ "${WITH_ADDICTIONS}" = "YES" ]
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
   if [ "${WITH_LIBRARYPATHS}" = "YES" ]
   then
      if [ "${WITH_DEPENDENCIES}" = "YES" ]
      then
         _flags_emit_option "-L" "${DEPENDENCIES_DIR}/lib"
      fi
      if [ "${WITH_ADDICTIONS}" = "YES" ]
      then
         _flags_emit_option "-L" "${ADDICTIONS_DIR}/lib"
      fi
   fi

   if [ "${WITH_FRAMEWORKPATHS}" = "YES" ]
   then
      if [ "${WITH_DEPENDENCIES}" = "YES" ]
      then
         _flags_emit_option "-F" "${DEPENDENCIES_DIR}/Frameworks"
      fi
      if [ "${WITH_ADDICTIONS}" = "YES" ]
      then
         _flags_emit_option "-F" "${ADDICTIONS_DIR}/Frameworks"
      fi
   fi

   if [ "${WITH_LIBRARIES}" = "YES" ]
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


   if [ "${WITH_FRAMEWORKS}" = "YES" ]
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
   local result

   if [ "${WITH_FRAMEWORKPATHS}" = "YES" ]
   then
      if [ "${WITH_DEPENDENCIES}" = "YES" ]
      then
         result="`_flags_add_search_path "${result}" "${DEPENDENCIES_DIR}/Frameworks"`"
      fi
      if [ "${WITH_ADDICTIONS}" = "YES" ]
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

   if [ "${WITH_HEADERPATHS}" = "YES" ]
   then
      if [ "${WITH_DEPENDENCIES}" = "YES" ]
      then
         result="`_flags_add_search_path "${result}" "${DEPENDENCIES_DIR}/include"`"
      fi
      if [ "${WITH_ADDICTIONS}" = "YES" ]
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
   if [ "${WITH_LIBRARYPATHS}" = "YES" ]
   then
      if [ "${WITH_DEPENDENCIES}" = "YES" ]
      then
         if [ "${FUTURE}" = "YES" -o -d "${DEPENDENCIES_DIR}/lib" ]
         then
            result="`_flags_add_search_path "${result}" "${DEPENDENCIES_DIR}/lib"`"
         fi
      fi
      if [ "${WITH_ADDICTIONS}" = "YES" ]
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

   # semi-local
   local WITH_HEADERPATHS
   local WITH_LIBRARYPATHS
   local WITH_FRAMEWORKPATHS
   local WITH_LIBRARIES
   local WITH_FRAMEWORKS
   local WITH_ADDICTIONS
   local WITH_DEPENDENCIES
   local FUTURE
   local COMBINE
   local ABSOLUTE_PATHS

   log_fluff ":flags_main:"

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh

   WITH_HEADERPATHS="YES"
   WITH_LIBRARYPATHS="YES"
   WITH_ADDICTIONS="YES"
   ABSOLUTE_PATHS="YES"

   case "${UNAME}" in
      darwin)
         WITH_FRAMEWORKS="YES"
         WITH_FRAMEWORKPATHS="YES"
      ;;
   esac

   if [ "${MULLE_BOOTSTRAP_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      WITH_DEPENDENCIES="YES"
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
            WITH_DEPENDENCIES="YES"
         ;;

         -f|--frameworks)
            WITH_FRAMEWORKS="YES"
            WITH_FRAMEWORKPATHS="YES"
         ;;

         -l|--libraries)
            WITH_LIBRARYPATHS="YES"
            WITH_LIBRARIES="YES"
         ;;

         -m|--missing)
            FUTURE="YES"
         ;;

         -na|--no-addictions)
            WITH_ADDICTIONS=
         ;;

         -nh|--no-header-paths)
            WITH_HEADERPATHS=
         ;;

         -nl|--no-library-paths)
            WITH_LIBRARYPATHS=
         ;;

         -nf|--no-framework-paths)
            WITH_FRAMEWORKPATHS=
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown option $1"
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
            values="`_flags_${type}_value "${WITH_HEADERPATHS}"  \
                                          "${WITH_LIBRARYPATHS}" \
                                          "${WITH_FRAMEWORKPATHS}" \
                                          "${WITH_LIBRARIES}"   \
                                          "${WITH_FRAMEWORKS}"  \
                                          "${WITH_ADDICTIONS}" \
                                          "${WITH_DEPENDENCIES}"`"
            result="`add_line "${result}" "${values}"`"
         ;;


         "environment")
            values="`_flags_cflags_value "${WITH_HEADERPATHS}"  \
                                         "${WITH_LIBRARYPATHS}" \
                                         "${WITH_FRAMEWORKPATHS}" \
                                         "${WITH_LIBRARIES}"   \
                                         "${WITH_FRAMEWORKS}"  \
                                         "${WITH_ADDICTIONS}" \
                                         "${WITH_DEPENDENCIES}"`"
            if [ ! -z "${values}" ]
            then
               values="`echo "${values}" | tr '\012' ' ' | sed 's/ *$//'`"
               result="`add_line "${result}" "CFLAGS='${values}'"`"
            fi

            values="`_flags_cxxflags_value "${WITH_HEADERPATHS}"  \
                                           "${WITH_LIBRARYPATHS}" \
                                           "${WITH_FRAMEWORKPATHS}" \
                                           "${WITH_LIBRARIES}"   \
                                           "${WITH_FRAMEWORKS}"  \
                                           "${WITH_ADDICTIONS}" \
                                           "${WITH_DEPENDENCIES}"`"
            if [ ! -z "${values}" ]
            then
               values="`echo "${values}" | tr '\012' ' ' | sed 's/ *$//'`"
               result="`add_line "${result}" "CXXFLAGS='${values}'"`"
            fi

            values="`_flags_ldflags_value "${WITH_HEADERPATHS}"  \
                                          "${WITH_LIBRARYPATHS}" \
                                          "${WITH_FRAMEWORKPATHS}" \
                                          "${WITH_LIBRARIES}"   \
                                          "${WITH_FRAMEWORKS}"  \
                                          "${WITH_ADDICTIONS}" \
                                          "${WITH_DEPENDENCIES}"`"
            if [ ! -z "${values}" ]
            then
               values="`echo "${values}" | tr '\012' ' ' | sed 's/ *$//'`"
               result="`add_line "${result}" "LDFLAGS='${values}'"`"
            fi
         ;;

         *)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown type \"$type\""
            flags_usage
         ;;
      esac

      type="$1"
   done

   if [ ! -z "${result}" ]
   then
      if [ "${separator}" = " " ]
      then
         echo "${result}" | tr '\012' ' '  | sed 's/ *$//'
         echo ""
      else
         echo "${result}"
      fi
   fi
}

