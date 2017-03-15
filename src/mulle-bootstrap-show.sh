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
MULLE_BOOTSTRAP_SHOW_SH="included"


show_usage()
{
    cat <<EOF >&2
usage:
   mulle-bootstrap show [options]

   Options:
EOF

   if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      cat <<EOF >&2
      -b : show brews
      -d : show deeply embedded repositories
      -r : show raw repository content
      -u : show URL
      -s : show scm, branch, tag info
EOF
   fi
  exit 1
}


_show_path()
{
   local filepath="$1"

   if [ -e "${filepath}" ]
   then
      if [ -d "${filepath}" ]
      then
         # printf "${C_BOLD}"
         :
      fi
   else
      printf "%b" "${C_FAINT}"
   fi

   printf "%b" "${filepath}${C_RESET}"
}


show_path()
{
   local filepath="$1"

   if [ -L "${filepath}" ]
   then
      local redirect
      local directory

      redirect="`readlink "${filepath}"`"
      directory="`dirname -- "${filepath}"`"
      printf "%b"  "${filepath} -> `( cd "${directory}" ; _show_path "${redirect}" )`"
   else
      _show_path "${filepath}"
   fi
}


show_minion()
{
   local name="$1"  # ususally .bootstrap.repos

   printf "%b"  "${SHOW_PREFIX}${C_MAGENTA}${C_BOLD}"

   if [ "${PARENT_REPOSITORY_NAME}" ]
   then
      printf "%b"  "${PARENT_REPOSITORY_NAME}/"
   fi

   printf "%b" "${name}${C_RESET}"

   printf ": "
   show_path "${name}"

   printf "\n"
}


show_repository()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   printf "%b"  "${SHOW_PREFIX}${C_MAGENTA}"
   if is_minion_bootstrap_project "${stashdir}"
   then
      printf "%b" "${C_BOLD}"
   fi


   if [ "${PARENT_REPOSITORY_NAME}" ]
   then
      printf "%b"  "${PARENT_REPOSITORY_NAME}/"
   fi

   printf "%b" "${name}${C_RESET}"

   if [ "${SHOW_URL}" = "YES" ]
   then
      printf "%b"  " (${url})"
   fi

   printf ": "
   show_path "${stashdir}"

   if [ "${SHOW_SCM}" = "YES" ]
   then
      printf "%b"  "  [${scm}"

      if [ ! -z "${tag}" -o ! -z "${branch}" ]
      then
         printf "%b"  ": ${branch}"
         if [ ! -z "${tag}" ]
         then
            printf "%b"  ";${tag}"
         fi
      fi

      printf "]"
   fi

   printf "\n"
}


show_raw_repository()
{
   local url="$1"       # URL of the clone
   local dstdir="$2"    # branch of the clone
   local branch="$3"       # scm to use for this clone
   local scm="$4"       # scm to use for this clone
   local tag="$5"       # tag to checkout of the clone

   local name
   local stashdir

   name="`_canonical_clone_name "${url}"`"
   stashdir="`computed_stashdir "${url}" "${name}" "${dstdir}"`"

   (
      printf "%b" "${SHOW_PREFIX}${url}"
      printf "%b" ";${dstdir}"
      printf "%b" ";${branch}"
      printf "%b" ";${scm}"
      printf "%b" ";${tag}"
      printf "\n"
   ) | sed 's/;*$//'

   if is_bootstrap_project "${stashdir}"
   then
      (
         cd "${stashdir}"
         SHOW_PREFIX="${SHOW_PREFIX}   " \
         MULLE_BOOTSTRAP_DONT_DEFER="YES" \
            mulle-bootstrap show -n ${MULLE_EXECUTABLE_OPTIONS}
      )
   fi
}


show_raw_repositories()
{
   (
      local clones

      SHOW_PREFIX="${SHOW_PREFIX}   "
      clones="`read_raw_setting "repositories"`"
      walk_raw_clones "${clones}" "show_raw_repository"
   )
}


show_raw_embedded_repositories()
{
   (
      local clones

      SHOW_PREFIX="${SHOW_PREFIX}   "
      clones="`read_raw_setting "embedded_repositories"`"
      walk_raw_clones "${clones}" "show_raw_repository"
   )
}


show_raw_minions()
{
   (
      local minions
      local minion

      SHOW_PREFIX="${SHOW_PREFIX}   "
      minions="`read_raw_setting "minions"`"

      IFS="
"
      for minion in ${minions}
      do
          printf "%b%b\n" "${SHOW_PREFIX}" "${minion}"
      done
   )
}

show_minions()
{
   (
      SHOW_PREFIX="${SHOW_PREFIX}   " \
      walk_root_setting "minions"  \
                        "show_minion"
   )
}


show_repositories()
{
   local permissions

   permissions="missing
minion"
   (
      SHOW_PREFIX="${SHOW_PREFIX}   " \
      walk_auto_repositories "repositories"  \
                             "show_repository" \
                             "${permissions}" \
                             "${REPOS_DIR}"
   )
}


