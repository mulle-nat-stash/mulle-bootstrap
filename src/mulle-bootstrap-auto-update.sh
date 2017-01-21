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
MULLE_BOOTSTRAP_AUTO_UPDATE_SH="included"


#
# What auto_update does:
#
# 1. bootstrap_auto_create:
#    1.a. run once to copy roots .bootstrap.local to .bootstrap.auto
#    1.b) augment .bootstrap.local with stuff from .bootstrap
#
# 2. bootstrap_auto_update:
#    2.a) augment .bootstrap.local with stuff from .repos/<name>/.bootstrap
#

#
# prepend new contents to old contents
# of a few select and known files, these are merged with whats there
# `BOOTSTRAP_DIR` is the "root" bootstrap to update
# `directory` can be the inferior bootstrap of a fetched repository
#
_bootstrap_auto_update_merge()
{
   local directory

   directory="$1"

   [ -z "${directory}" ] && internal_fail "wrong"

   local srcfile
   local dstfile
   local localfile
   local tmpfile
   local settingname
   local match
   local i

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   IFS="
"
   for i in `ls -1 "${directory}/.bootstrap"`
   do
      IFS="${DEFAULT_IFS}"

      settingname="`basename -- "${i}"`"
      srcfile="${directory}/.bootstrap/${settingname}"

      if [ -d "${srcfile}" ]
      then
         log_fluff "Directory \"${srcfile}\" not copied"
         continue
      fi

      localfile="${BOOTSTRAP_DIR}.local/${settingname}"

      if [ -e "${localfile}" ]
      then
         log_info "Setting \"${settingname}\" is locally specified, so not merged"
         continue
      fi

      match="`echo "${NON_MERGABLE_SETTINGS}" | fgrep -s -x "${settingname}"`"
      if [ ! -z "${match}" ]
      then
         log_fluff "Setting \"${settingname}\" is not mergable, so ignored"
         continue
      fi

      match="`echo "${MERGABLE_SETTINGS}" | fgrep -s -x "${settingname}"`"
      if [ -z "${match}" ]
      then
         log_fluff "Setting \"${settingname}\" is unknown"
         continue
      fi

      dstfile="${BOOTSTRAP_DIR}.auto/${settingname}"
      if [ -f "${dstfile}" ]
      then
         tmpfile="${BOOTSTRAP_DIR}.auto/${settingname}.tmp"

         log_fluff "Merging \"${settingname}\" from \"${srcfile}\""

         exekutor mv "${dstfile}" "${tmpfile}" || exit 1
         redirect_exekutor "${dstfile}" exekutor merge_settings_in_front "${srcfile}" "${tmpfile}"  || exit 1
         exekutor rm "${tmpfile}" || exit 1
      else
         log_fluff "Copying \"${settingname}\" from \"${srcfile}\""

         exekutor cp "${srcfile}" "${dstfile}" || exit 1
      fi
   done

   IFS="${DEFAULT_IFS}"
}


_bootstrap_auto_update_repo_settings()
{
   local directory

   directory="$1"

   local srcdir
   local dstdir
   local reponame

   srcdir="${directory}/.bootstrap"
   dstdir="${BOOTSTRAP_DIR}.auto"

   [ -d "${dstdir}" ] || internal_fail "missing ${dstdir}"

   #
   # copy repo settings flat if not present already
   #
   for i in `find "${srcdir}" -mindepth 1 -maxdepth 1 -type d -print 2> /dev/null`
   do
      reponame="`basename -- "${i}"`"

      case "${reponame}" in
         .*)
            # skip hidden stuff
         ;;

         *.info)
            if [ -d "${dstdir}/${reponame}" ]
            then
               log_verbose "Settings for \"${reponame}\" are already present, so skipped"
               continue
            fi

            exekutor cp -Ra "${i}" "${dstdir}/${reponame}"
         ;;
      esac
   done

   rmdir_if_empty "${dstdir}"
}


