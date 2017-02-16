#! /bin/sh
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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
MULLE_BOOTSTRAP_DEFER_SH="included"


emancipate_usage()
{
    cat <<EOF >&2
usage:
   mulle-bootstrap emancipate

   Emancipate from master. mulle-bootstrap will produce local builds again.
EOF
  exit 1
}


defer_usage()
{
    cat <<EOF >&2
usage:
   mulle-bootstrap defer <master>

   Share and defer builds to master. The master will be used
   to fetch dependencies and build them. Use mulle-bootstrap flags
   to get paths to addictions and dependencies.
EOF
  exit 1
}


defer_main()
{
   log_debug ":defer_main:"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            defer_usage
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown option $1"
            defer_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_BOOTSTRAP_PROJECT_SH}" ] && . mulle-bootstrap-project.sh

   unpostpone_trace

   local masterpath
   local minionpath

   minionpath="${PWD}"
   minionpath="`absolutepath "${minionpath}"`"

   if is_minion_bootstrap_project "${minionpath}"
   then
      masterpath="`get_master_of_minion_bootstrap_project "${minionpath}"`"
      [ ! -z "${masterpath}" ]  || internal_fail "is_minion file empty"
      log_info "Master \"${masterpath}\" already owns \"${minionpath}\""
      return
   fi

   masterpath="${1:-..}"
   masterpath="`absolutepath "${masterpath}"`"

   if [ ! -d "${masterpath}" ]
   then
      fail "Master \"${masterpath}\" not found"
   fi

   if ! can_be_master_bootstrap_project "${masterpath}"
   then
      fail "\"${masterpath}\" contains a .bootstrap folder. It can't be used as a master"
   fi

   if master_owns_minion_bootstrap_project "${masterpath}" "${minionpath}"
   then
      internal_fail "Master \"${masterpath}\" already owns \"${minionpath}\", but it was not detected before"
   fi

   log_info "Deferring to \"${masterpath}\""

   make_master_bootstrap_project "${masterpath}"
   make_minion_bootstrap_project "${minionpath}" "${masterpath}"

   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   [ -z "${MULLE_BOOTSTRAP_CLEAN_SH}" ]           && . mulle-bootstrap-clean.sh

   #
   # dist clean ourselves
   #
   clean_execute "dist"

   master_add_minion_bootstrap_project "${masterpath}" "${minionpath}"

}


emancipate_main()
{
   log_debug ":emancipate_main:"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            defer_usage
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown option $1"
            defer_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_BOOTSTRAP_PROJECT_SH}" ] && . mulle-bootstrap-project.sh

   unpostpone_trace

   local masterpath
   local minionpath

   [ $# -ne 0 ] && defer_usage

   minionpath="${PWD}"
   minionpath="`absolutepath "${minionpath}"`"
   if ! is_minion_bootstrap_project "${minionpath}"
   then
      log_info "Project \"${minionpath}\" does not defer to a master and is already emancipated"
      return
   fi

   masterpath="`get_master_of_minion_bootstrap_project \"${minionpath}\"`"
   if [ -z "${masterpath}" ]
   then
      fail "Can not determine master for \"${minionpath}\""
   fi

   if [ ! -d "${masterpath}" ]
   then
      fail "Master \"${masterpath}\" is missing"
   fi

   if ! is_master_bootstrap_project "${masterpath}"
   then
      fail "\"${masterpath}\" is not a master project"
   fi

   log_info "Emancipating from \"${masterpath}\""
   master_remove_minion_bootstrap_project "${masterpath}" "${minionpath}"
   emancipate_minion_bootstrap_project "${minionpath}"

   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   [ -z "${MULLE_BOOTSTRAP_CLEAN_SH}" ] && . mulle-bootstrap-clean.sh

   #
   # dist clean ourselves
   #
   clean_execute "dist"
}

