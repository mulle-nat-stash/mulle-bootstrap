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
#
MULLE_BOOTSTRAP_XCODE_SH="included"

# this script patches the xcodeproj so that the headers and
# lib files can be added in a sensible order
#

xcode_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE} xcode <command> [xcodeproj]

Commands:
   add      : add settings to Xcode project (default)
   remove   : remove settings from Xcode project

EOF
   exit 1
}


list_configurations()
{
   local project

   project="$1"
   #
   # Figure out all configurations
   #
   xcodebuild -list -project "${project}" 2> /dev/null | \
   grep -A100 'Build Configurations' | \
   grep -B100 'Schemes' | \
   egrep -v 'Configurations:|Schemes:' | \
   grep -v 'If no build' | \
   sed 's/^[ \t]*\(.*\)/\1/' | \
   sed '/^$/d'
}


#
# Figure out default configuration
#
list_default_configuration()
{
   xcodebuild -list 2> /dev/null | grep 'If no build configuration' | sed 's/^.*\"\(.*\)\".*$/\1/g'
}


check_for_mulle_xcode_settings()
{
   #
   # OK
   #
   if [ -z "`command -v mulle-xcode-settings`" ]
   then
      user_say_yes "Need to install mulle-xcode-settings (via brew)
Install mulle-xcode-settings now ?"
      [ $? -eq 0 ] || return 1

      [ -z "${MULLE_BOOTSTRAP_BREW_SH}" ] && . mulle-bootstrap-brew.sh

      brew_install_brews install "mulle-kybernetik/software/mulle-xcode-settings"
   fi
   return 0
}


map_configuration()
{
   local xcode_configuration
   local configurations
   local default

   configurations="$1"
   xcode_configuration="$2"
   default="$3"

   local mapped
   local i

   mapped=""

   IFS="
"
   for i in ${configurations}
   do
      if [ "$i" = "$xcode_configuration" ]
      then
         mapped="${xcode_configuration}"
      fi
   done
   IFS="${DEFAULT_IFS}"

   if [ "$mapped" = "" ]
   then
   case i in
      *ebug*)
         mapped="Debug"
         ;;
      *rofile*)
         mapped="Release"
         ;;
      *eleas*)
         mapped="Release"
         ;;
      *)
         mapped="${default}"
         ;;
   esac
   fi
   echo "${mapped}"
}


patch_library_configurations()
{
   local xcode_configurations
   local configurations
   local i
   local mapped
   local default

   xcode_configurations="$1"
   configurations="$2"
   project="$3"
   default="$4"
   flag="$5"

   if ! check_for_mulle_xcode_settings
   then
      exit 1
   fi

   IFS="
"
   for i in ${xcode_configurations}
   do
      IFS="${DEFAULT_IFS}"

      mapped=`map_configuration "${configurations}" "${i}" "${default}"`
      exekutor mulle-xcode-settings -configuration "${i}" "${flag}" "LIBRARY_CONFIGURATION" "${mapped}" "${project}" || exit 1
   done
   IFS="${DEFAULT_IFS}"
}


