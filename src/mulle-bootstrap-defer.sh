#! /usr/bin/env bash
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
Usage:
   ${MULLE_EXECUTABLE} emancipate

   Emancipate from master. ${MULLE_EXECUTABLE} will make local dependencies
   again.

EOF
  exit 1
}


defer_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE} defer

   Share and defer builds to master. The master will be used
   to fetch dependencies and build them. Use ${MULLE_EXECUTABLE} paths
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

   [ $# -eq 0 ] || defer_usage

   [ -z "${MULLE_BOOTSTRAP_PROJECT_SH}" ]         && . mulle-bootstrap-project.sh
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   [ -z "${MULLE_BOOTSTRAP_CLEAN_SH}" ]           && . mulle-bootstrap-clean.sh

   unpostpone_trace

   local masterpath
   local minionpath

   minionpath="${PWD}"
   minionpath="`absolutepath "${minionpath}"`"

   if is_minion_bootstrap_project "${minionpath}"
   then
      masterpath="`get_master_of_minion_bootstrap_project "${minionpath}"`"
      [ ! -z "${masterpath}" ]  || internal_fail "is_minion file empty"
      log_warning "Master \"${masterpath}\" already owns \"${minionpath}\""

      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "NONE" ]
      then
         return
      fi
   fi

   masterpath=".."
   masterpath="`absolutepath "${masterpath}"`"

   if [ ! -d "${masterpath}" ]
   then
      fail "Master \"${masterpath}\" not found"
   fi

   if [ -L "${masterpath}" ]
   then
      log_warning "Mater \"${masterpath}\" is a symlink. Don't overcomplicate it."
   fi

   if [ -L "${minionpath}" ]
   then
      log_warning "Minion \"${minionpath}\" is a symlink. Don't overcomplicate it."
   fi

   if ! can_be_master_bootstrap_project "${masterpath}"
   then
      fail "\"${masterpath}\" contains a .bootstrap folder. It can't be used as a master"
   fi

   if master_owns_minion_bootstrap_project "${masterpath}" "${minionpath}"
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "NONE" ]
      then
         log_warning "Master \"${masterpath}\" already owns \"${minionpath}\", but it was not detected before"
         return
      fi
   fi

   #
   # dist clean ourselves
   #
   log_info "Cleaning minion before deferral"

   ( clean_execute "dist" )


   log_info "Deferring \"${minionpath}\" to \"${masterpath}\""

   make_master_bootstrap_project "${masterpath}"
   master_add_minion_bootstrap_project "${masterpath}" "${minionpath}"
   make_minion_bootstrap_project "${minionpath}" "${masterpath}"

   #
   # clean the master, because cmake doesn't like old paths
   # kinda superzealous though...
   #
   mulle-bootstrap clean output
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
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   [ -z "${MULLE_BOOTSTRAP_CLEAN_SH}" ] && . mulle-bootstrap-clean.sh

   unpostpone_trace

   local masterpath
   local minionpath

   [ $# -ne 0 ] && defer_usage

   minionpath="${PWD}"
   minionpath="`absolutepath "${minionpath}"`"
   if ! is_minion_bootstrap_project "${minionpath}"
   then
      log_warning "Project \"${minionpath}\" does not defer to a master and is already emancipated"

      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "NONE" ]
      then
         return
      fi
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
      log_warning "\"${masterpath}\" is not a master project"
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "NONE" ]
      then
         return
      fi
   else
      log_info "Cleaning minion before emancipation"

      local name

      name="`basename -- "${minionpath}"`"
      ( mulle-bootstrap clean --minion "${name}" )

      log_info "Cleaning master before emancipation"
      ( mulle-bootstrap clean output )
   fi

   log_info "Emancipating \"${minionpath}\" from \"${masterpath}\""

   master_remove_minion_bootstrap_project "${masterpath}" "${minionpath}"

   emancipate_minion_bootstrap_project "${minionpath}"

   #
   # dist clean ourselves
   #
   log_info "Cleaning ex-minion after emancipation"

   clean_execute "dist"
}

