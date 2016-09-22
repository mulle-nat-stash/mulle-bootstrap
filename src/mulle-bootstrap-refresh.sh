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
MULLE_BOOTSTRAP_REFRESH_SH="included"

#
# this script installs the proper git clones into "clones"
# it does not to git subprojects.
# You can also specify a list of "brew" dependencies. That
# will be third party libraries, you don't tag or debug
#

refresh_usage()
{
   cat <<EOF >&2
usage:
   mulle-bootstrap <refresh|nonrecursive>

   refresh      : update settings, remove unused repositories (default)
   nonrecursive : ignore .bootstrap folders of fetched repositories
EOF
   exit 1
}


refresh_repositories_settings()
{
   local stop
   local clones
   local clone
   local old
   local stop
   local refreshed
   local match
   local dependency_map

   old="${IFS:-" "}"

   refreshed=""
   dependency_map=""

   stop=0
   while [ $stop -eq 0 ]
   do
      stop=1

      clones="`read_fetch_setting "repositories"`"
      if [ "${clones}" != "" ]
      then
         IFS="
"
         for clone in ${clones}
         do
            IFS="${old}"

            clone="`expanded_setting "${clone}"`"
            # avoid superflous updates
            match="`echo "${refreshed}" | grep -x "${clone}"`"
            # could remove prefixes here https:// http://

            if [ "${match}" != "${clone}" ]
            then
               refreshed="${refreshed}
${clone}"

               local branch
               local dstdir
               local flag
               local name
               local scm
               local tag
               local url

               __parse_expanded_clone "${clone}"

               dstdir="${CLONESFETCH_SUBDIR}/${name}"
               if [ ! -d "${dstdir}" ]
               then
                  log_fluff "${name} has not been fetched yet"
                  continue
               fi

               #
               # dependency management, it could be nicer, but isn't.
               # Currently matches only URLs
               #
               local sub_repos
               local filename

               filename="${dstdir}/${BOOTSTRAP_SUBDIR}/repositories"
               if [ -f "${filename}" ]
               then
                  sub_repos="`_read_setting "${filename}"`"
                  if [ ! -z "${sub_repos}" ]
                  then
                     dependency_map="`dependency_add "${dependency_map}" "__ROOT__" "${url}"`"
                     dependency_map="`dependency_add_array "${dependency_map}" "${url}" "${sub_repos}"`"
                     if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" -o "$MULLE_BOOTSTRAP_TRACE_MERGE" = "YES"  ]
                     then
                        log_trace2 "add \"${sub_repos}\" for ${url} to ${dependency_map}"
                     fi
                  fi
               else
                  log_fluff "${name} has no repositories"
               fi

               bootstrap_auto_update "${name}" "${url}" "${dstdir}"
               flag=$?

               if [ $flag -eq 0 ]
               then
                  stop=0
               fi
            fi
         done
      fi
   done

   IFS="${old}"

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
      echo "${repositories}" > "${BOOTSTRAP_SUBDIR}.auto/repositories"
   fi
}


# ----------------

#
# used to do this with chmod -h, alas Linux can't do that
# So we create a special directory .zombies
# and create files there
#
mark_all_repositories_zombies()
{
   local i
   local name

      # first mark all repos as stale
   if dir_has_files "${CLONESFETCH_SUBDIR}"
   then
      log_fluff "Marking all repositories as zombies for now"

      mkdir_if_missing "${CLONESFETCH_SUBDIR}/.zombies"

      for i in `ls -1d "${CLONESFETCH_SUBDIR}/"*`
      do
         if [ -d "${i}" -o -L "${i}" ]
         then
            name="`basename -- "${i}"`"
            exekutor touch "${CLONESFETCH_SUBDIR}/.zombies/${name}"
         fi
      done
   fi
}


_mark_repository_alive()
{
   local dstdir
   local name
   local zombie

   name="$1"
   dstdir="$2"
   zombie="$3"

   # mark as alive
   if [ -d "${dstdir}" -o -L "${dstdir}" ]
   then
      if [ -e "${zombie}" ]
      then
         log_fluff "Mark \"${dstdir}\" as alive"

         exekutor rm -f "${zombie}" || fail "failed to delete zombie ${zombie}"
      else
         log_fluff "Marked \"${dstdir}\" is already alive"
      fi
   else
      if [ -e "${dstdir}" ]
      then
         log_fail "\"${dstdir}\" is neither a symlink nor a directory"
      fi

      # repository should be there but hasn't been fetched yet
      # so not really a zmbie
      if [ -e "${zombie}" ]
      then
         log_fluff "\"${dstdir}\" is not there, so not a zombie"

         exekutor rm -f "${zombie}" || fail "failed to delete zombie ${zombie}"
      fi
   fi
}


mark_repository_alive()
{
   local dstdir
   local name

   name="$1"
   dstdir="$2"

   local zombie

   zombie="`dirname -- "${dstdir}"`/.zombies/${name}"

   _mark_repository_alive "${name}" "${dstdir}" "${zombie}"
}


