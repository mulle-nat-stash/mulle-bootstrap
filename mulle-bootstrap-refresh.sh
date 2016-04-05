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
# this script installs the proper git clones into "clones"
# it does not to git subprojects.
# You can also specify a list of "brew" dependencies. That
# will be third party libraries, you don't tag or debug
#
. mulle-bootstrap-local-environment.sh
. mulle-bootstrap-auto-update.sh


usage()
{
   cat <<EOF
usage: refresh <refresh|nonrecursive>
   refresh      : update settings, remove unused repositories (default)
   nonrecursive : ignore .bootstrap folders of fetched repositories
EOF
}


check_and_usage_and_help()
{
   case "$COMMAND" in
      nonrecursive)
        DONT_RECURSE="YES"
         ;;
      refresh)
         ;;
      *)
         usage >&2
         exit 1
         ;;
   esac
}


if [ "$1" = "-h" -o "$1" = "--help" ]
then
   COMMAND=help
else
   if [ -z "${COMMAND}" ]
   then
      COMMAND=${1:-"refresh"}
      [ $# -eq 0 ] || shift
   fi

   if [ "${MULLE_BOOTSTRAP}" = "mulle-bootstrap" ]
   then
      COMMAND="refresh"
   fi
fi


check_and_usage_and_help



refresh_repositories_settings()
{
   local stop
   local clones
   local clone
   local old
   local stop
   local refreshed
   local match

   old="${IFS:-" "}"

   refreshed=""

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

            # avoid superflous updates
            match="`echo "${refreshed}" | grep -x "${clone}"`"
            # could remove prefixes here https:// http://

            if [ "${match}" != "${clone}" ]
            then
               refreshed="${refreshed}
${clone}"

               local name
               local url
               local tag
               local dstdir
               local flag

               name="`canonical_name_from_clone "${clone}"`"
               url="`url_from_clone "${clone}"`"
               tag="`read_repo_setting "${name}" "tag"`" #repo (sic)
               dstdir="${CLONESFETCH_SUBDIR}/${name}"

               bootstrap_auto_update "${name}" "${url}" "${dstdir}"
               flag=$?

               if [ $flag -eq 0 ]
               then
                  stop=0
                  break
               fi
            fi
         done
      fi
   done

   IFS="${old}"
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


mark_repository_alive()
{
   local dstdir
   local name

   name="$1"
   dstdir="$2"

   local zombie

   zombie="`dirname -- "${dstdir}"`/.zombies/${name}"

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
      log_fluff "\"${dstdir}\" is neither a symlink nor a directory"
   fi
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

      for i in `ls -1 "${zombiepath}/"*`
      do
         if [ -e "${i}" ]
         then
            name="`basename -- "${i}"`"
            dstdir="${CLONESFETCH_SUBDIR}/${name}"
            if [ -d "${dstdir}" ]
            then
               log_info "Removing unused repository ${C_MAGENTA_BOLD}${name}${C_INFO}"

               if [ -e "${gravepath}/${name}" ]
               then
                  exekutor rm -rf "${gravepath}/${name}"
                  log_fluff "Made for a new grave at \"${gravepath}/${name}\""
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
         i="`readlink "$symlink"`"
         name="`basename "$i"`"
         exekutor touch "${zombiepath}/${name}"
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
      log_fluff "\"${dstdir}\" is neither a symlink nor a directory"
   fi
}


bury_embedded_zombies()
{
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

      for i in `ls -1 "${zombiepath}/"*`
      do
         if [ -f "${i}" ]
         then
            name="`basename -- "${i}"`"
            dstdir="${name}"
            log_info "Removing unused embedded repository ${C_MAGENTA_BOLD}${name}${C_INFO}"

            if [ -d "${dstdir}" ]
            then
               if [ -e "${gravepath}/${name}" ]
               then
                  exekutor rm -rf "${gravepath}/${name}"
                  log_fluff "Made for a new grave at \"${gravepath}/${name}\""
               fi
               exekutor mv "${dstdir}" "${gravepath}"
               exekutor rm "${i}"
               exekutor rm "${CLONESFETCH_SUBDIR}/.embedded/${name}"
            else
               log_fluff "\"${dstdir}\" embedded zombie vanished or never existed"
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
   local clones
   local clone
   local old
   local name
   local url
   local dstdir

   mark_all_repositories_zombies

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
         name="`canonical_name_from_clone "${clone}"`"
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

   local clones
   local clone
   local old
   local name
   local dstdir

   old="${IFS:-" "}"

   clones="`read_fetch_setting "embedded_repositories"`"
   if [ "${clones}" != "" ]
   then
      IFS="
"
      for clone in ${clones}
      do
         IFS="${old}"

         ensure_clones_directory

         name="`canonical_name_from_clone "${clone}"`"
         dstdir="${dstprefix}${name}"
         mark_embedded_repository_alive "${name}" "${dstdir}"
      done
   fi

   IFS="${old}"
}


refresh_embedded_repositories()
{
   mark_all_embedded_repositories_zombies

   _refresh_embedded_repositories "$@"

   bury_embedded_zombies
}


refresh_deeply_embedded_repositories()
{
   local clones
   local clone
   local old
   local name
   local url
   local dstprefix
   local previous_bootstrap
   local previous_clones

   old="${IFS:-" "}"

   clones="`read_fetch_setting "repositories"`"
   if [ "${clones}" != "" ]
   then
      IFS="
"
      for clone in ${clones}
      do
         IFS="${old}"
         name="`canonical_name_from_clone "${clone}"`"
         dstprefix="${CLONESFETCH_SUBDIR}/${name}/"

         previous_bootstrap="${BOOTSTRAP_SUBDIR}"
         previous_clones="${CLONESFETCH_SUBDIR}"
         BOOTSTRAP_SUBDIR="${dstprefix}.bootstrap"
         CLONESFETCH_SUBDIR="${dstprefix}${CLONESFETCH_SUBDIR}"

         refresh_embedded_repositories "${dstprefix}"

         BOOTSTRAP_SUBDIR="${previous_bootstrap}"
         CLONESFETCH_SUBDIR="${previous_clones}"
      done
   fi

   IFS="${old}"
}



# -------------------

main()
{
   log_fluff "::: refresh :::"

   #
   # remove .auto because it's contents are stale now
   #
   if [ -d "${BOOTSTRAP_SUBDIR}.auto" ]
   then
      exekutor rm -rf "${BOOTSTRAP_SUBDIR}.auto"
   fi

   if [ "${DONT_RECURSE}" = "" ]
   then
      log_fluff "Refreshing repository settings"
      refresh_repositories_settings
   fi

   log_fluff "Detect zombie repositories"
   refresh_repositories

   log_fluff "Detect embedded zombie repositories"
   refresh_embedded_repositories

   if [ "${DONT_RECURSE}" = "" ]
   then
      log_fluff "Detect deeply embedded zombie repositories"
      refresh_deeply_embedded_repositories
   fi
}

main "$@"