#
# This function is called periodocally to update .bootstrap.auto with the
# contents of fetched repository .bootstraps
#
# `BOOTSTRAP_DIR` is the "root" bootstrap to update
# `directory` the fetched repository
# return 0, if something changed
#
bootstrap_auto_update()
{
   local name
   local directory

   name="$1"
   directory="$2"

   [ -z "${BOOTSTRAP_DIR}" ]     && internal_fail "BOOTSTRAP_DIR was empty"
   [ -z "${directory}" ]         && internal_fail "directory was empty"
   [ "${PWD}" = "${directory}" ] && internal_fail "configuration error"

   if [ "$MULLE_BOOTSTRAP_TRACE_MERGE" = "YES" ]
   then
      log_trace2 "bootstrap.auto: ${name} from ${directory}"
   fi

   log_verbose "Auto update \"${name}\" settings ($directory)"

   # contains own bootstrap ? and not a symlink
   if [ ! -d "${directory}/.bootstrap" ] # -a ! -L "${dst}" ]
   then
      log_fluff "No .bootstrap folder in \"${directory}\" found"
      return 1
   fi

   log_verbose "Updating .bootstrap.auto with ${directory}/.bootstrap ($PWD)"

   log_fluff "Acquiring \"${name}\" merge settings"
   _bootstrap_auto_update_merge "${directory}"

   log_fluff "Acquiring \"${name}\" repo settings"
   _bootstrap_auto_update_repo_settings "${directory}"

   log_fluff "Acquisiton of \"${name}\" settings complete"

   return 0
}


#
# This function is called initially to setup .bootstrap.auto before
# doing anything else. It is clear that .bootstrap.auto does not exist
#
# copy contents of .bootstrap.local to .bootstrap.auto
# them add contents of .bootstrap to .bootstrap.auto, if not present
#
bootstrap_auto_create()
{
   [ -z "${BOOTSTRAP_DIR}" ] && internal_fail "empty bootstrap"
   [ -d "${BOOTSTRAP_DIR}.auto" ] && internal_fail "${BOOTSTRAP_DIR}.auto already exists"

   log_verbose "Creating .bootstrap.auto from ${BOOTSTRAP_DIR} (`pwd -P`)"

   assert_mulle_bootstrap_version

   mkdir_if_missing "${BOOTSTRAP_DIR}.auto"

   #
   # Copy over .local verbatim
   #
   if dir_has_files "${BOOTSTRAP_DIR}.local"
   then
      exekutor cp -Ra "${BOOTSTRAP_DIR}.local/" "${BOOTSTRAP_DIR}.auto/"
   fi

   #
   # add stuff from bootstrap folder
   # don't copy config if exists (it could be malicious)
   #
   local path
   local name

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"
   IFS="
"
   for path in `ls -1 "${BOOTSTRAP_DIR}"`
   do
      IFS="${DEFAULT_IFS}"
      name="`basename -- "${path}"`"

      case "${name}" in
         config)
            continue
         ;;

         *)
            exekutor cp -Ran "${BOOTSTRAP_DIR}/${name}" "${BOOTSTRAP_DIR}.auto/"
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"
}


bootstrap_auto_final()
{
   [ -d "${BOOTSTRAP_DIR}.auto" ] || internal_fail "${BOOTSTRAP_DIR}.auto does not exists"

   log_verbose "Creating build_order from repositories"

   #
   # Copy over .local verbatim
   #
   if [ -f "${BOOTSTRAP_DIR}.auto/build_order" ]
   then
      log_fluff "build_order already exists"
      return
   fi

   #
   # add stuff from bootstrap folder
   # don't copy config if exists (it could be malicious)
   #
   # __parse_expanded_clone
   local name
   local url
   local branch
   local scm
   local tag
   local clone
   local order

   order=""

   IFS="
"
   for clone in `read_fetch_setting "repositories"`
   do
      IFS="${DEFAULT_IFS}"

      __parse_embedded_clone "${clone}"
      order="`add_line "${order}" "${name}"`"
   done

   echo "${order}"  > "${BOOTSTRAP_DIR}.auto/build_order"

   IFS="${DEFAULT_IFS}"
}


auto_update_initialize()
{
   log_fluff ":auto_update_initialize:"

   MERGABLE_SETTINGS='brews
taps
tarballs
repositories
'

   NON_MERGABLE_SETTINGS='embedded_repositories
version
'
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
}

auto_update_initialize