bury_zombies()
{
   local i
   local name
   local dstdir
   local zombiepath
   local gravepath

      # first mark all repos as stale
   zombiepath="${CLONESFETCH_SUBDIR}/.zombies"
   if dir_has_files "${zombiepath}"
   then
      log_fluff "Burying zombies into graveyard"

      gravepath="${CLONESFETCH_SUBDIR}/.graveyard"
      mkdir_if_missing "${gravepath}"

      for i in `ls -1 "${zombiepath}/"* 2> /dev/null`
      do
         if [ -e "${i}" ]
         then
            name="`basename -- "${i}"`"
            dstdir="${CLONESFETCH_SUBDIR}/${name}"
            if [ -d "${dstdir}" ]
            then
               log_info "Removing unused repository ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from \"`pwd`/${dstdir}\""

               if [ -e "${gravepath}/${name}" ]
               then
                  exekutor rm -rf "${gravepath}/${name}"
                  log_fluff "Made room for a new grave at \"${gravepath}/${name}\""
               fi

               exekutor mv "${dstdir}" "${gravepath}"
               exekutor rm "${i}"
            else
               log_fluff "\"${dstdir}\" zombie vanished or never existed"
            fi
         fi
      done
   fi

   if [ -d "${zombiepath}" ]
   then
      exekutor rm -rf "${zombiepath}"
   fi
}


#
# ###
#
mark_all_embedded_repositories_zombies()
{
   local i
   local name
   local symlink
   local path
   local zombiepath

   # first mark all repos as stale
   path="${CLONESFETCH_SUBDIR}/.embedded"
   if dir_has_files "${CLONESFETCH_SUBDIR}/.embedded"
   then
      log_fluff "Marking all embedded repositories as zombies for now"

      zombiepath="${CLONESFETCH_SUBDIR}/.embedded/.zombies"
      mkdir_if_missing "${zombiepath}"

      for symlink in `ls -1d "${path}/"*`
      do
         i="`head -1 "$symlink" 2>/dev/null`" || fail "Old style mulle-bootstrap files detected, \`mulle-bootstrap dist clean\` it ($PWD/$symlink)"
         name="`basename -- "${i}"`"
         exekutor cp "${symlink}" "${zombiepath}/${name}"
      done
   fi
}


mark_embedded_repository_alive()
{
   local dstdir
   local name

   name="$1"
   dstdir="$2"

   local zombie

   zombie="${CLONESFETCH_SUBDIR}/.embedded/.zombies/${name}"

   _mark_repository_alive "${name}" "${dstdir}" "${zombie}"
}


bury_embedded_zombies()
{
   local dstprefix

   dstprefix="$1"

   local i
   local name
   local dstdir
   local path
   local zombiepath
   local gravepath
   local path2

   # first mark all repos as stale
   zombiepath="${CLONESFETCH_SUBDIR}/.embedded/.zombies"

   if dir_has_files "${zombiepath}"
   then
      log_fluff "Burying embedded zombies into graveyard"

      gravepath="${CLONESFETCH_SUBDIR}/.embedded/.graveyard"
      mkdir_if_missing "${gravepath}"

      for i in `ls -1 "${zombiepath}/"* 2> /dev/null`
      do
         if [ -f "${i}" ]
         then
            log_info "CLONESFETCH_SUBDIR=${CLONESFETCH_SUBDIR}"
            log_info "pwd=${PWD}"
            log_info "i=${i}"
            dstdir="`embedded_repository_subdir_from_file "${i}" "${CLONESFETCH_SUBDIR}/.embedded"`"
            dstdir="${dstprefix}${dstdir}"
            log_info "dstdir=${dstdir}"

            if [ -d "${dstdir}" -o -L "${dstdir}" ]
            then
               name="`basename -- "${i}"`"

               if [ -e "${gravepath}/${name}" ]
               then
                  exekutor rm -rf "${gravepath}/${name}"
                  log_fluff "Made for a new grave at \"${gravepath}/${name}\""
               fi

               if [ -d "${dstdir}"  ]
               then
                  exekutor mv "${dstdir}" "${gravepath}"
               else
                  exekutor rm "${dstdir}"
               fi

               exekutor rm "${i}"
               exekutor rm "${CLONESFETCH_SUBDIR}/.embedded/${name}"
               log_info "Removed unused embedded repository ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from \"${dstdir}\""
            else
               log_fluff "Embedded zombie \"${dstdir}\" vanished or never existed ($PWD)"
            fi
         fi
      done
   fi

   if [ -d "${zombiepath}" ]
   then
      exekutor rm -rf "${zombiepath}"
   fi
}

#
# ###
#

refresh_repositories()
{
   local clone
   local clones
   local dstdir
   local old

   mark_all_repositories_zombies

   # local variables for __parse_clone
   local name
   local url
   local branch
   local scm
   local tag
   local subdir

   old="${IFS:-" "}"

   clones="`read_fetch_setting "repositories"`"
   if [ "${clones}" != "" ]
   then
      ensure_clones_directory

      IFS="
"
      for clone in ${clones}
      do
         IFS="${old}"

         __parse_clone "${clone}"

         dstdir="${CLONESFETCH_SUBDIR}/${name}"

         # if it's not there it's not fetched yet, that's OK
         mark_repository_alive "${name}" "${dstdir}"
      done
   fi

   IFS="${old}"

   bury_zombies
}


