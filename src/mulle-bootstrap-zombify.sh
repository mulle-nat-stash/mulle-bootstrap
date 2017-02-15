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

   zombiepath="${reposdir}/.zombies"
   rmdir_safer "${zombiepath}"

   if dir_has_files "${reposdir}"
   then
      mkdir_if_missing "${zombiepath}"

      exekutor cp ${COPYMOVETARFLAGS} "${reposdir}/"* "${zombiepath}/" >&2
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

      exekutor rm -f ${COPYMOVETARFLAGS} "${zombie}" >&2 || fail "failed to delete zombie ${zombie}"
   else
      log_fluff "\"${name}\" is alive as `absolutepath "${zombie}"` is not present"
   fi
}


#
#
#

_bury_stash()
{
   local reposdir="$1"
   local name="$2"
   local stashdir="$3"

   local gravepath

   gravepath="${reposdir}/.graveyard/${name}"

   if [ -e "${gravepath}" ]
   then
      log_fluff "Repurposing old grave \"${gravepath}\""
      exekutor rm -rf ${COPYMOVETARFLAGS}  "${gravepath}" >&2
   else
      mkdir_if_missing "${reposdir}/.graveyard"
   fi

   log_info "Burying \"${stashdir}\" in grave \"${gravepath}\""
   exekutor mv ${COPYMOVETARFLAGS} "${stashdir}" "${gravepath}" >&2
}


_bury_zombie()
{
   local reposdir="$1"
   local zombie="$2"

   local name
   local stashdir
   local gravepath

   name="`basename -- "${zombie}"`"
   stashdir="`_stash_of_reposdir_file "${reposdir}/${name}"`"

   if [ -L "${stashdir}"  ]
   then
      log_info "Removing unused symlink ${C_MAGENTA}${C_BOLD}${stashdir}${C_INFO}"
      exekutor rm ${COPYMOVETARFLAGS}  "${stashdir}" >&2
      return
   fi

   if [ -d "${stashdir}" ]
   then
      _bury_stash "${reposdir}" "${name}" "${stashdir}"

      exekutor rm ${COPYMOVETARFLAGS} "${zombie}" >&2
      exekutor rm ${COPYMOVETARFLAGS} "${reposdir}/${name}" >&2

   else
      log_fluff "Zombie \"${stashdir}\" vanished or never existed ($PWD)"
   fi
}


_bury_zombies()
{
   local reposdir="$1"

   [ -z "${reposdir}" ] && internal_fail "reposdir"

   local zombie
   local zombiepath

   zombiepath="${reposdir}/.zombies"

   if dir_has_files "${zombiepath}"
   then
      log_fluff "Moving zombies into graveyard"

      for zombie in `ls -1 "${zombiepath}/"* 2> /dev/null`
      do
         if [ -f "${zombie}" ]
         then
            _bury_zombie "${reposdir}" "${zombie}"
         fi
      done
   fi

   if [ -d "${zombiepath}" ]
   then
      exekutor rm -rf ${COPYMOVETARFLAGS} "${zombiepath}" >&2
   fi
}


#
#
#
zombify_embedded_repository_stashes()
{
   log_fluff "Marking all embedded repositories as zombies for now"

   _zombify_stashes "${EMBEDDED_REPOS_DIR}"
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
   local name

   log_fluff "Marking all deep embedded repositories as zombies for now"

   IFS="
"
   stashes="`all_repository_stashes "${REPOS_DIR}"`"
   for stash in ${stashes}
   do
      IFS="${DEFAULT_IFS}"

      name="`basename -- "${stash}"`"
      _zombify_stashes "${REPOS_DIR}/.deep/${name}.d"
   done

   IFS="${DEFAULT_IFS}"
}


#
#
#
bury_embedded_repository_zombies()
{
   log_fluff "Burying embedded zombie repositories"

   _bury_zombies "${EMBEDDED_REPOS_DIR}"
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

      name="`basename -- "${stash}"`"
      _bury_zombies "${REPOS_DIR}/.deep/${name}.d"
   done

   IFS="${DEFAULT_IFS}"
}

