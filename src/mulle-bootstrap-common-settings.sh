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
#   POSSIBILITY OF SUCH DAMAGE.
#
MULLE_BOOTSTRAP_COMMON_SETTINGS_SH="included"


simplified_dispense_style()
{
   local dispense_style="$1"
   local configurations="$2"
   local sdks="$3"

   local have_release
   local have_default

   have_release="$(fgrep -x -s "Release" <<< "${configurations}")"
   have_default="$(fgrep -x -s "Default" <<< "${sdks}")"

   # simplify dispense style to: none, category-strict or category-sdk-strict
   # for finding a bin directory
   while :
   do
      case "${dispense_style}" in
         auto|configuration)
            if [ ! -z "${have_release}" ]
            then
               echo "none"
            else
               echo "configuration-strict"
            fi
            return
         ;;

         configuration-sdk)
            if [ ! -z "${have_default}" ]
            then
               dispense_style="configuration" # reloop
            else
               echo "configuration-sdk-strict"
               return
            fi
         ;;


         none|configuration-strict|configuration-sdk-strict)
            echo "${dispense_style}"
            return
         ;;

         *)
            fail "Unknown dispense_style \"$dispense_style\""
         ;;
      esac
   done
}


_simplified_dispense_style_subdirectory()
{
   local dispense_style="$1"
   local configurations="$2"
   local sdks="$3"

   local configuration
   local sdk

   [ -z "${configurations}" ] && internal_fail "configurations is empty"
   [ -z "${sdks}" ]           && internal_fail "sdks is empty"

   case "${dispense_style}" in
      none)
      ;;

      configuration-strict)
         configuration="$(head -1 <<< "${configurations}")"
         echo "/${configuration}"
      ;;

      configuration-sdk-strict)
         configuration="$(head -1 <<< "${configurations}")"
         sdk="$(head -1 <<< "${sdks}")"
         echo "/${configuration}-${sdk}"
      ;;

      *)
         internal_fail "pass in the simplified dispense style"
      ;;
   esac
}


build_environment_options()
{
   log_debug ":build_environment_options:"

   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh

   if [ -z "${OPTION_SDKS}" ]
   then
      OPTION_SDKS="`read_config_setting "sdks" "Default"`"
      OPTION_SDKS="`read_root_setting "sdks" "${OPTION_SDKS}"`"
   fi

   if [ -z "${OPTION_CONFIGURATIONS}" ]
   then
      OPTION_CONFIGURATIONS="`read_config_setting "configurations" "Release"`"
      OPTION_CONFIGURATIONS="`read_root_setting "configurations" "${OPTION_CONFIGURATIONS}"`"
   fi

   #
   # Determine dispense_style
   #
   if [ -z "${OPTION_DISPENSE_STYLE}" ]
   then
      OPTION_DISPENSE_STYLE="`read_config_setting "dispense_style" "none"`"
   fi
}


#
# only needed for true builds
#
build_complete_environment()
{
   log_debug ":build_complete_environment:"

   [ -z "${__BUILD_COMPLETE_ENVIRONMENT}" ] || internal_fail "build_complete_environment run twice"
   __BUILD_COMPLETE_ENVIRONMENT="YES"

   build_environment_options

   ##
   ## try to minimize this
   ##
   # experimentally, these could reside outside the project folder but never tested
   CLONESBUILD_DIR="`read_sane_config_path_setting "build_dir" "build/.repos"`"
   BUILDLOGS_DIR="`read_sane_config_path_setting "build_log_dir" "${CLONESBUILD_DIR}/.logs"`"

   [ -z "${CLONESBUILD_DIR}" ]  && internal_fail "variable CLONESBUILD_DIR is empty"
   [ -z "${BUILDLOGS_DIR}" ]    && internal_fail "variable BUILDLOGS_DIR is empty"


   #
   # expand PATH for build, but it's kinda slow
   # so don't do it all the time
   #
   BUILDPATH="`prepend_to_search_path_if_missing "${MULLE_EXECUTABLE_ENV_PATH}" \
                                                 "${ADDICTIONS_DIR}/bin"`"

   # for scripts
   BUILDPATH="${BUILDPATH}:${MULLE_LIBEXEC_PATH}"

   #
   # dont export stuff for scripts
   # if scripts want it, they should source this file
   #
   case "${UNAME}" in
      mingw)
         [ -z "${MULLE_BOOTSTRAP_MINGW_SH}" ] && . mulle-bootstrap-mingw.sh

         setup_mingw_buildenvironment

         BUILDPATH="`mingw_buildpath "${BUILDPATH}"`"
         # if mulle-bootstrap is not properly installed pickup .bat path
         # this way
         local pretty

         pretty="`dirname -- "${MULLE_EXECUTABLE_PATH}"`"
         pretty="`simplified_path "$pretty"`"

         BUILDPATH="$pretty:${BUILDPATH}"
         BUILD_PWD_OPTIONS="-PW"

         log_fluff "MINGW buildpath is \"${BUILDPATH}\""
      ;;

      "")
         fail "UNAME not set"
      ;;

      *)
         # get number of cores, use 50% more for make -j
         if [ -z "${CORES}" ]
         then
            CORES="`get_core_count`"
            CORES="`expr $CORES + $CORES / 2`"
         fi

         BUILD_PWD_OPTIONS="-P"
         BUILDPATH="${BUILDPATH}"
      ;;
   esac
}


common_settings_initialize()
{
   log_debug ":common_settings_initialize:"

   #
   # Global Settings
   # used to be configurable, but just slows me down
   #
   case "${UNAME}" in
      *)
         FRAMEWORK_DIR_NAME="Frameworks"
         HEADER_DIR_NAME="include"
         LIBRARY_DIR_NAME="lib"
         LIBEXEC_DIR_NAME="libexec"
         RESOURCE_DIR_NAME="share"
         BIN_DIR_NAME="bin"
      ;;
   esac

   # HEADER_DIR_NAME="`read_config_setting "header_dir_name" "include"`"
   # LIBRARY_DIR_NAME="`read_config_setting "library_dir_name" "lib"`"
   # FRAMEWORK_DIR_NAME="`read_config_setting "framework_dir_name" "Frameworks"`"

   # all of these must reside in the project folder
   # used to be configurable, but what's the point really ? just slows us down

   DEPENDENCIES_DIR="dependencies"
   ADDICTIONS_DIR="addictions"
   STASHES_DEFAULT_DIR="stashes"

   # DEPENDENCIES_DIR="`read_sane_config_path_setting "dependencies_dir" "dependencies"`"
   # ADDICTIONS_DIR="`read_sane_config_path_setting "addictions_dir" "addictions"`"
   # STASHES_DEFAULT_DIR="`read_sane_config_path_setting "stashes_dir" "stashes"`"

#   [ -z "${DEPENDENCIES_DIR}" ]    && internal_fail "variable DEPENDENCIES_DIR is empty"
#   [ -z "${ADDICTIONS_DIR}" ]      && internal_fail "variable ADDICTIONS_DIR is empty"
#   [ -z "${STASHES_DEFAULT_DIR}" ] && internal_fail "variable STASHES_DEFAULT_DIR is empty"
}

common_settings_initialize
