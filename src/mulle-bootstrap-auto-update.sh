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
# This function is called initially to setup .bootstrap.auto before
# doing anything else. It is clear that .bootstrap.auto does not exist
#
# copy contents of .bootstrap.local to .bootstrap.auto
# them add contents of .bootstrap to .bootstrap.auto, if not present
#
bootstrap_auto_create()
{
   [ -z "${BOOTSTRAP_DIR}" ] && internal_fail "empty bootstrap"

   log_fluff "Creating ${BOOTSTRAP_DIR}.auto from ${BOOTSTRAP_DIR}"

   assert_mulle_bootstrap_version

   rmdir_safer "${BOOTSTRAP_DIR}.auto"
   mkdir_if_missing "${BOOTSTRAP_DIR}.auto"

   #
   # Copy over .local verbatim
   #
   if dir_has_files "${BOOTSTRAP_DIR}.local"
   then
      exekutor cp -Ra ${COPYMOVEFLAGS} "${BOOTSTRAP_DIR}.local/" "${BOOTSTRAP_DIR}.auto/" >&2
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

         *.build|settings|overrides)
            if [ -d "${BOOTSTRAP_DIR}/${name}" ]
            then
               inherit_files "${BOOTSTRAP_DIR}.auto/${name}" "${BOOTSTRAP_DIR}/${name}"
            fi
         ;;

         *)
            exekutor cp -Ran ${COPYMOVEFLAGS}  "${BOOTSTRAP_DIR}/${name}" "${BOOTSTRAP_DIR}.auto/" >&2
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"
}



_bootstrap_auto_refresh_repository_file()
{
   local clones
   local stop
   local refreshed
   local match
   local dependency_map
   local unexpanded

   [ -z "${MULLE_BOOTSTRAP_DEPENDENY_RESOLVE_SH}" ] && . mulle-bootstrap-dependency-resolve.sh

   refreshed=""
   dependency_map=""

   clones="`read_root_setting "repositories"`"
   if [ -z "${clones}" ]
   then
      return
   fi

   IFS="
"
   for unexpanded in ${clones}
   do
      IFS="${DEFAULT_IFS}"

      # cat for -e
      match="`echo "${refreshed}" | fgrep -s -x "${unexpanded}"`"
      if [ ! -z "${match}" ]
      then
         continue
      fi

      refreshed="${refreshed}
${unexpanded}"

      if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" -o "$MULLE_BOOTSTRAP_TRACE_MERGE" = "YES"  ]
      then
         log_trace2 "Dealing with ${unexpanded}"
      fi

      # avoid superflous updates

      local branch
      local stashdir
      local name
      local scm
      local tag
      local url
      local clone
      local dstdir

      clone="`expanded_variables "${unexpanded}"`"
      parse_clone "${clone}"

      dependency_map="`dependency_add "${dependency_map}" "__ROOT__" "${unexpanded}"`"

      #
      # dependency management, it could be nicer, but isn't.
      # Currently matches only URLs
      #

      if [ ! -d "${stashdir}" ]
      then
         if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" -o "$MULLE_BOOTSTRAP_TRACE_MERGE" = "YES"  ]
         then
            log_trace2 "${stashdir} not fetched yet"
         fi
         continue
      fi

      local sub_repos
      local filename

      filename="${stashdir}/.bootstrap/repositories"
      sub_repos="`read_setting "${filename}" "repositories"`"
      if [ ! -z "${sub_repos}" ]
      then
#                  unexpanded_url="`url_from_clone "${unexpanded}"`"
         dependency_map="`dependency_add_array "${dependency_map}" "${unexpanded}" "${sub_repos}"`"
         if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" -o "$MULLE_BOOTSTRAP_TRACE_MERGE" = "YES"  ]
         then
            log_trace2 "add \"${unexpanded}\" to __ROOT__ as dependencies"
            log_trace2 "add [ ${sub_repos} ] to ${unexpanded} as dependencies"
         fi
      else
         log_fluff "${name} has no repositories"
      fi
   done

   IFS="${DEFAULT_IFS}"

   #
   # output true repository dependencies
   #
   local repositories

   repositories="`dependency_resolve "${dependency_map}" "__ROOT__" | fgrep -v -x "__ROOT__"`"
   if [ ! -z "${repositories}" ]
   then
      if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" -o "$MULLE_BOOTSTRAP_TRACE_MERGE" = "YES"  ]
      then
         log_trace2 "----------------------"
         log_trace2 "resolved dependencies:"
         log_trace2 "----------------------"
         log_trace2 "${repositories}"
         log_trace2 "----------------------"
      fi
      echo "${repositories}" > "${BOOTSTRAP_DIR}.auto/repositories"
   fi
}

