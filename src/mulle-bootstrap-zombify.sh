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
MULLE_BOOTSTRAP_ZOMBIFY_SH="included"


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


# ----------------

#
# used to do this with chmod -h, alas Linux can't do that
# So we create a special directory .zombies
# and create files there
#
#
# ###
#
_zombify_stashes()
{
   local reposdir

   reposdir="$1"

   [ -z "${reposdir}" ] && internal_fail "reposdir"

   local zombiepath

   # first mark all repos as stale

   if dir_has_files "${reposdir}"
   then
      zombiepath="${reposdir}/.zombies"
      mkdir_if_missing "${zombiepath}"

      exekutor cp ${COPYMOVEFLAGS} "${reposdir}/"* "${zombiepath}/" >&2
   fi
}


mark_stash_as_alive()
{
   local reposdir

   reposdir="$1"
   name="$2"

   [ $# -eq 2 ] || internal_fail "parameter error"

   zombie="${reposdir}/.zombies/${name}"
   if [ -e "${zombie}" ]
   then
      log_fluff "Marking \"${name}\" as alive"

      exekutor rm -f ${COPYMOVEFLAGS} "${zombie}" >&2 || fail "failed to delete zombie ${zombie}"
   else
      log_fluff "Marked \"${name}\" is already alive (`absolutepath "${zombie}"` not present)"
   fi
}


mark_all_stashes_as_alive()
{
   local reposdir

   reposdir="$1"

   local zombiedir

   zombiedir="${reposdir}/.zombies"

   if dir_has_files "${zombiedir}"
   then
      log_fluff "Marking all stashes of \"${reposdir}\" as alive"
      exekutor rm -f ${COPYMOVEFLAGS} "${zombiedir}/"* >&2 || fail "failed to delete zombie ${zombie}"
   fi
}


#
#
#
_bury_zombies()
{
   local reposdir

   reposdir="$1"

   [ -z "${reposdir}" ] && internal_fail "reposdir"

   local i
   local name
   local stashdir
   local zombiepath
   local gravepath

   zombiepath="${reposdir}/.zombies"

   if dir_has_files "${zombiepath}"
   then
      log_fluff "Moving zombies into graveyard"

      gravepath="${reposdir}/.graveyard"
      mkdir_if_missing "${gravepath}"

      for i in `ls -1 "${zombiepath}/"* 2> /dev/null`
      do
         if [ -f "${i}" ]
         then
            name="`basename -- "${i}"`"
            stashdir="`_stash_of_reposdir_file "${reposdir}/${name}"`"

            if [ -L "${stashdir}"  ]
            then
               log_info "Removing unused symlink ${C_MAGENTA}${C_BOLD}${stashdir}${C_INFO}"
               exekutor rm ${COPYMOVEFLAGS}  "${stashdir}" >&2
               continue
            fi

            if [ -d "${stashdir}" ]
            then
               if [ -e "${gravepath}/${name}" ]
               then
                  log_fluff "Repurposing old grave \"${gravepath}/${name}\""
                  exekutor rm -rf ${COPYMOVEFLAGS}  "${gravepath}/${name}" >&2
               fi

               log_info "Removing unused repository ${C_MAGENTA}${C_BOLD}${name}${C_INFO} (\"${stashdir}\")"

               exekutor mv ${COPYMOVEFLAGS} "${stashdir}" "${gravepath}/" >&2
               exekutor rm ${COPYMOVEFLAGS} "${i}" >&2
               exekutor rm ${COPYMOVEFLAGS} "${reposdir}/${name}" >&2

            else
               log_fluff "Zombie \"${stashdir}\" vanished or never existed ($PWD)"
            fi
         fi
      done
   fi

   if [ -d "${zombiepath}" ]
   then
      exekutor rm -rf ${COPYMOVEFLAGS} "${zombiepath}" >&2
   fi
}


#
#
#
zombify_embedded_repository_stashes()
{
   log_fluff "Marking all embedded repositories as zombies for now"

   _zombify_stashes "${REPOS_DIR}/.embedded"
}


zombify_repository_stashes()
{
   log_fluff "Marking all repositories as zombies for now"

   _zombify_stashes "${REPOS_DIR}"
}


zombify_deep_embedded_repository_stashes()
{
   local stashes
   local stash

   log_fluff "Marking all deep embedded repositories as zombies for now"

   IFS="
"
   stashes="`all_repository_stashes "${REPOS_DIR}"`"
   for stash in ${stashes}
   do
      IFS="${DEFAULT_IFS}"

      (
         cd "${stash}" &&
         _zombify_stashes "${REPOS_DIR}/.embedded"
      ) || fail "failed to mark stashes"
   done

   IFS="${DEFAULT_IFS}"
}


#
#
#
bury_embedded_repository_zombies()
{
   log_fluff "Burying embedded zombie repositories"

   _bury_zombies "${REPOS_DIR}/.embedded"
}


bury_repository_zombies()
{
   log_fluff "Burying zombie repositories"

   _bury_zombies "${REPOS_DIR}"
}


bury_deep_embedded_repository_zombies()
{
   local stashes
   local stash

   log_fluff "Burying deep embedded zombie repositories"

   IFS="
"
   stashes="`all_repository_stashes "${REPOS_DIR}"`"
   for stash in ${stashes}
   do
      IFS="${DEFAULT_IFS}"

      (
         cd "${stash}" &&
         _bury_zombies "${REPOS_DIR}/.embedded"
      ) || fail "failed to bury zombies"
   done

   IFS="${DEFAULT_IFS}"
}

