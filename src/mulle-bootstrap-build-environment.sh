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
MULLE_BOOTSTRAP_BUILD_ENVIRONMENT_SH="included"

# only needed for true builds

build_complete_environment()
{
   if [ ! -z "${CLEAN_BEFORE_BUILD}" ]
   then
      return
   fi

   CLEAN_BEFORE_BUILD=`read_config_setting "clean_before_build"`
   if [ -z "${CONFIGURATIONS}" ]
   then
      CONFIGURATIONS="`read_config_setting "configurations" "Release"`"
      CONFIGURATIONS="`read_build_root_setting "configurations" "${CONFIGURATIONS}"`"
   fi
   N_CONFIGURATIONS="`echo "${CONFIGURATIONS}" | wc -l | awk '{ print $1 }'`"

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
         CORES="`get_core_count`"
         CORES="`expr $CORES + $CORES / 2`"

         BUILD_PWD_OPTIONS="-P"
         BUILDPATH="$PATH"
      ;;
   esac
}


make_executable_search_path()
{
   local path
   local dependencies
   local addictions

   path="$1"
   dependencies="$2"
   addictions="$3"

   #
   #
   #
   local new_path
   local tail_path

   tail_path=""
   new_path=""
   addictions="`realpath "${addictions}"`"
   dependencies="`realpath "${dependencies}"`"

   tail_path="`add_path "${tail_path}" "${dependencies}/bin"`"
   tail_path="`add_path "${tail_path}" "${addictions}/bin"`"

   local i
   local oldifs

   oldifs="$IFS"
   IFS=":"

   for i in $path
   do
      IFS="${oldifs}"

      # shims stay in front (homebrew)
      case "$i" in
         */shims/*)
            new_path="`add_path "${new_path}" "$i"`"
         ;;

         *)
            tail_path="`add_path "${tail_path}" "$i"`"
         ;;
      esac
   done

   IFS="${oldifs}"

   add_path "${new_path}" "${tail_path}"
}


build_environment_initialize()
{
   log_fluff ":build_environment_initialize:"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh

   CLONESBUILD_SUBDIR="`read_sane_config_path_setting "build_foldername" "build/.repos"`"
   BUILDLOG_SUBDIR="`read_sane_config_path_setting "build_log_foldername" "${CLONESBUILD_SUBDIR}/.logs"`"
   DEPENDENCIES_DIR="`read_sane_config_path_setting "dependency_dir" "dependencies"`"
   ADDICTIONS_DIR="`read_sane_config_path_setting "addictions_dir" "addictions"`"
   STASHES_DIR="`read_sane_config_path_setting "stashes_dir" "stashes"`"

   [ -z "${CLONESBUILD_SUBDIR}" ] && internal_fail "variable CLONESBUILD_SUBDIR is empty"
   [ -z "${BUILDLOG_SUBDIR}" ]    && internal_fail "variable BUILDLOG_SUBDIR is empty"
   [ -z "${DEPENDENCIES_DIR}" ]   && internal_fail "variable DEPENDENCIES_DIR is empty"
   [ -z "${ADDICTIONS_DIR}" ]     && internal_fail "variable ADDICTIONS_DIR is empty"
   [ -z "${STASHES_DIR}" ]        && internal_fail "variable STASHES_DIR is empty"

   PATH="`make_executable_search_path "$PATH" "${DEPENDENCIES_DIR}" "${ADDICTIONS_DIR}"`"
   export PATH

   log_fluff "PATH set to: $PATH"

   #
   # Global Settings
   #
   HEADER_DIR_NAME="`read_config_setting "header_dir_name" "include"`"
   LIBRARY_DIR_NAME="`read_config_setting "library_dir_name" "lib"`"
   FRAMEWORK_DIR_NAME="`read_config_setting "framework_dir_name" "Frameworks"`"
}

build_environment_initialize
