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
#
MULLE_BOOTSTRAP_COMMON_SETTINGS_SH="included"

#
# only needed for true builds
#
build_complete_environment()
{
   #
   # Global Settings
   # used to be configurable, but just slows me down
   HEADER_DIR_NAME="include"
   LIBRARY_DIR_NAME="lib"
   FRAMEWORK_DIR_NAME="Frameworks"

   # HEADER_DIR_NAME="`read_config_setting "header_dir_name" "include"`"
   # LIBRARY_DIR_NAME="`read_config_setting "library_dir_name" "lib"`"
   # FRAMEWORK_DIR_NAME="`read_config_setting "framework_dir_name" "Frameworks"`"

   OPTION_CLEAN_BEFORE_BUILD=`read_config_setting "clean_before_build"`
   if [ -z "${OPTION_CONFIGURATIONS}" ]
   then
      OPTION_CONFIGURATIONS="`read_config_setting "configurations" "Release"`"
      OPTION_CONFIGURATIONS="`read_root_setting "configurations" "${OPTION_CONFIGURATIONS}"`"
   fi
   N_CONFIGURATIONS="`echo "${OPTION_CONFIGURATIONS}" | wc -l | awk '{ print $1 }'`"

   #
   # expand PATH for build, but it's kinda slow
   # so don't do it all the time
   #
   PATH="`prepend_to_search_path_if_missing "$PATH" "${DEPENDENCIES_DIR}/bin" "${ADDICTIONS_DIR}/bin"`"
   export PATH

   log_fluff "PATH set to: $PATH"

   #
   # dont export stuff for scripts
   # if scripts want it, they should source this file
   #
   case "${UNAME}" in
      mingw)
         [ -z "${MULLE_BOOTSTRAP_MINGW_SH}" ] && . mulle-bootstrap-mingw.sh

         setup_mingw_buildenvironment

         BUILDPATH="`mingw_buildpath "$PATH"`"
         BUILD_PWD_OPTIONS="-PW"
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
         BUILDPATH="$PATH"
      ;;
   esac
}


common_settings_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

   log_debug ":common_settings_initialize:"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]          && . mulle-bootstrap-settings.sh

   # experimentally, these could reside outside the project folder but never tested
   CLONESBUILD_DIR="`read_sane_config_path_setting "build_dir" "build/.repos"`"
   BUILDLOGS_DIR="`read_sane_config_path_setting "build_log_dir" "${CLONESBUILD_DIR}/.logs"`"

   # all of these must reside in the project folder
   # used to be configurable, but what's the point really ? just slows us down

   DEPENDENCIES_DIR="dependencies"
   ADDICTIONS_DIR="addictions"
   STASHES_DEFAULT_DIR="stashes"

   # DEPENDENCIES_DIR="`read_sane_config_path_setting "dependencies_dir" "dependencies"`"
   # ADDICTIONS_DIR="`read_sane_config_path_setting "addictions_dir" "addictions"`"
   # STASHES_DEFAULT_DIR="`read_sane_config_path_setting "stashes_dir" "stashes"`"

   [ -z "${CLONESBUILD_DIR}" ]  && internal_fail "variable CLONESBUILD_DIR is empty"
   [ -z "${BUILDLOGS_DIR}" ]    && internal_fail "variable BUILDLOGS_DIR is empty"
#   [ -z "${DEPENDENCIES_DIR}" ]    && internal_fail "variable DEPENDENCIES_DIR is empty"
#   [ -z "${ADDICTIONS_DIR}" ]      && internal_fail "variable ADDICTIONS_DIR is empty"
#   [ -z "${STASHES_DEFAULT_DIR}" ] && internal_fail "variable STASHES_DEFAULT_DIR is empty"
}

common_settings_initialize
