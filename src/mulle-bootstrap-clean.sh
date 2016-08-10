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

. mulle-bootstrap-local-environment.sh

CLEAN_EMPTY_PARENTS="`read_config_setting "clean_empty_parent_folders" "YES"`"


BUILD_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "clean_folders" "${CLONESBUILD_SUBDIR}
${DEPENDENCY_SUBDIR}/tmp"`"
OUTPUT_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "output_clean_folders" "${DEPENDENCY_SUBDIR}"`"
DIST_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "dist_clean_folders" "${CLONES_SUBDIR}
${ADDICTION_SUBDIR}
.bootstrap.auto"`"
INSTALL_CLEANABLE_SUBDIRS="`read_sane_config_path_setting "install_clean_folders" "${BUILD_CLEANABLE_SUBDIRS}
${CLONES_SUBDIR}
.bootstrap.auto"`"


embedded_repositories()
{
   local clones
   local clone
   local dir
   local name

   clones="`read_fetch_setting "embedded_repositories"`"
   if [ "${clones}" != "" ]
   then
      local old

      old="${IFS:-" "}"
      IFS="
"
      for clone in ${clones}
      do
         IFS="${old}"

         clone="`expanded_setting "${clone}"`"

         name="`canonical_name_from_clone "${clone}"`"
         dir="${name}"
         echo "${dir}"
      done
      IFS="${old}"
   fi
}


EMBEDDED="`embedded_repositories`"

if [ ! -z "$EMBEDDED" ]
then
   DIST_CLEANABLE_SUBDIRS="${DIST_CLEANABLE_SUBDIRS}
${EMBEDDED}"
fi


usage()
{
   cat <<EOF
clean [build|dist|install|output]

   build   : useful to remove intermediate build files. it cleans
---
${BUILD_CLEANABLE_SUBDIRS}
---

   output  : useful to rebuild. This is the default. It cleans
---
${BUILD_CLEANABLE_SUBDIRS}
${OUTPUT_CLEANABLE_SUBDIRS}
---

   dist    : remove all clones, dependencies, addictions. It cleans
---
${BUILD_CLEANABLE_SUBDIRS}
${OUTPUT_CLEANABLE_SUBDIRS}
${DIST_CLEANABLE_SUBDIRS}
---

   install  : useful if you know, you don't want to rebuild ever. It cleans
---
${INSTALL_CLEANABLE_SUBDIRS}
---
EOF
}


check_and_usage_and_help()
{
   case "$COMMAND" in
      output)
      ;;
      dist)
      ;;
      build)
      ;;
      install)
      ;;
      *)
      usage >&2
      exit 1
      ;;
   esac
}


COMMAND=${1:-"output"}
[ $# -eq 0 ] || shift

check_and_usage_and_help


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

         if dir_can_be_rmdir "${parent}"
         then
            assert_sane_subdir_path "${parent}"
            log_info "Deleting \"${parent}\" because it was empty. "
            log_fluff "Set \".bootstrap/config/clean_empty_parent_folders\" to NO if you don't like it."
            exekutor rmdir "${parent}"
         fi
      done
   fi
}



#
# cleanability is checked, because in some cases its convenient
# to have other tools provide stuff besides /include and /lib
# and sometimes  projects install other stuff into /share
#
clean()
{
   local flag
   local old

   old="${IFS:-" "}"
   IFS="
"

   flag="NO"
   if [ ! -z "${BUILD_CLEANABLE_SUBDIRS}" ]
   then
      if [ "${COMMAND}" = "build" -o "${COMMAND}" = "dist" -o "${COMMAND}" = "output"  ]
      then
         for dir in ${BUILD_CLEANABLE_SUBDIRS}
         do
            clean_asserted_folder "${dir}"
            clean_parent_folders_if_empty "${dir}" "${PWD}"
            flag="YES"
         done
      fi
   fi


   if [ ! -z "${OUTPUT_CLEANABLE_SUBDIRS}" ]
   then
      if [ "${COMMAND}" = "dist" -o "${COMMAND}" = "output" ]
      then
         for dir in ${OUTPUT_CLEANABLE_SUBDIRS}
         do
            clean_asserted_folder "${dir}"
            clean_parent_folders_if_empty "${dir}" "${PWD}"
            flag="YES"
         done
      fi
   fi


   if [ ! -z "${INSTALL_CLEANABLE_SUBDIRS}" ]
   then
      if [ "${COMMAND}" = "install" ]
      then
         for dir in ${INSTALL_CLEANABLE_SUBDIRS}
         do
            clean_asserted_folder "${dir}"
            clean_parent_folders_if_empty "${dir}" "${PWD}"
            flag="YES"
         done
      fi
   fi

   if [ ! -z "${DIST_CLEANABLE_SUBDIRS}" ]
   then
      if [ "${COMMAND}" = "dist" ]
      then
         for dir in ${DIST_CLEANABLE_SUBDIRS}
         do
            clean_asserted_folder "${dir}"
            clean_parent_folders_if_empty "${dir}" "${PWD}"
            flag="YES"
         done
      fi
   fi

   if [ "$flag" = "NO" ]
   then
      log_info "Nothing configured to clean"
   fi

   IFS="${old}"
}


main()
{
   #
   # don't rename these settings anymore, the consequences can be catastrophic
   # for users of previous versions.
   # Also don't change the search paths for read_sane_config_path_setting
   #
   log_fluff "::: clean :::"

   clean "$@"
}

main "$@"
