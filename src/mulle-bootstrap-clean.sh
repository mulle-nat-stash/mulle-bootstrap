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
MULLE_BOOTSTRAP_CLEAN_SH="included"


setup_clean_environment()
{
   [ -z "${DEPENDENCIES_DIR}"  ]   && internal_fail "DEPENDENCIES_DIR is empty"
   [ -z "${CLONESBUILD_SUBDIR}" ]  && internal_fail "CLONESBUILD_SUBDIR is empty"
   [ -z "${ADDICTIONS_DIR}" ]      && internal_fail "ADDICTIONS_DIR is empty"
   [ -z "${STASHES_DEFAULT_DIR}" ] && internal_fail "STASHES_DEFAULT_DIR is empty"

   CLEAN_EMPTY_PARENTS="`read_config_setting "clean_empty_parent_folders" "YES"`"

   BUILD_CLEANABLE_FILES="${REPOS_DIR}/.bootstrap_build_done"

   BUILD_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "clean_folders" "${CLONESBUILD_SUBDIR}
${DEPENDENCIES_DIR}/tmp"`"
   OUTPUT_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "output_clean_folders" "${DEPENDENCIES_DIR}"`"
   INSTALL_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "install_clean_folders" "${REPOS_DIR}
${STASHES_DEFAULT_DIR}
.bootstrap.auto"`"
   DIST_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "dist_clean_folders" "${REPOS_DIR}
${ADDICTIONS_DIR}
${STASHES_DEFAULT_DIR}
.bootstrap.auto"`"
   EMBEDDED="`stashes_of_embedded_repositories "${REPOS_DIR}"`"

   DIST_CLEANABLE_SUBDIRS="`add_line "${EMBEDDED}" "${DIST_CLEANABLE_SUBDIRS}"`"
}


_clean_usage()
{
   setup_clean_environment

   cat <<EOF >&2
   build   : useful to remove intermediate build files. it cleans
---
${BUILD_CLEANABLE_SUBDIRS}
${BUILD_CLEANABLE_FILES}
---

   output  : useful to rebuild. It cleans
---
${BUILD_CLEANABLE_SUBDIRS}
${BUILD_CLEANABLE_FILES}
${OUTPUT_CLEANABLE_SUBDIRS}
---

   install : useful if you know, you don't want to rebuild.
---
${BUILD_CLEANABLE_SUBDIRS}
${INSTALL_CLEANABLE_SUBDIRS}
---

   dist    : remove all clones, dependencies, addictions. It cleans
---
${BUILD_CLEANABLE_SUBDIRS}
${OUTPUT_CLEANABLE_SUBDIRS}
${DIST_CLEANABLE_SUBDIRS}
---
EOF
}


clean_usage()
{
   cat <<EOF >&2
usage:
   mulle-bootstrap clean [build|dist|install|output]

EOF
   _clean_usage
   exit 1
}


clean_asserted_folder()
{
   if [ -d "$1" ]
   then
      log_info "Deleting \"$1\""

      rmdir_safer "$1"
   else
      log_fluff "\"$1\" doesn't exist"
   fi
}


clean_asserted_file()
{
   if [ -f "$1" ]
   then
      log_info "Deleting \"$1\""

      remove_file_if_present "$1"
   else
      log_fluff "\"$1\" doesn't exist"
   fi
}



clean_parent_folders_if_empty()
{
   local dir
   local stop

   if [ "${CLEAN_EMPTY_PARENTS}" = "YES" ]
   then
      dir="$1"
      stop="$2"

      local parent

      parent="${dir}"
      while :
      do
         parent="`dirname -- "${parent}"`"
         if [ "${parent}" = "." -o "${parent}" = "${stop}" ]
         then
             break
         fi

         if dir_is_empty "${parent}"
         then
            assert_sane_subdir_path "${parent}"
            log_info "Deleting \"${parent}\" because it was empty. "
            log_fluff "Set \"${BOOTSTRAP_DIR}/config/clean_empty_parent_folders\" to NO if you don't like it."
            exekutor rmdir "${parent}"
         fi
      done
   fi
}


clean_files()
{
   local files

   files="$1"

   local file

   IFS="
"
   for file in ${files}
   do
      IFS="${DEFAULT_IFS}"

      clean_asserted_file "${file}"
   done

   IFS="${DEFAULT_IFS}"
}


clean_directories()
{
   local directories
   local flag

   directories="$1"
   flag="$2"

   local directory

   IFS="
"
   for directory in ${directories}
   do
      IFS="${DEFAULT_IFS}"

      clean_asserted_folder "${directory}"
      clean_parent_folders_if_empty "${directory}" "${PWD}"
      flag="YES"
   done
   IFS="${DEFAULT_IFS}"

   echo "$flag"
}



_print_stashdir()
{
   # local reposdir="$1"  # ususally .bootstrap.repos
   # local name="$2"      # name of the clone
   # local url="$3"       # URL of the clone
   # local branch="$4"    # branch of the clone
   # local scm="$5"       # scm to use for this clone
   # local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   local stashparentdir

   stashparentdir="`dirname -- "${stashdir}"`"
   if [ "${stashparentdir}" != "${STASHES_DEFAULT_DIR}" ]
   then
      echo "${stashdir}"
   fi
}


print_stashdir_repositories()
{
   walk_repositories "repositories" \
                     "_print_stashdir" \
                     "" \
                     "${REPOS_DIR}"
}


