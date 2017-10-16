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
MULLE_BOOTSTRAP_STATUS_SH="included"


status_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE} status [options]

Options:
   -e   : embedded directories
   -nfs : don't follow symlinks

EOF
  exit 1
}


_status_repository()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   log_fluff "Perform status in ${stashdir} ..."


   if [ "${STATUS_LIST}" = "YES" ]
   then
      echo "${stashdir}"
   fi

   if [ "${STATUS_SCM}" = "YES" ]
   then
      case "${scm}" in
      git*)
         git_status "$@" >&2
      ;;

      svn*)
         svn_status "$@" >&2
      ;;

      zip*|tar*)
         log_verbose "No status for ${scm}"
      ;;

      *)
         fail "Unknown scm system ${scm}"
      ;;
      esac
   fi

   if [ "${STATUS_FETCH}" = "YES" ]
   then
      if [ "${stashdir}/.bootstrap" -nt "${REPOS_DIR}/.fetch_done" -o \
           "${stashdir}/.bootstrap.local" -nt "${REPOS_DIR}/.fetch_done" ]
      then
         echo "${C_RED} M ${C_RESET}${stashdir}"
      fi
   fi
}


status_repositories()
{
   local permissions

   permissions="minion"

   walk_auto_repositories "repositories"  \
                     "_status_repository" \
                     "${permissions}" \
                     "${REPOS_DIR}"
}


status_embedded_repositories()
{
   local permissions

   permissions="minion"
   walk_auto_repositories "embedded_repositories"  \
                          "_status_repository" \
                          "${permissions}" \
                          "${EMBEDDED_REPOS_DIR}"
}


status_deep_embedded_repositories()
{
   local permissions

   permissions="minion"
   walk_auto_deep_embedded_repositories "_status_repository" \
                                        "${permissions}" \
                                        "${REPOS_DIR}"
}


status_brew()
{
   local formula="$1"  # ususally .bootstrap.repos

   ${BREW} list "${formula}"
}


status_brews()
{
   local brews

   brews="`find_brews`"
   walk_brews "${brews}" "status_brew"
}


_quick_status()
{
   if dirty_harry
   then
      log_info "Dirty Harry"
      return 3
   else
      if fetch_needed
      then
         log_info "Fetch needed"
         return 2
      else
         if build_needed
         then
            log_info "Build needed"
            return 1
         fi
      fi
   fi

   return 0
}


_common_status()
{
   if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      local MULLE_BOOTSTRAP_SETTINGS_NO_AUTO

      if [ ! -d "${BOOTSTRAP_DIR}.auto" ]
      then
         MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="YES"
      fi


      if [ "${SKIP_EMBEDDED}" = "YES"  ]
      then
         status_embedded_repositories
      fi

      if [ "${OPTION_EMBEDDED_ONLY}" = "YES" ]
      then
         return
      fi

      status_repositories "$@"

      if [ "${SKIP_EMBEDDED}" = "YES"  ]
      then
         status_deep_embedded_repositories
      fi
   fi

   if [ "${STATUS_BREWS}" = "YES"  ]
   then
      status_brews
   fi
}


status_main()
{
   log_debug ":status_main:"

   local MULLE_FLAG_FOLLOW_SYMLINKS="YES"
   local OPTION_EMBEDDED_ONLY="NO"
   local SKIP_EMBEDDED="YES"
   local STATUS_BREWS="YES"
   local STATUS_CONDENSED="NO"
   local STATUS_SCM="NO"
   local STATUS_FETCH="YES"
   local STATUS_LIST="NO"

   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ] && . mulle-bootstrap-repositories.sh
   [ -z "${MULLE_BOOTSTRAP_FETCH_SH}" ]        && . mulle-bootstrap-fetch.sh
   [ -z "${MULLE_BOOTSTRAP_SCM_SH}" ]          && . mulle-bootstrap-scm.sh
   [ -z "${MULLE_BOOTSTRAP_BREW_SH}" ]         && . mulle-bootstrap-brew.sh

   if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      STATUS_BREWS="NO"
   fi

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            status_usage
         ;;

         -a|--all)
            SKIP_EMBEDDED="NO"
         ;;

         -b|--brews)
            STATUS_BREWS="YES"
         ;;

         -c|--condensed)
            STATUS_CONDENSED="YES"
         ;;

         -e|--embedded-only)
            OPTION_EMBEDDED_ONLY="YES"
            SKIP_EMBEDDED="NO"
         ;;

         -l|--list)
            STATUS_LIST="YES"
         ;;

         -nf|--no-fetch)
            STATUS_FETCH="NO"
         ;;

         -nfs|--no-follow-symlinks)
            MULLE_FLAG_FOLLOW_SYMLINKS="NO"
         ;;

         -s|--scm)
            STATUS_SCM="YES"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown status option $1"
            status_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local rval

   _quick_status "$@"
   rval="$?"

   if [ "${MULLE_FLAG_LOG_TERSE}" = "YES" ]
   then
      return "$rval"
   fi

   if [ "${STATUS_CONDENSED}" = "NO" ]
   then
      _common_status "$@"
   fi
}

