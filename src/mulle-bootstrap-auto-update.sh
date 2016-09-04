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
   local old
   local i

   old="${IFS:-' '}"
   IFS="
"
   for i in `ls -1 "${directory}/.bootstrap"`
   do
      IFS="${old}"

      settingname="`basename -- "${i}"`"
      srcfile="${directory}/.bootstrap/${settingname}"
      dstfile="${BOOTSTRAP_SUBDIR}.auto/${settingname}"
      localfile="${BOOTSTRAP_SUBDIR}.local/${settingname}"

      if [ -e "${localfile}" ]
      then
         log_verbose "Setting \"${settingname}\" is locally specified, so not merged"
         continue
      fi

      if [ -d "${srcfile}" ]
      then
         continue
      fi

      match="`echo "$NON_MERGABLE_SETTINGS" | grep "${settingname}"`"
      if [ ! -z "${match}" ]
      then
         continue
      fi

      log_verbose "Inheriting \"${settingname}\" from \"${srcfile}\""

      if [ -f "${dstfile}" ]
      then
         tmpfile="${BOOTSTRAP_SUBDIR}.auto/${settingname}.tmp"

         exekutor mv "${dstfile}" "${tmpfile}" || exit 1
         exekutor merge_settings_in_front "${srcfile}" "${tmpfile}" > "${dstfile}"  || exit 1
         exekutor rm "${tmpfile}" || exit 1
      else
         exekutor cp "${srcfile}" "${dstfile}" || exit 1
      fi
   done
   IFS="${old}"
}


bootstrap_auto_copy_files()
{
   local srcdir
   local dstdir

   srcdir="$1"
   dstdir="$2"

   local path
   local filename

    # copy settings
   for path in `find "${srcdir}" -mindepth 1 -maxdepth 1 -type f -print 2> /dev/null`
   do
      filename="`basename -- "${path}"`"

      if [ -f "${dstdir}/${filename}" ]
      then
         log_verbose "\"${filename}\" is already present, so not inherited"
         continue
      fi

      exekutor cp -a "${path}" "${dstdir}/"
   done
}


#
# copy up other non-mergable settings, if there aren't already settings there
#
bootstrap_auto_update_settings()
{
   local name
   local directory

   directory="$1"
   name="$2"

   local srcdir
   local settingname
   local script
   local dstdir
   local i
   local is_merge

   srcdir="${directory}/.bootstrap/settings"
   dstdir="${BOOTSTRAP_SUBDIR}.auto/settings/${name}"

   mkdir_if_missing "${dstdir}" 

   bootstrap_auto_copy_files  "${srcdir}" "${dstdir}"

   # copy scripts

   srcdir="${srcdir}/bin"
   dstdir="${dstdir}/bin"

   mkdir_if_missing "${dstdir}" 
   bootstrap_auto_copy_files  "${srcdir}" "${dstdir}"

   rmdir_if_empty "${dstdir}/bin"

   rmdir_if_empty "${dstdir}" 
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

      log_fluff  "Copy \"${i}\" to \"${dstdir}\""
      exekutor cp -Ra "${i}" ${dstdir}/${reponame}""
   done

   rmdir_if_empty "${dstdir}" 
}


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

   log_fluff "Acquiring \"${name}\" build settings"
   bootstrap_auto_update_settings "${directory}" "${name}"

   log_fluff "Acquiring \"${name}\" repo settings"
   bootstrap_auto_update_repo_settings "${directory}"

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
      exekutor cp -Ra "${BOOTSTRAP_SUBDIR}.local/"* "${BOOTSTRAP_SUBDIR}.auto/"
   fi

   #
   # add stuff from bootstrap folder
   # don't copy config/ if exists (it could be malicious)
   #
   local old
   local file

   old="${IFS}"
   IFS="
"
   for file in `ls -1 "${BOOTSTRAP_SUBDIR}"`
   do
      name="`basename -- "${file}"`"
      case "$name" in
         config)
            continue
         ;;

         *)
            exekutor cp -Ran "${BOOTSTRAP_SUBDIR}/${name}" "${BOOTSTRAP_SUBDIR}.auto/${name}"
         ;;
      esac
   done

   IFS="${old}"
}


auto_update_initialize()
{
    log_fluff ":auto_update_initialize:"

  NON_MERGABLE_SETTINGS='embedded_repositories
'   
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh && functions_initialize
}