print_stashdir_embedded_repositories()
{
   walk_repositories "embedded_repositories" \
                     "_print_stashdir" \
                     "" \
                     "${EMBEDDED_REPOS_DIR}"
}


#
# dist cleaning is dangerous
#
_dist_clean()
{
   # dependencies already done before

   DIST_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "dist_clean_folders" \
"${REPOS_DIR}
${ADDICTIONS_DIR}
${STASHES_DEFAULT_DIR}
${BOOTSTRAP_DIR}.auto"`"

   # scrub old stuff
   if [ -d ".repos" ]
   then
      DIST_CLEANABLE_SUBDIRS="`add_line "${DIST_CLEANABLE_SUBDIRS}" ".repos"`"
   else
      #
      # as a master we don't throw the minions out
      #
      if ! is_master_bootstrap_project
      then
         local stashes

         stashes="`print_stashdir_repositories`"
         DIST_CLEANABLE_SUBDIRS="`add_line "${DIST_CLEANABLE_SUBDIRS}" "${stashes}"`"

         stashes="`print_stashdir_embedded_repositories`"
         DIST_CLEANABLE_SUBDIRS="`add_line "${DIST_CLEANABLE_SUBDIRS}" "${stashes}"`"
      fi
   fi

   clean_directories "${DIST_CLEANABLE_SUBDIRS}" "${flag}"

   clean_files "${DIST_CLEANABLE_FILES}"
}


#
# for mingw its faster, if we have separate clean functions
#
# cleanability is checked, because in some cases its convenient
# to have other tools provide stuff besides /include and /lib
# and sometimes  projects install other stuff into /share
#
_clean_execute()
{
   local flag

   [ -z "${DEPENDENCIES_DIR}"  ]   && internal_fail "DEPENDENCIES_DIR is empty"
   [ -z "${CLONESBUILD_SUBDIR}" ]  && internal_fail "CLONESBUILD_SUBDIR is empty"
   [ -z "${ADDICTIONS_DIR}"   ]    && internal_fail "ADDICTIONS_DIR is empty"
   [ -z "${STASHES_DEFAULT_DIR}" ] && internal_fail "STASHES_DEFAULT_DIR is empty"

   flag=
   CLEAN_EMPTY_PARENTS="`read_config_setting "clean_empty_parent_folders" "YES"`"


   case "${COMMAND}" in
      build)
         BUILD_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "clean_folders" "${CLONESBUILD_SUBDIR}
${DEPENDENCIES_DIR}/tmp"`"
         BUILD_CLEANABLE_FILES="${REPOS_DIR}/.bootstrap_build_done"
         clean_directories "${BUILD_CLEANABLE_SUBDIRS}" "${flag}"
         clean_files "${BUILD_CLEANABLE_FILES}"
         return
      ;;

      dist|output|install)
         BUILD_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "clean_folders" "${CLONESBUILD_SUBDIR}
${DEPENDENCIES_DIR}/tmp"`"
         BUILD_CLEANABLE_FILES="${REPOS_DIR}/.bootstrap_build_done"
         flag="`clean_directories "${BUILD_CLEANABLE_SUBDIRS}" "${flag}"`"
         clean_files "${BUILD_CLEANABLE_FILES}"
      ;;
   esac

   case "${COMMAND}" in
      output)
         OUTPUT_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "output_clean_folders" "${DEPENDENCIES_DIR}"`"
         clean_directories "${OUTPUT_CLEANABLE_SUBDIRS}" "${flag}"
         clean_files "${OUTPUT_CLEANABLE_FILES}"
         return
      ;;

      dist)
         OUTPUT_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "output_clean_folders" "${DEPENDENCIES_DIR}"`"
         flag="`clean_directories "${OUTPUT_CLEANABLE_SUBDIRS}" "${flag}"`"
         clean_files "${OUTPUT_CLEANABLE_FILES}"
      ;;
   esac

   case "${COMMAND}" in
      install)
         INSTALL_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "install_clean_folders" "${REPOS_DIR}
.bootstrap.auto"`"
         clean_directories "${INSTALL_CLEANABLE_SUBDIRS}" "${flag}"
         clean_files "${INSTALL_CLEANABLE_FILES}"
         return
      ;;
   esac

   case "${COMMAND}" in
      dist)
         _dist_clean
      ;;
   esac
}


clean_execute()
{
   local flag

   flag="`_clean_execute "$@"`"
   if [ "$flag" = "NO" ]
   then
      log_info "Nothing configured to clean"
   fi
}


#
# don't rename these settings anymore, the consequences can be catastrophic
# for users of previous versions.
# Also don't change the search paths for read_sane_config_path_setting
#
clean_main()
{
   log_debug "::: clean :::"

   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ] && . mulle-bootstrap-repositories.sh

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   build_complete_environment

   COMMAND=

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            COMMAND=help
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown clean option $1"
            COMMAND=help
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${COMMAND}" ]
   then
      COMMAND=${1:-"output"}
      [ $# -eq 0 ] || shift
   fi


   case "$COMMAND" in
      output|dist|build|install)
         clean_execute "$@"
      ;;

      help)
         clean_usage
      ;;

      _help)
         _clean_usage
      ;;

      *)
         log_error "Unknown command \"${COMMAND}\""
         clean_usage
      ;;
   esac
}
