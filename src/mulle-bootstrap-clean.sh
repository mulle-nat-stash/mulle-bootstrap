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
MULLE_BOOTSTRAP_CLEAN_SH="included"


clean_usage()
{
   setup_clean_environment

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE} clean [command]

   Default clean command is "full".

Commands:
   cruft : remove intermediate build files to conserve space. It deletes
`echo "${CRUFT_CLEANABLE_SUBDIRS}" | sort -u | sed '/^$/d' | sed -e 's/^/      /'`

   install : keep only addictions and dependencies
`echo "${CRUFT_CLEANABLE_SUBDIRS}
${INSTALL_CLEANABLE_SUBDIRS}" | sort -u | sed '/^$/d' | sed -e 's/^/      /'`

   build : useful to rebuild. It deletes
`echo "${CRUFT_CLEANABLE_SUBDIRS}
${BUILD_CLEANABLE_SUBDIRS}
${BUILD_CLEANABLE_FILES}
${BUILD_CLEANABLE_SUBDIRS}"  | sort -u | sed '/^$/d' | sed -e 's/^/      /'`

   full : useful to pickup config changes and to rebuild
`echo "${CRUFT_CLEANABLE_SUBDIRS}
${BUILD_CLEANABLE_SUBDIRS}
${BUILD_CLEANABLE_FILES}
${BUILD_CLEANABLE_SUBDIRS}
${FULL_CLEANABLE_SUBDIRS}" | sort -u | sed '/^$/d' | sed -e 's/^/      /'`

   dist : remove all clones, dependencies, addictions. It deletes
`echo "${CRUFT_CLEANABLE_SUBDIRS}
${BUILD_CLEANABLE_SUBDIRS}
${BUILD_CLEANABLE_FILES}
${BUILD_CLEANABLE_SUBDIRS}
${FULL_CLEANABLE_SUBDIRS}
${INSTALL_CLEANABLE_SUBDIRS}
${DIST_CLEANABLE_SUBDIRS}"    | sort -u | sed '/^$/d' | sed -e 's/^/      /'`

EOF

   exit 1
}