_refresh_embedded_repositories()
{
   local dstprefix

   dstprefix="$1"

   local clone
   local clones

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="YES"

   clones="`read_fetch_setting "embedded_repositories"`"
   if [ ! -z "${clones}" ]
   then

      local old

      old="${IFS:-" "}"
      IFS="
"
      # local variables for __parse_embedded_clone
      local name
      local url
      local branch
      local scm
      local tag
      local subdir

      local dstdir
      local olddir

      for clone in ${clones}
      do
         IFS="${old}"

         ensure_clones_directory

         __parse_embedded_clone "${clone}"

         olddir="`find_embedded_repository_subdir_in_repos "${url}"`"
         if [ ! -z "${olddir}" ]
         then
            if [ "${subdir}" != "${olddir}" ]
            then
               if [ -z "${MULLE_BOOTSTRAP_WILL_FETCH}" ]
               then
                  log_info "Embedded repository ${name} should move from ${olddir} to ${subdir}. A refetch is needed."
               fi
            else
               mark_embedded_repository_alive "${name}" "${dstprefix}${subdir}"
            fi
         fi
      done
   fi

   IFS="${old}"

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO=
}


refresh_embedded_repositories()
{
   mark_all_embedded_repositories_zombies

   _refresh_embedded_repositories "$@"

   bury_embedded_zombies "$@"
}


refresh_deeply_embedded_repositories()
{
   local branch
   local clone
   local clones
   local dstprefix
   local name
   local old
   local previous_bootstrap
   local previous_clones
   local scm
   local subdir
   local tag
   local url

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="YES"

   old="${IFS:-" "}"

   clones="`read_fetch_setting "repositories"`"
   if [ "${clones}" != "" ]
   then
      IFS="
"
      for clone in ${clones}
      do
         IFS="${old}"

         __parse_embedded_clone "${clone}"

         dstprefix="${CLONESFETCH_SUBDIR}/${subdir}/"

         if [ ! -L "${dstprefix}" ]
         then
            previous_bootstrap="${BOOTSTRAP_SUBDIR}"
            previous_clones="${CLONESFETCH_SUBDIR}"
            BOOTSTRAP_SUBDIR="${dstprefix}.bootstrap"
            CLONESFETCH_SUBDIR="${dstprefix}${CLONESFETCH_SUBDIR}"

            refresh_embedded_repositories "${dstprefix}"

            BOOTSTRAP_SUBDIR="${previous_bootstrap}"
            CLONESFETCH_SUBDIR="${previous_clones}"
         else
            log_warn  "Don't refresh embedded repositories of symlinked \"${name}\""
         fi
      done
   fi

   IFS="${old}"

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO=
}



# -------------------

refresh_main()
{
   log_fluff "::: refresh begin :::"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh
   [ -z "${MULLE_BOOTSTRAP_AUTO_UPDATE_SH}" ] && . mulle-bootstrap-auto-update.sh
   [ -z "${MULLE_BOOTSTRAP_DEPENDENCY_RESOLVE_SH}" ] && . mulle-bootstrap-dependency-resolve.sh
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ] && . mulle-bootstrap-repositories.sh

   while :
   do
      if [ "$1" = "-h" -o "$1" = "--help" ]
      then
         refresh_usage
      fi

      break
   done

   COMMAND=${1:-"refresh"}
   [ $# -eq 0 ] || shift

   case "$COMMAND" in
      refresh|clear|refresh_if_bare)
      ;;

      nonrecursive)
         DONT_RECURSE="YES"
      ;;

      *)
         log_error "Unknown command \"${COMMAND}\""
         refresh_usage
      ;;
   esac

   #
   # recreate .auto because it's contents are stale now
   #
   if [ -d "${BOOTSTRAP_SUBDIR}.auto" ]
   then
      if [ "${COMMAND}" = "refresh_if_bare" ]
      then
          return
      fi
      exekutor rm -rf "${BOOTSTRAP_SUBDIR}.auto"
   fi

   bootstrap_auto_create

   #
   # short cut if there are no .repos
   #
   if [ "${COMMAND}" != "clear" -a -d "${CLONESFETCH_SUBDIR}" ]
   then
      if [ "${DONT_RECURSE}" = "" ]
      then
         log_verbose "Refreshing repository settings"
         refresh_repositories_settings
      fi

      log_verbose "Detect zombie repositories"
      refresh_repositories

      log_verbose "Detect embedded zombie repositories"
      refresh_embedded_repositories

      if [ "${DONT_RECURSE}" = "" ]
      then
         log_verbose "Detect deeply embedded zombie repositories"
         refresh_deeply_embedded_repositories
      fi
   fi

   log_fluff "::: refresh end :::"
}