show_embedded_repositories()
{
   local permissions

   permissions="missing
minion"
   (
      SHOW_PREFIX="${SHOW_PREFIX}   " \
      walk_auto_repositories "embedded_repositories"  \
                             "show_repository" \
                             "${permissions}" \
                             "${EMBEDDED_REPOS_DIR}"
   )
}


show_deep_embedded_repositories()
{
   local permissions

   permissions="missing
minion"
   (
      SHOW_PREFIX="${SHOW_PREFIX}   " \
         walk_deep_embedded_auto_repositories "show_repository" \
                                              "${permissions}"
   )
}


show_brew()
{
   local formula="$1"  # ususally .bootstrap.repos

   printf "%b" "${SHOW_PREFIX}${formula}\n"
}


show_brews()
{
   local brews

   if [ "${SHOW_RAW}" = "YES" ]
   then
      brews="`read_raw_setting "brews"`"
   else
      brews="`find_brews`"
   fi
   walk_brews "${brews}" "show_brew"
}


_header_show()
{
   if [ "${SHOW_HEADER}" = "YES" ]
   then
      log_info "${SHOW_PREFIX}Project:"
      printf "%b" "${SHOW_PREFIX}   "
      printf "%b" "${C_INFO}Directory${C_RESET}: "
      printf "%s\n" "${PWD}"

      printf "%b" "${SHOW_PREFIX}   "
      printf "%b" "${C_INFO}Master${C_RESET}: "
      if is_master_bootstrap_project
      then
         printf "YES\n"
      else
         printf "NO\n"
      fi

      printf "%b" "${SHOW_PREFIX}   "
      printf "%b" "${C_INFO}Minion${C_RESET}: "
      if is_minion_bootstrap_project
      then
         printf "YES\n"
      else
         printf "NO\n"
      fi
      log_info ""
   fi
}


_common_show()
{
   local header_only="$1" ; shift

   _header_show

   if [ "${header_only}" = "YES" ]
   then
      return
   fi

   if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      log_info "${SHOW_PREFIX}Minions:"
      if [ "${SHOW_RAW}" = "YES" ]
      then
         show_raw_minions
      else
         show_minions
      fi
      log_info ""

      log_info "${SHOW_PREFIX}Repositories:"
      if [ "${SHOW_RAW}" = "YES" ]
      then
         log_info "${SHOW_PREFIX}   ${C_FAINT}URL;DSTDIR;BRANCH;SCM;TAG"
         show_raw_repositories
      else
         show_repositories
      fi

      log_info ""
      log_info "${SHOW_PREFIX}Embedded Repositories:"
      if [ "${SHOW_RAW}" = "YES" ]
      then
         show_raw_embedded_repositories
      else
         show_embedded_repositories
      fi

      if [ "${SHOW_RAW}" = "NO" -a "${SHOW_DEEP}" = "YES" ]
      then
         log_info ""
         log_info "${SHOW_PREFIX}Deeply Embedded Repositories:"
         show_deep_embedded_repositories
      fi
      log_info ""
   fi

   if [ "${SHOW_BREWS}" = "YES" ]
   then
      log_info "${SHOW_PREFIX}Brews:"
      show_brews
   fi
}


_show_main()
{
   local header_only="$1" ; shift

   log_debug ":show_main:"

   local ROOT_DIR="`pwd -P`"

   local SHOW_SCM="NO"
   local SHOW_URL="NO"
   local SHOW_BREWS="YES"
   local SHOW_RAW="NO"
   local SHOW_DEEP="NO"
   local SHOW_HEADER="YES"
   local MULLE_FLAG_FOLLOW_SYMLINKS="YES"

   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ] && . mulle-bootstrap-repositories.sh
   [ -z "${MULLE_BOOTSTRAP_FETCH_SH}" ]        && . mulle-bootstrap-fetch.sh
   [ -z "${MULLE_BOOTSTRAP_SCM_SH}" ]          && . mulle-bootstrap-scm.sh
   [ -z "${MULLE_BOOTSTRAP_BREW_SH}" ]         && . mulle-bootstrap-brew.sh

   if [ "${MULLE_EXECUTABLE}" = "mulle-bootstrap" ]
   then
      SHOW_BREWS="NO"
   fi

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            show_usage
         ;;

         -b|--brews)
            SHOW_BREWS="YES"
         ;;

         -d|--deep)
            SHOW_DEEP="YES"
         ;;

         -r|--raw)
            SHOW_RAW="YES"
         ;;

         -s|--scm)
            SHOW_SCM="YES"
         ;;

         -u|--url)
            SHOW_URL="YES"
         ;;

         -n|--no-header)
            SHOW_HEADER="NO"
         ;;

         -nfs|--no-follow-symlinks)
            MULLE_FLAG_FOLLOW_SYMLINKS="NO"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown status option $1"
            show_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 0 ] && show_usage

   _common_show "${header_only}" "$@"

   if [ "${header_only}" != "YES" -a \
        "${SHOW_RAW}" != "YES" -a \
        ! -d "${BOOTSTRAP_DIR}".auto ]
   then
      log_warning "Nothing to show yet. Maybe use --raw option ?"
   fi
}


show_main()
{
   _show_main "NO" "$@"
}


show_main_header_only()
{
   _show_main "YES" "$@"
}