_collect_stashdir()
{
   log_debug ":_collect_stashdir:" "$*"

   # local reposdir="$1"  # ususally .bootstrap.repos
   # local name="$2"      # name of the clone
   # local url="$3"       # URL of the clone
   # local branch="$4"    # branch of the clone
   # local scm="$5"       # scm to use for this clone
   # local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   is_minion_bootstrap_project "${stashdir}" && return

   case "${stashdir}" in
      stashes/*)
         return
      ;;
   esac

   echo "${stashdir}"
}


#
# MEMO don't walk via .bootstrap.auto here, use information from
# .bootstrap.repos
#
print_stashdir_repositories()
{
   local permissions

   permissions=""
   walk_repos_repositories "${REPOS_DIR}" \
                           "_collect_stashdir" \
                           "${permissions}"
}


print_embedded_stashdir_repositories()
{
   local permissions

   permissions=""
   walk_repos_repositories "${EMBEDDED_REPOS_DIR}" \
                            "_collect_stashdir" \
                            "${permissions}"
}


print_stashdir_deep_embedded_repositories()
{
   local permissions

   permissions="minion"
   walk_deep_embedded_repos_repositories "_collect_stashdir" \
                                         "${permissions}"
}


print_stashdir_deep_embedded_minion_repositories()
{
   local permissions

   permissions="minion"
   walk_deep_embedded_minion_repositories "_collect_stashdir" \
                                         "${permissions}"
}


_collect_embedded_stashdir()
{
   # local reposdir="$1"  # ususally .bootstrap.repos
   # local name="$2"      # name of the clone
   # local url="$3"       # URL of the clone
   # local branch="$4"    # branch of the clone
   # local scm="$5"       # scm to use for this clone
   # local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   stashparentdir="`dirname -- "${stashdir}"`"

   [ "${stashparentdir}" = "${STASHES_DEFAULT_DIR}" ] && return
   echo "${stashdir}"
}


print_stashdir_embedded_repositories()
{
   walk_auto_repositories "embedded_repositories" \
                          "_collect_embedded_stashdir" \
                          "" \
                          "${EMBEDDED_REPOS_DIR}"
}


setup_clean_environment()
{
   build_complete_environment

   [ -z "${DEPENDENCIES_DIR}"  ]   && internal_fail "DEPENDENCIES_DIR is empty"
   [ -z "${CLONESBUILD_DIR}" ]     && internal_fail "CLONESBUILD_DIR is empty"
   [ -z "${ADDICTIONS_DIR}" ]      && internal_fail "ADDICTIONS_DIR is empty"
   [ -z "${STASHES_DEFAULT_DIR}" ] && internal_fail "STASHES_DEFAULT_DIR is empty"

   CLEAN_EMPTY_PARENTS="`read_config_setting "clean_empty_parent_folders" "YES"`"


   CRUFT_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "clean_folders" "${CLONESBUILD_DIR}
${DEPENDENCIES_DIR}/tmp"`"

   BUILD_CLEANABLE_FILES="${REPOS_DIR}/.build_done"

   # BUILD is: CRUFT +  ...
   BUILD_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "output_clean_folders" "${DEPENDENCIES_DIR}"`"

   # INSTALL is: CRUFT + ...
   INSTALL_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "install_clean_folders" "${REPOS_DIR}
${STASHES_DEFAULT_DIR}"`"

   # FULL is: CRUFT + BUILD + ...
   FULL_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "full_clean_folders" "${BOOTSTRAP_DIR}.auto"`"

   # DIST is: CRUFT + BUILD + FULL + INSTALL + ...
   DIST_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "dist_clean_folders" \
"${ADDICTIONS_DIR}"`"

   # scrub old stuff
   if [ -d ".repos" ]
   then
      DIST_CLEANABLE_SUBDIRS="`add_line "${DIST_CLEANABLE_SUBDIRS}" ".repos"`"
   fi

   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ] && . mulle-bootstrap-repositories.sh

   #
   # as a master we don't throw the minions out
   # but we are responsible for embedded repositories of minions
   #
   local stashes

   stashes="`print_stashdir_repositories`"
   DIST_CLEANABLE_SUBDIRS="`add_line "${DIST_CLEANABLE_SUBDIRS}" "${stashes}"`"

   stashes="`print_stashdir_embedded_repositories`"
   DIST_CLEANABLE_SUBDIRS="`add_line "${DIST_CLEANABLE_SUBDIRS}" "${stashes}"`"

   stashes="`print_stashdir_deep_embedded_repositories`"
   DIST_CLEANABLE_SUBDIRS="`add_line "${DIST_CLEANABLE_SUBDIRS}" "${stashes}"`"

   stashes="`print_stashdir_deep_embedded_minion_repositories`"
   DIST_CLEANABLE_SUBDIRS="`add_line "${DIST_CLEANABLE_SUBDIRS}" "${stashes}"`"
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
   local dir="$1"
   local stop="$2"

   if [ "${CLEAN_EMPTY_PARENTS}" = "YES" ]
   then
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
   local files="$1"

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
   local directories="$1"

   local directory

   IFS="
"
   for directory in ${directories}
   do
      IFS="${DEFAULT_IFS}"

      clean_asserted_folder "${directory}"
      clean_parent_folders_if_empty "${directory}" "${PWD}"
   done

   IFS="${DEFAULT_IFS}"
}


#
# for mingw its faster, if we have separate clean functions
#
# cleanability is checked, because in some cases its convenient
# to have other tools provide stuff besides /include and /lib
# and sometimes  projects install other stuff into /share
#
clean_execute()
{
   local style="$1"

   setup_clean_environment

   # CRUFT
   case "${style}" in
      cruft|build|dist|full|output|install)
         clean_directories "${CRUFT_CLEANABLE_SUBDIRS}"
      ;;

      *)
         internal_fail "Unknown clean style \"${style}\""
      ;;
   esac

   # BUILD, formerly called OUTPUT
   case "${style}" in
      build|dist|full|output)
         clean_directories "${BUILD_CLEANABLE_SUBDIRS}"
         clean_files "${BUILD_CLEANABLE_FILES}"
      ;;

   esac

   # FULL
   case "${style}" in
      dist|full)
         clean_directories "${FULL_CLEANABLE_SUBDIRS}"

         if [ -d "${BOOTSTRAP_DIR}.local" ]
         then
            touch "${BOOTSTRAP_DIR}.local"
         else
            if [ -d "${BOOTSTRAP_DIR}" ]
            then
               touch "${BOOTSTRAP_DIR}"
            fi
         fi
      ;;
   esac

   # INSTALL
   case "${style}" in
      dist|install)
         clean_directories "${INSTALL_CLEANABLE_SUBDIRS}"
      ;;
   esac

   # DIST
   case "${style}" in
      dist)
         clean_directories "${DIST_CLEANABLE_SUBDIRS}"
      ;;
   esac
}


#
# clean embedded repositories out of minion
#
clean_minion()
{
   local minion="$1"

   local directories

   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ] && . mulle-bootstrap-repositories.sh

   directories="`_all_repository_stashes "${REPOS_DIR}/.deep/${minion}.d"`"
   clean_directories "${directories}"
   clean_directories "${REPOS_DIR}/.deep/${minion}.d"
}


#
# don't rename these settings anymore, the consequences can be catastrophic
# for users of previous versions.
# Also don't change the search paths for read_sane_config_path_setting
#
clean_main()
{
   log_debug "::: clean :::"

   local ROOT_DIR="`pwd -P`"

   local MINION_NAME

   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]        && . mulle-bootstrap-settings.sh
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ]    && . mulle-bootstrap-repositories.sh

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            clean_usage
         ;;


         -m|--minion)
            shift
            [ $# -ne 0 ] || clean_usage

            MINION_NAME="${1}"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown clean option $1"
            clean_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local style

   style=${1:-"full"}

   case "${style}" in
      "cruft"|"build"|"output"|"full"|"dist"|"install"|"output")
         if [ -z "${MINION_NAME}" ]
         then
            clean_execute "${style}"
         else
            clean_minion "${MINION_NAME}"
         fi
      ;;

      help)
         clean_usage
      ;;

      *)
         log_error "Unknown clean style \"${style}\""
         clean_usage
      ;;
   esac
}
