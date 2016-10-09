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
# MERGE some settings
#
# prepend new contents to old contents
# of a few select and known files, these are merged with whats there
#
bootstrap_auto_update_merge()
{
   local directory

   directory="$1"

   local srcfile
   local dstfile
   local localfile
   local tmpfile
   local settingname
   local match
   local i

   IFS="
"
   for i in `ls -1 "${directory}/.bootstrap"`
   do
      IFS="${DEFAULT_IFS}"

      settingname="`basename -- "${i}"`"
      srcfile="${directory}/.bootstrap/${settingname}"

      if [ -d "${srcfile}" ]
      then
         continue
      fi

      localfile="${BOOTSTRAP_SUBDIR}.local/${settingname}"

      if [ -e "${localfile}" ]
      then
         log_verbose "Setting \"${settingname}\" is locally specified, so not merged"
         continue
      fi

      match="`echo "${NON_MERGABLE_SETTINGS}" | fgrep -x "${settingname}"`"
      if [ ! -z "${match}" ]
      then
         log_fluff "Setting \"${settingname}\" is not mergable"
         continue
      fi

      dstfile="${BOOTSTRAP_SUBDIR}.auto/${settingname}"
      if [ -f "${dstfile}" ]
      then
         tmpfile="${BOOTSTRAP_SUBDIR}.auto/${settingname}.tmp"

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


bootstrap_auto_copy_public_settings()
{
   local name
   local directory

   name="$1"
   directory="$2"

   local srcdir
   local dstdir

   srcdir="${directory}/.bootstrap/public_settings"
   dstdir="${BOOTSTRAP_SUBDIR}.auto/${name}"

   if dir_has_files "${srcdir}"
   then
      exekutor cp -Ra "${srcdir}/" "${dstdir}/"
   fi
}


bootstrap_auto_update_repo_settings()
{
   local directory

   directory="$1"

   local srcdir
   local dstdir
   local reponame

   srcdir="${directory}/.bootstrap"
   dstdir="${BOOTSTRAP_SUBDIR}.auto"

   mkdir_if_missing "${dstdir}"

   #
   # copy repo settings flat if not present already
   #
   for i in `find "${srcdir}" -mindepth 1 -maxdepth 1 -type d -print 2> /dev/null`
   do
      reponame="`basename -- "${i}"`"

      case "${reponame}" in
         bin|config|settings)
            continue
         ;;
      esac

      if [ -d "${dstdir}/${reponame}" ]
      then
         log_verbose "Settings for \"${reponame}\" are already present, so skipped"
         continue
      fi

      exekutor cp -Ra "${i}" ${dstdir}/${reponame}""
   done

   rmdir_if_empty "${dstdir}"
}


#
# return 0, if something changed
#
bootstrap_auto_update()
{
   local name
   local url
   local directory

   name="$1"
   url="$2"
   directory="$3"

   [ -z "${directory}" ]         && internal_fail "src was empty"
   [ "${PWD}" = "${directory}" ] && internal_fail "configuration error"

   if [ "$MULLE_BOOTSTRAP_TRACE_MERGE" = "YES" ]
   then
      log_trace2 "bootstrap.auto: ${name}"
   fi

   # contains own bootstrap ? and not a symlink
   if [ ! -d "${directory}/.bootstrap" ] # -a ! -L "${dst}" ]
   then
      log_fluff "No .bootstrap folder in \"${directory}\" found"
      return 1
   fi

   log_verbose "Updating .bootstrap.auto with ${directory}"

   log_fluff "Acquiring \"${name}\" merge settings"
   bootstrap_auto_update_merge "${directory}"

   log_fluff "Acquiring \"${name}\" public settings"
   bootstrap_auto_copy_public_settings "${name}" "${directory}"

   log_fluff "Acquiring \"${name}\" repo settings"
   bootstrap_auto_update_repo_settings "${directory}"

   log_fluff "Acquisiton of \"${name}\" complete"
   return 0
}

#
# copy contents of .bootstrap.local to .bootstrap.auto
# them add contents of .bootstrap to .bootstrap.auto, if not present
#
bootstrap_auto_create()
{
   log_verbose "Creating .bootstrap.auto from .bootstrap and .bootstrap.local"

   mkdir_if_missing "${BOOTSTRAP_SUBDIR}.auto"

   if dir_has_files "${BOOTSTRAP_SUBDIR}.local"
   then
      exekutor cp -Ra "${BOOTSTRAP_SUBDIR}.local/" "${BOOTSTRAP_SUBDIR}.auto/"
   fi

   #
   # add stuff from bootstrap folder
   # don't copy config if exists (it could be malicious)
   # don't copy settings (must be duplicated by inheritor)
   #
   local file
   local name

   IFS="
"
   for file in `ls -1 "${BOOTSTRAP_SUBDIR}"`
   do
      IFS="${DEFAULT_IFS}"
      name="`basename -- "${file}"`"

      case "$name" in
         config|settings)
            continue
         ;;

         public_settings)
            exekutor cp -Ran "${BOOTSTRAP_SUBDIR}/public_settings/" "${BOOTSTRAP_SUBDIR}.auto/settings"
         ;;

         *)
            exekutor cp -Ran "${BOOTSTRAP_SUBDIR}/${name}" "${BOOTSTRAP_SUBDIR}.auto/"
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"
}


auto_update_initialize()
{
    log_fluff ":auto_update_initialize:"

  NON_MERGABLE_SETTINGS='embedded_repositories
'
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
}

auto_update_initialize