#
# prepend new contents to old contents
# of a few select and known files, these are merged with whats there
# `BOOTSTRAP_DIR` is the "root" bootstrap to update
# `directory` can be the inferior bootstrap of a fetched repository
#
_bootstrap_auto_merge_root_settings()
{
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

      # cat is for -e
      match="`echo "${NON_MERGABLE_SETTINGS}" | fgrep -s -x "${settingname}"`"
      if [ ! -z "${match}" ]
      then
         log_fluff "Setting \"${settingname}\" is not mergable, so ignored"
         continue
      fi

      # cat is for -e
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

         exekutor mv ${COPYMOVEFLAGS}  "${dstfile}" "${tmpfile}" >&2 || exit 1
         redirect_exekutor "${dstfile}" exekutor merge_settings_in_front "${srcfile}" "${tmpfile}"  || exit 1
         exekutor rm ${COPYMOVEFLAGS}  "${tmpfile}" >&2 || exit 1
      else
         log_fluff "Copying \"${settingname}\" from \"${srcfile}\""

         exekutor cp ${COPYMOVEFLAGS}  "${srcfile}" "${dstfile}" >&2 || exit 1
      fi
   done

   IFS="${DEFAULT_IFS}"
}


bootstrap_auto_update()
{
   local directory

   log_fluff ":bootstrap_auto_update: begin"
   directory="$1"

   if [ -d "${directory}/${BOOTSTRAP_DIR}" ]
   then
      _bootstrap_auto_merge_root_settings "${directory}"
      _bootstrap_auto_refresh_repository_file "${directory}"
   fi
   log_fluff ":bootstrap_auto_update: end"
}


bootstrap_create_build_folders()
{
   #
   # now pick up on build order and produce .build folders
   # but build order could be "hand coded", lets use it
   #
   local revclonenames
   local clonenames
   local srcdir
   local dstdir

   local has_settings
   local has_overrides

   [ -d "${BOOTSTRAP_DIR}.auto/settings" ]
   has_settings=$?

   [ -d "${BOOTSTRAP_DIR}.auto/overrides" ]
   has_overrides=$?

   clonenames="`read_root_setting "build_order"`"
   revclonenames="`echo "${clonenames}" | sed '1!G;h;$!d'`"  # reverse lines

   local tmp
   local apath
   local name
   local revname

   #
   # small optimization,
   # throw out revclones  that have no .bootstrap folder
   #

   tmp="${revclonenames}"
   revclonenames=""

   IFS="
"
   for revname in ${tmp}
   do
      IFS="${DEFAULT_IFS}"

      apath="`stash_of_repository "${REPOS_DIR}" "${revname}"`/.bootstrap"
      if [ -d "${apath}" ]
      then
         revclonenames="`add_line "${revclonenames}" "${revname}"`"
      fi
   done

   IFS="
"
   for name in ${clonenames}
   do
      IFS="${DEFAULT_IFS}"

      dstdir="${BOOTSTRAP_DIR}.auto/${name}.build"
      if [ ${has_settings} -eq 0 ]
      then
         inherit_files "${dstdir}" "${BOOTSTRAP_DIR}.auto/settings"
      fi

      if [ "`read_build_setting "${name}" "final" "NO"`" = "YES" ]
      then
         break
      fi

      IFS="
"
      for revname in ${revclonenames}
      do
         IFS="${DEFAULT_IFS}"

         srcdir="`stash_of_repository "${REPOS_DIR}" "${revname}"`/.bootstrap/${name}.build"

         if [ -d "${srcdir}" ]
         then
            inherit_files "${dstdir}" "${srcdir}"
            if [ "`read_build_setting "${name}" "final" "NO"`" = "YES" ]
            then
               break
            fi
         fi

         if [ "${revname}" = "${name}" ]
         then
            break
         fi

      done

      if [ ${has_overrides} -eq 0 ]
      then
         override_files "${dstdir}" "${BOOTSTRAP_DIR}.auto/overrides"
      fi
   done

   IFS="${DEFAULT_IFS}"
}


bootstrap_auto_final()
{
   [ -d "${BOOTSTRAP_DIR}.auto" ] || internal_fail "${BOOTSTRAP_DIR}.auto does not exists"

   log_fluff "Creating ${C_MAGENTA}${C_BOLD}build_order${C_VERBOSE} from repositories"

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
   for clone in `read_root_setting "repositories"`
   do
      IFS="${DEFAULT_IFS}"

      parse_clone "${clone}"
      order="`add_line "${order}" "${name}"`"
   done

   IFS="${DEFAULT_IFS}"

   echo "${order}" > "${BOOTSTRAP_DIR}.auto/build_order"

   bootstrap_create_build_folders
}


auto_update_initialize()
{
   log_fluff ":auto_update_initialize:"

   MERGABLE_SETTINGS='brews
tarballs
repositories
'

   NON_MERGABLE_SETTINGS='embedded_repositories
version
'
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_COPY_SH}" ] && . mulle-bootstrap-copy.sh
   :
}

auto_update_initialize
