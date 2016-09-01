#! /bin/sh
#
#   Copyright (c) 2016 Nat! - Mulle kybernetiK
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
#
MULLE_BOOTSTRAP_PROJECT_SH="included"

# tag this project, and all cloned dependencies
# the dependencies will get a different vendor tag
# based on the tag
#

[ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
[ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ] && . mulle-bootstrap-scripts.sh



project_usage()
{
   cat <<EOF >&2
usage:
   mulle-bootstrap project <clone|build|install> <options>

   clone   : clone a remote git repoistory and try to build something
   build   : execute ./build.sh, if missing do a mulle-bootstrap build
   install : execute ./install.sh, if missing execute ./build.sh install
EOF
   exit 1
}


main_project()
{
   local command

   if [ "$1" = "" -o "$1" = "-h" -o "$1" = "--help" ]
   then
      project_usage 
   fi

   command="$1"
   case  "${command}" in
      http:*|https:*)
         command="clone";
         ;;
      *)
         [ $# -eq 0 ] || shift
         ;;
   esac

   case  "${command}" in
   clone)
      set -e
      git clone "$1"
      cd "`basename "$1"`"
      mulle-bootstrap-fetch.sh || exit 1
      if [ -x "./build.sh" ]
      then
         ./build.sh
      else
         COMMAND="install" mulle-bootstrap-build.sh || exit 1
      fi
      ;;

   build)
      if [ -x "./build.sh" ]
      then
         ./build.sh
      fi
      ;;

   install)
      if [ -x "./install.sh" ]
      then
         ./install.sh
      else
         if [ -x "./build.sh" ]
         then
            ./build.sh install
         fi
      fi
      ;;

   *)
      log_error "unknown command \"${command}\""
      project_usage
      ;;

   esac
}

