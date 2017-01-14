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


# What refresh does:
#
# 1. remove .bootstrap.auto
# 2. recreate .bootstrap.auto (without .repos/<name>/.bootstrap)
# 3. augment .bootstrap.auto/repositories file with contents of
#     .repos/<name>/.bootstrap/repositories files
# 4. augment .bootstrap.auto with other contents of .repos/<name>/.bootstrap
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
   local reposdir

   reposdir="$1"

   [ $# -eq 1 ] || internal_fail "parameter error"

   local stop
   local clones
   local stop
   local refreshed
   local match
   local dependency_map
   local unexpanded
   local unexpanded_url

   refreshed=""
   dependency_map=""

   stop=0
   while [ $stop -eq 0 ]
   do
      stop=1

      clones="`read_fetch_setting "repositories"`"
      if [ ! -z "${clones}" ]
      then
         IFS="
"
         for unexpanded in ${clones}
         do
            IFS="${DEFAULT_IFS}"

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
            local dstdir
            local name
            local scm
            local tag
            local url
            local clone

            clone="`expanded_variables "${unexpanded}"`"
            __parse_expanded_clone "${clone}"

            dependency_map="`dependency_add "${dependency_map}" "__ROOT__" "${unexpanded}"`"

            dstdir="${reposdir}/${name}"
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

            filename="${dstdir}/.bootstrap.local/repositories"
            if [ ! -f "${filename}" ]
            then
               filename="${dstdir}/.bootstrap/repositories"
            fi

            if [ -f "${filename}" ]
            then
               sub_repos="`_read_setting "${filename}"`"
               if [ ! -z "${sub_repos}" ]
               then
#                  unexpanded_url="`url_from_clone "${unexpanded}"`"
                  dependency_map="`dependency_add_array "${dependency_map}" "${unexpanded}" "${sub_repos}"`"
                  if [ "$MULLE_BOOTSTRAP_TRACE_SETTINGS" = "YES" -o "$MULLE_BOOTSTRAP_TRACE_MERGE" = "YES"  ]
                  then
                     log_trace2 "add \"${unexpanded}\" to __ROOT__ as dependencies"
                     log_trace2 "add [ ${sub_repos} ] to ${unexpanded} as dependencies"
                  fi
               fi
            else
               log_fluff "${name} has no repositories"
            fi

            #
            # we always update the "root" repository
            #
            if bootstrap_auto_update "${name}" "${dstdir}"
            then
               stop=0
            fi
         done
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


# ----------------

#
# used to do this with chmod -h, alas Linux can't do that
# So we create a special directory .zombies
# and create files there
#
mark_all_repositories_zombies()
{
   local reposdir

   reposdir="$1"

   [ $# -eq 1 ] || internal_fail "parameter error"

   local i
   local name

      # first mark all repos as stale
   if dir_has_files "${reposdir}"
   then
      log_fluff "Marking all repositories as zombies for now"

      mkdir_if_missing "${reposdir}/.zombies"

      IFS="
"
      for i in `ls -1d "${reposdir}/"*`
      do
         IFS="${DEFAULT_IFS}"

         if [ -d "${i}" -o -L "${i}" ]
         then
            name="`basename -- "${i}"`"
            exekutor touch "${reposdir}/.zombies/${name}"
         fi
      done
      IFS="${DEFAULT_IFS}"
   fi
}


_mark_repository_alive()
{
   local reposdir
   local dstdir
   local name
   local zombie

   reposdir="$1"
   name="$2"
   dstdir="$3"
   zombie="$4"

   [ $# -eq 4 ] || internal_fail "parameter error"

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
         fail "\"${dstdir}\" is neither a symlink nor a directory (`pwd -P`)"
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
   local reposdir
   local dstdir
   local name

   reposdir="$1"
   name="$2"
   dstdir="$3"

   [ $# -eq 3 ] || internal_fail "parameter error"

   local zombie

   zombie="`dirname -- "${dstdir}"`/.zombies/${name}"

   _mark_repository_alive "${reposdir}" "${name}" "${dstdir}" "${zombie}"
}


bury_zombies()
{
   local reposdir

   reposdir="$1"

   [ $# -eq 1 ] || internal_fail "parameter error"

   local i
   local name
   local dstdir
   local zombiepath
   local gravepath

      # first mark all repos as stale
   zombiepath="${reposdir}/.zombies"
   if dir_has_files "${zombiepath}"
   then
      log_fluff "Burying zombies into graveyard"

      gravepath="${reposdir}/.bootstrap_graveyard"
      mkdir_if_missing "${gravepath}"

      IFS="
"
      for i in `ls -1 "${zombiepath}/"* 2> /dev/null`
      do
         IFS="${DEFAULT_IFS}"

         if [ ! -e "${i}" ]
         then
            continue
         fi

         name="`basename -- "${i}"`"
         dstdir="${reposdir}/${name}"
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
      done
      IFS="${DEFAULT_IFS}"
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
   local reposdir
   local dstprefix

   reposdir="$1"
   #dstprefix="$2"

   [ -z "${reposdir}" ] && internal_fail "reposdir"
   [ $# -le 2 ] || internal_fail "parameter error"

   local i
   local name
   local symlink
   local path
   local zombiepath

   # first mark all repos as stale
   path="${reposdir}/.bootstrap_embedded"
   if dir_has_files "${path}"
   then
      log_fluff "Marking all embedded repositories as zombies for now"

      zombiepath="${path}/.zombies"
      mkdir_if_missing "${zombiepath}"

      IFS="
"
      for symlink in `ls -1d "${path}/"*`
      do
         IFS="${DEFAULT_IFS}"

         i="`head -1 "$symlink" 2>/dev/null`" || fail "Old style mulle-bootstrap files"
         name="`basename -- "${i}"`"
         exekutor cp "${symlink}" "${zombiepath}/${name}"
      done
      IFS="${DEFAULT_IFS}"
   fi
}


mark_embedded_repository_alive()
{
   local reposdir
   local dstdir
   local name

   reposdir="$1"
   name="$2"
   dstdir="$3"

   [ -z "${reposdir}" ] && internal_fail "reposdir"
   [ $# -eq 3 ] || internal_fail "parameter error"

   local zombie

   zombie="${reposdir}/.bootstrap_embedded/.zombies/${name}"

   _mark_repository_alive "${reposdir}" "${name}" "${dstdir}" "${zombie}"
}


bury_embedded_zombies()
{
   local reposdir
   local dstprefix

   reposdir="$1"
   dstprefix="$2"

   [ -z "${reposdir}" ] && internal_fail "reposdir"
   [ $# -le 2 ] || internal_fail "parameter error"

   local i
   local name
   local dstdir
   local path
   local zombiepath
   local gravepath
   local path2

   # first mark all repos as stale
   zombiepath="${reposdir}/.bootstrap_embedded/.zombies"

   if dir_has_files "${zombiepath}"
   then
      log_fluff "Burying embedded zombies into graveyard"

      gravepath="${reposdir}/.bootstrap_embedded/.bootstrap_graveyard"
      mkdir_if_missing "${gravepath}"

      for i in `ls -1 "${zombiepath}/"* 2> /dev/null`
      do
         if [ -f "${i}" ]
         then
            dstdir="`embedded_repository_subdir_from_file "${i}"`"
            dstdir="${dstprefix}${dstdir}"

            if [ -L "${dstdir}" -a "${MULLE_BOOTSTRAP_UPDATE_SYMLINKS}" != "YES" ]
            then
               log_fluff "${dstdir} is symlinked, so ignored"
               continue
            fi

            if [ -d "${dstdir}" ]
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
               exekutor rm "${reposdir}/.bootstrap_embedded/${name}"
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
   local reposdir

   reposdir="$1"

   [ $# -eq 1 ] || internal_fail "parameter error"

   local clone
   local clones
   local dstdir

   mark_all_repositories_zombies "${reposdir}"

   # local variables for __parse_clone
   local name
   local url
   local branch
   local scm
   local tag
   local subdir

   clones="`read_fetch_setting "repositories"`"
   if [ "${clones}" != "" ]
   then
      ensure_clones_directory "${reposdir}"

      IFS="
"
      for clone in ${clones}
      do
         IFS="${DEFAULT_IFS}"

         __parse_clone "${clone}"

         dstdir="${reposdir}/${name}"

         # if it's not there it's not fetched yet, that's OK
         mark_repository_alive "${reposdir}" "${name}" "${dstdir}"
      done
      IFS="${DEFAULT_IFS}"
   fi

   bury_zombies "${reposdir}"
}


_refresh_embedded_repositories()
{
   local reposdir
   local dstprefix

   reposdir="$1"
   dstprefix="$2"

   [ $# -le 2 ] || internal_fail "parameter error"

   local clone
   local clones

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="YES"

   clones="`read_fetch_setting "embedded_repositories"`"
   if [ ! -z "${clones}" ]
   then
      # local variables for __parse_embedded_clone
      local name
      local url
      local branch
      local scm
      local tag
      local subdir

      local dstdir
      local olddir

      ensure_clones_directory "${reposdir}"

      IFS="
"
      for clone in ${clones}
      do
         IFS="${DEFAULT_IFS}"

         __parse_embedded_clone "${clone}"

         olddir="`find_embedded_repository_subdir_in_repos "${reposdir}" "${url}"`"
         if [ ! -z "${olddir}" ]
         then
            if [ "${subdir}" != "${olddir}" ]
            then
               if [ -z "${MULLE_BOOTSTRAP_WILL_FETCH}" ]
               then
                  log_info "Embedded repository ${name} should move from ${olddir} to ${subdir}. A refetch is needed."
               fi
            else
               mark_embedded_repository_alive "${reposdir}" "${name}" "${dstprefix}${subdir}"
            fi
         fi
      done
      IFS="${DEFAULT_IFS}"

   fi

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO=
}


refresh_embedded_repositories()
{
   mark_all_embedded_repositories_zombies "$@"

   _refresh_embedded_repositories "$@"

   bury_embedded_zombies "$@"
}


refresh_deeply_embedded_repositories()
{
   local reposdir

   reposdir="$1"

   [ -z "${reposdir}" ] && internal_fail "reposdir empty"
   [ $# -eq 1 ] || internal_fail "parameter error"

   local clone
   local clones
   local dstprefix
   local previous_bootstrap
   local previous_clones

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="YES"

   # __parse_embedded_clone
   local name
   local url
   local branch
   local scm
   local tag
   local subdir

   clones="`read_fetch_setting "repositories"`"
   if [ "${clones}" != "" ]
   then
      IFS="
"
      for clone in ${clones}
      do
         IFS="${DEFAULT_IFS}"

         __parse_embedded_clone "${clone}"

         if [ ! -L "${reposdir}/${subdir}" -o "${MULLE_BOOTSTRAP_UPDATE_SYMLINKS}" = "YES" ]
         then
            dstprefix="${reposdir}/${subdir}/"

            previous_bootstrap="${BOOTSTRAP_DIR}"
            BOOTSTRAP_DIR="${dstprefix}.bootstrap"

            refresh_embedded_repositories "${dstprefix}${reposdir}" "${dstprefix}"

            BOOTSTRAP_DIR="${previous_bootstrap}"
         else
            log_fluff "Don't refresh embedded repositories of symlinked \"${name}\""
         fi
      done
      IFS="${DEFAULT_IFS}"
   fi

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO=
}


# -------------------
# TODO: check that refresh actually changed something in repositoires or
#       embedded repositories and refetch as needed
refresh_main()
{
   log_fluff "::: refresh begin :::"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ]  && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]           && . mulle-bootstrap-settings.sh
   [ -z "${MULLE_BOOTSTRAP_AUTO_UPDATE_SH}" ]        && . mulle-bootstrap-auto-update.sh
   [ -z "${MULLE_BOOTSTRAP_DEPENDENCY_RESOLVE_SH}" ] && . mulle-bootstrap-dependency-resolve.sh
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ]       && . mulle-bootstrap-repositories.sh

   while :
   do
      case "$1" in
         -h*|--h*)
            refresh_usage
         ;;

         -us|--update-symlinks)
            MULLE_BOOTSTRAP_UPDATE_SYMLINKS="YES"
         ;;

         *)
            break
         ;;
      esac

      shift
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
   if [ -d "${BOOTSTRAP_DIR}.auto" ]
   then
      if [ "${COMMAND}" = "refresh_if_bare" ]
      then
          return
      fi
      exekutor rm -rf "${BOOTSTRAP_DIR}.auto"
   fi

   remove_file_if_present "${REPOS_DIR}/.bootstrap_refresh_done"

   bootstrap_auto_create

   #
   # short cut if there are no .repos
   #
   if [ "${COMMAND}" != "clear" -a -d "${REPOS_DIR}" ]
   then
      if [ "${DONT_RECURSE}" = "" ]
      then
         log_fluff "Refreshing repository settings"
         refresh_repositories_settings "${REPOS_DIR}"
      fi

      log_fluff "Detect zombie repositories"
      refresh_repositories "${REPOS_DIR}"

      log_fluff "Detect embedded zombie repositories"
      refresh_embedded_repositories "${REPOS_DIR}"

      if [ "${DONT_RECURSE}" = "" ]
      then
         log_fluff "Detect deeply embedded zombie repositories"
         refresh_deeply_embedded_repositories "${REPOS_DIR}"
      fi
   fi

   create_file_if_missing "${REPOS_DIR}/.bootstrap_refresh_done"

   log_fluff "::: refresh end :::"
}

