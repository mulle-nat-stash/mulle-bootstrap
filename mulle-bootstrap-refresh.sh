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
   install      : default, install settings into .bootstrap.auto
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

   old="${IFS:-" "}"

   clones="`read_fetch_setting "repositories"`"
   if [ "${clones}" != "" ]
   then
      IFS="
"
      for clone in ${clones}
      do
         IFS="${old}"

         local name
         local url
         local tag
         local dstdir

         name="`canonical_name_from_clone "${clone}"`"
         url="`url_from_clone "${clone}"`"
         tag="`read_repo_setting "${name}" "tag"`" #repo (sic)
         dstdir="${CLONES_FETCH_SUBDIR}/${name}"

         bootstrap_auto_update "${name}" "${url}" "${dstdir}" "$INHERIT_SETTINGS"
      done
   fi

   IFS="${old}"
}



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
      refresh_repositories_settings
   fi
}

main "$@"