patch_xcode_project()
{
   local name
   local project
   local mapped
   local configurations
   local xcode_configurations
   local terse

   read_yes_no_config_setting "terse" "NO"
   terse=$?

   name=`basename -- "${PWD}"`

   if [ ! -z "${PROJECT}" ]
   then
      [ -d "${PROJECT}" ] || fail "xcodeproj ${PROJECT} not found"
      project="${PROJECT}"
   else
      project=`find_xcodeproj "${name}"`
      if [ "${project}" = "" ]
      then
         fail "no xcodeproj found"
      fi
   fi

   local projectdir
   local projectname

   projectdir="`dirname -- "${project}"`"
   projectname="`basename -- "${project}"`"

   # mod_pbxproj can only do Debug/Release/All...


   configurations=`read_root_setting "configurations" "Debug
Release"`

   #
   # Add LIBRARY_CONFIGURATION mapping
   #
   xcode_configurations=`list_configurations "${project}"`
   if [ "$xcode_configurations" = "" ]
   then
      xcode_configurations="Debug
Release"
   fi

   local flag

   if [ "$COMMAND" = "add" ]
   then
      flag="add"

      if [ $terse -ne 0 -a "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
      then
         #         012345678901234567890123456789012345678901234567890123456789
         log_info "Settings will be added to ${C_MAGENTA}${projectname}${C_RESET}."
         log_info "In the long term it may be more useful to copy/paste the"
         log_info "following lines into a set of local .xcconfig files, that are"
         log_info "inherited by all configurations."
      fi
   else
      flag="remove"

      if [ $terse -ne 0 ]
      then
         #         012345678901234567890123456789012345678901234567890123456789
         log_info "Settings will be removed from ${projectname}."
         log_info "You may want to check afterwards, that this has worked out"
         log_info "OK :)."
      fi
   fi

   local addictions_dir
   local dependencies_dir
   local header_search_paths
   local library_search_paths
   local framework_search_paths

   # grab values from master if needed
   DEPENDENCIES_DIR="`${MULLE_EXECUTABLE} paths dependencies`"
   ADDICTIONS_DIR="`${MULLE_EXECUTABLE} paths addictions`"

   relpath="`symlink_relpath "${DEPENDENCIES_DIR}" "${projectdir}"`"
   dependencies_dir='$(PROJECT_DIR)'/"${relpath}"

   relpath="`symlink_relpath "${ADDICTIONS_DIR}" "${projectdir}"`"
   addictions_dir='$(PROJECT_DIR)'/"${relpath}"

   header_search_paths=""
   if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      header_search_paths="`concat "${header_search_paths}" '$(DEPENDENCIES_DIR)/'"${HEADER_DIR_NAME}"`"
   fi
   header_search_paths="`concat "${header_search_paths}" '$(ADDICTIONS_DIR)/include'`"
   header_search_paths="`concat "${header_search_paths}" '$(inherited)'`"

   local default

   default=`echo "${configurations}" | tail -1 | sed 's/^[ \t]*//;s/[ \t]*$//'`

   library_search_paths=""
   if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      library_search_paths="`concat "${library_search_paths}" '$(DEPENDENCIES_DIR)/$(LIBRARY_CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)/'"${LIBRARY_DIR_NAME}"`"
      library_search_paths="`concat "${library_search_paths}" '$(DEPENDENCIES_DIR)/$(LIBRARY_CONFIGURATION)/'"${LIBRARY_DIR_NAME}"`"
      library_search_paths="`concat "${library_search_paths}" '$(DEPENDENCIES_DIR)/$(EFFECTIVE_PLATFORM_NAME)/'"${LIBRARY_DIR_NAME}"`"
      library_search_paths="`concat "${library_search_paths}" '$(DEPENDENCIES_DIR)/'"${LIBRARY_DIR_NAME}"`"
   fi
   library_search_paths="`concat "${library_search_paths}" '$(ADDICTIONS_DIR)/lib'`"
   library_search_paths="`concat "${library_search_paths}" '$(inherited)'`"

   framework_search_paths=""
   if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      framework_search_paths="`concat "${framework_search_paths}" '$(DEPENDENCIES_DIR)/$(LIBRARY_CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)/'"${FRAMEWORK_DIR_NAME}"`"
      framework_search_paths="`concat "${framework_search_paths}" '$(DEPENDENCIES_DIR)/$(LIBRARY_CONFIGURATION)/'"${FRAMEWORK_DIR_NAME}"`"
      framework_search_paths="`concat "${framework_search_paths}" '$(DEPENDENCIES_DIR)/$(EFFECTIVE_PLATFORM_NAME)/'"${FRAMEWORK_DIR_NAME}"`"
      framework_search_paths="`concat "${framework_search_paths}" '$(DEPENDENCIES_DIR)/'"${FRAMEWORK_DIR_NAME}"`"
   fi
   framework_search_paths="`concat "${framework_search_paths}" '$(ADDICTIONS_DIR)/'"${FRAMEWORK_DIR_NAME}"`"
   framework_search_paths="`concat "${framework_search_paths}" '$(inherited)'`"

   local query

   if check_for_mulle_xcode_settings
   then
      if [ "$COMMAND" = "add" ]
      then
         if [ $terse -ne 0 -a "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
         then
            local mapped
            local i

            printf  "${C_RESET_BOLD}-----------------------------------------------------------\n${C_RESET}" >&2

            #  make these echos easily grabable by stdout
            #     012345678901234567890123456789012345678901234567890123456789
            printf "${C_RESET_BOLD}Common.xcconfig:${C_RESET}\n"
            printf "${C_RESET_BOLD}-----------------------------------------------------------\n${C_RESET}" >&2
            echo "ADDICTIONS_DIR=${addictions_dir}"
            if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
            then
               echo "DEPENDENCIES_DIR=${dependencies_dir}"
            fi
            echo "HEADER_SEARCH_PATHS=${header_search_paths}"
            echo "LIBRARY_SEARCH_PATHS=${library_search_paths}"
            echo "FRAMEWORK_SEARCH_PATHS=${framework_search_paths}"
            printf  "${C_RESET_BOLD}-----------------------------------------------------------\n${C_RESET}" >&2

            IFS="
   "
            for i in ${xcode_configurations}
            do
               IFS="${DEFAULT_IFS}"
               mapped=`map_configuration "${configurations}" "${i}"`

               #     012345678901234567890123456789012345678901234567890123456789
               printf "${C_RESET_BOLD}${i}.xcconfig:${C_RESET}\n"
               printf "${C_RESET_BOLD}-----------------------------------------------------------\n${C_RESET}" >&2
               echo "#include \"Common.xcconfig\""
               echo ""
               echo "LIBRARY_CONFIGURATION=${mapped}"
               printf  "${C_RESET_BOLD}-----------------------------------------------------------\n${C_RESET}" >&2
            done

            IFS="${DEFAULT_IFS}"
         fi

         query="Add ${C_CYAN}${ADDICTIONS_DIR}/${LIBRARY_DIR_NAME}${C_MAGENTA} and friends to search paths of ${C_MAGENTA}${projectname}${C_YELLOW} ?"
      else
         query="Remove ${C_CYAN}${ADDICTIONS_DIR}/${LIBRARY_DIR_NAME}${C_MAGENTA} and friends from search paths of ${C_MAGENTA}${projectname}${C_YELLOW} ?"
      fi


      user_say_yes "$query"
      [ $? -eq 0 ] || exit 1

      if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
      then
         patch_library_configurations "${xcode_configurations}" "${configurations}" "${project}" "${default}" "${flag}"
      fi

      exekutor mulle-xcode-settings "${flag}" "ADDICTIONS_DIR" "${addictions_dir}" "${project}"  || exit 1
      exekutor mulle-xcode-settings "${flag}" "DEPENDENCIES_DIR" "${dependencies_dir}" "${project}"  || exit 1
      exekutor mulle-xcode-settings "${flag}" "HEADER_SEARCH_PATHS" "${header_search_paths}" "${project}"  || exit 1
      exekutor mulle-xcode-settings "${flag}" "LIBRARY_SEARCH_PATHS" "${library_search_paths}" "${project}"  || exit 1
      exekutor mulle-xcode-settings "${flag}" "FRAMEWORK_SEARCH_PATHS" "${framework_search_paths}" "${project}" || exit 1
   else
      exit 1
   fi

   if [ "$COMMAND" = "add" ]
   then
      if [ $terse -ne 0 -a "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
      then
         #     012345678901234567890123456789012345678901234567890123456789
         printf "${C_RESET_BOLD}${C_CYAN}\n" >&2
         echo "Hint:" >&2
         echo "If you add a configuration to your project, remember to" >&2
         echo "edit the ${C_RESET_BOLD}LIBRARY_CONFIGURATION${C_CYAN} setting for that" >&2
         echo "configuration." >&2
         echo "You can rerun \"${MULLE_EXECUTABLE} xcode add\" at later times" >&2
         echo "and it should not unduly duplicate setting contents." >&2
         printf "\n${C_RESET}" >&2
      fi
   fi
}


xcode_main()
{
   log_debug "::: xcode :::"

   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]        && . mulle-bootstrap-settings.sh
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh

   if [ "${UNAME}" != 'darwin' ]
   then
      fail "for now xcode only works on OS X"
   fi

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            xcode_usage
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown xcode option $1"
            xcode_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   COMMAND="${1:-add}"
   [ $# -eq 0 ] || shift

   case "$COMMAND" in
      add|remove)
         :
      ;;

      *)
         log_error "Unknown command \"${COMMAND}\""
         xcode_usage
      ;;
   esac


   PROJECT="$1"
   [ $# -eq 0 ] || shift


   patch_xcode_project "$@"
}
