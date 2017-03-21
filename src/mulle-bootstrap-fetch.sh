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

MULLE_BOOTSTRAP_FETCH_SH="included"

#
# this script installs the proper git clones into "clones"
# it does not to git subprojects.
# You can also specify a list of "brew" dependencies. That
# will be third party libraries, you don't tag or debug
#
#
# ## NOTE ##
#
# There is a canonical argument passing scheme, which gets passed to and
# forwarded by most function
#
# reposdir="$1"   # ususally .bootstrap.repos
# name="$2"       # name of the clone
# url="$3"        # URL of the clone
# branch="$4"     # branch of the clone
# scm="$5"        # scm to use for this clone
# tag="$6"        # tag to checkout of the clone
# stashdir="$7"     # stashdir of this clone (absolute or relative to $PWD)
#

fetch_usage()
{
   cat <<EOF >&2
usage:
   mulle-bootstrap ${COMMAND} [options] [repositories]

   Options
      --caches            :  use CACHES_PATH to locate local repositories
      --check-usr-local   :  check /usr/local for duplicates
      --embedded-only     :  fetch embedded repositories only

      --symlinks          :  allow symlinking instead of cloning
      --embedded-symlinks :  allow embedded symlinks (very experimental)
      --follow-symlinks   :  follow symlinks when updating (not recommended)
      --no-caches         :  don't use caches. Useful to counter flag -y
      --no-symlinks       :  don't create symlinks. Useful to counter flag -y

   install  :  clone or symlink non-exisiting repositories and other resources
   update   :  execute a "fetch" in already fetched repositories
   upgrade  :  execute a "pull" in fetched repositories

   You can specify the names of the repositories to update.
EOF

   local  repositories

   repositories="`all_repository_names`"
   if [ -z "${repositories}" ]
   then
      echo "Currently available repositories are:"
      echo "${repositories}" | sed 's/^/   /'
   fi
   exit 1
}


assert_sane_parameters()
{
   local  empty_reposdir_is_ok="$1"

   [ ! -z "${empty_reposdir_is_ok}" -a -z "${reposdir}" ] && internal_fail "parameter: reposdir is empty"
   [ -z "${empty_reposdir_is_ok}" -a ! -d "${reposdir}" ] && internal_fail "parameter: reposdir does not exist ($reposdir)"

   [ -z "${url}" ]      && internal_fail "parameter: url is empty"
   [ -z "${name}" ]     && internal_fail "parameter: name is empty"
   [ -z "${stashdir}" ] && internal_fail "parameter: stashdir is empty"

   :
}

#
# future, download tarballs...
# we check for existance during fetch, but install during build
#
check_tars()
{
   local tarballs
   local tar

   log_fluff "Looking for tarballs"

   tarballs="`read_root_setting "tarballs" | sort | sort -u`"
   if [ ! -z "${tarballs}" ]
   then
      [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"
      IFS="
"
      for tar in ${tarballs}
      do
         IFS="${DEFAULT_IFS}"

         if [ ! -f "$tar" ]
         then
            fail "tarball \"$tar\" not found"
         fi
         log_fluff "tarball \"$tar\" found"
      done
      IFS="${DEFAULT_IFS}"

   else
      log_fluff "No tarballs found"
   fi
}


log_action()
{
   local action="$1" ; shift

   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   assert_sane_parameters "empty reposdir is ok"

   local info

   if [ -L "${url}" ]
   then
      info=" symlinked "
   else
      info=" "
   fi

   log_fluff "Perform ${action}${info}${url} into ${stashdir} ..."
}


#
###
#
link_command()
{
#   local reposdir="$1"  # ususally .bootstrap.repos
#   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
#   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   assert_sane_parameters "empty reposdir is ok"

   local absolute

   absolute="`read_config_setting "absolute_symlinks" "NO"`"
   if ! exekutor create_symlink "${url}" "${stashdir}" "${absolute}"
   then
      return 1
   fi

   local branchlabel

   branchlabel="branch"
   if [ -z "${branch}" -a ! -z "${tag}" ]
   then
      branchlabel="tag"
      branch="${tag}"
   fi

   if [ "${branch}" != "master" ]
   then
      log_warning "The intended ${branchlabel} ${C_RESET_BOLD}${branch}${C_WARNING} will be ignored, because"
      log_warning "the repository is symlinked."
      log_warning "If you want to checkout this ${branchlabel} do:"
      log_warning "${C_RESET_BOLD}(cd ${stashdir}; git checkout ${GITOPTIONS} \"${branch}\" )${C_WARNING}"
   fi
}


can_symlink_it()
{
   local  directory="$1"

   if [ "${OPTION_ALLOW_CREATING_SYMLINKS}" != "YES" ]
   then
      log_fluff "Can't symlink it, because forbidden"
      return 1
   fi

   case "${UNAME}" in
      minwgw)
         log_fluff "Can't symlink it, because symlinking is unavailable on this platform"
         return 1
      ;;
   esac

   if git_is_repository "${directory}"
   then
       # if bare repo, we can only clone anyway
      if git_is_bare_repository "${directory}"
      then
         log_info "${directory} is a bare git repository. So cloning"
         log_info "is the only way to go."
         return 1
      fi
   else
      log_info "${directory} is not a git repository (yet ?)"
      log_info "So symlinking is the only way to go."
   fi

  return 0
}


_search_for_git_repository_in_cache()
{
   local directory
   local name
   local branch

   [ $# -ne 3 ] && internal_fail "fail"

   directory="$1"
   name="$2"
   branch="$3"

   local found

   if [ "${MULLE_FLAG_LOG_CACHE}" = "YES" ]
   then
      log_trace "Checking cache path \"${directory}\""
   fi

   if [ ! -z "${branch}" ]
   then
      found="${directory}/${name}.${branch}"
      log_fluff "Looking for \"${found}\""

      if [ -d "${found}" ]
      then
         log_fluff "Found \"${name}.${branch}\" in \"${directory}\""

         echo "${found}"
         return
      fi
   fi

   found="${directory}/${name}.git"
   log_fluff "Looking for \"${found}\""
   if [ -d "${found}" ]
   then
      log_fluff "Found \"${name}.git\" in \"${directory}\""

      echo "${found}"
      return
   fi

   found="${directory}/${name}"
   log_fluff "Looking for \"${found}\""
   if [ -d "${found}" ]
   then
      log_fluff "Found \"${name}\" in \"${directory}\""

      echo "${found}"
      return
   fi
}


search_for_git_repository_in_caches()
{
   local found
   local directory
   local realdir
   local curdir

   if [ "${MULLE_FLAG_LOG_CACHE}" = "YES" -a -z "${CACHES_PATH}" ]
   then
      log_trace "CACHES_PATH is empty"
   fi

   curdir="`pwd -P`"
   IFS=":"
   for directory in ${CACHES_PATH}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -d "${directory}" ]
      then
         if [ "${MULLE_FLAG_LOG_CACHE}" = "YES" ]
         then
            log_trace2 "Cache path \"${realdir}\" does not exist"
         fi
         continue
      fi

      realdir="`realpath "${directory}"`"
      if [ "${realdir}" = "${curdir}" ]
      then
         fail "config setting \"caches_path\" mistakenly contains \"${directory}\", which is the current directory"
      fi

      found="`_search_for_git_repository_in_cache "${realdir}" "$@"`" || exit 1
      if [ ! -z "${found}" ]
      then
         symlink_relpath "${found}" "${ROOT_DIR}"
         return
      fi
   done

   IFS="${DEFAULT_IFS}"
   return 1
}


_search_for_archive_in_caches()
{
   local directory="$1"
   local name="$2"
   local filename="$3"

   [ $# -ne 3 ] && internal_fail "fail"

   local found

   found="${directory}/${name}-${filename}"
   log_fluff "Looking for \"${found}\""
   if [ -f "${found}" ]
   then
      log_fluff "Found \"${name}\" in \"${directory}\" as \"${found}\""

      echo "${found}"
      return
   fi

   found="${directory}/${filename}"
   log_fluff "Looking for \"${found}\""
   if [ -f "${found}" ]
   then
      log_fluff "Found \"${name}\" in \"${directory}\" as \"${found}\""

      echo "${found}"
      return
   fi
}


search_for_archive_in_caches()
{
   local name="$1"
   local filename="$2"

   local found
   local directory

   IFS=":"
   for directory in ${CACHES_PATH}
   do
      IFS="${DEFAULT_IFS}"

      found="`_search_for_archive_in_caches "${directory}" "${name}" "${filename}"`" || exit 1
      if [ ! -z "${found}" ]
      then
         found="`absolutepath "${found}"`"
         echo "file:///${found}"
         return
      fi
   done

   IFS="${DEFAULT_IFS}"
   return 1
}


mkdir_stashparent_if_missing()
{
   local stashdir="$1"

   local stashparent

   stashparent="`dirname -- "${stashdir}"`"
   case "${stashparent}" in
      ""|"\.")
      ;;

      *)
         mkdir_if_missing "${stashparent}"
         echo "${stashparent}"
      ;;
   esac
}


get_cache_item()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone, extensionless
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   if [ "${OPTION_ALLOW_SEARCH_CACHES}" = "NO" ]
   then
      log_fluff "Not searching caches because --no-caches"
      return
   fi

   case "${scm}" in
      git*)
         search_for_git_repository_in_caches "${name}" "${branch}"
      ;;

      tar*|zip*)
         search_for_archive_in_caches "${name}" "`basename -- "${url}"`"
      ;;

      *)
         log_fluff "Not searching caches because scm is \"${scm}\""
      ;;
   esac
}


clone_or_symlink()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone, extensionless
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)


   assert_sane_parameters "empty reposdir is ok"

   [ $# -le 7 ] || internal_fail "too many parameters"

   local operation
   local scmflagsdefault

   case "${scm}" in
      git*)
         operation="git_clone"
      ;;

      zip*)
         operation="zip_unpack"
      ;;

      tar*)
         operation="tar_unpack"
      ;;

      svn*)
         operation="svn_checkout"
      ;;

      *)
         fail "Unknown scm system ${scm}"
      ;;
   esac

   local SCM_OPTIONS

   #
   # later: make it so tar?shasum256=djhdjhdfdh
   # and check that the archive is correct
   #
   extra="`echo "${scm}" | sed -n 's/^[^?]*\?\(.*\)/\1/p'`"
   if [ ! -z "${extra}" ]
   then
      log_fluff "Parsed SCM_OPTIONS as \"${extra}\""
      SCM_OPTIONS="${extra}"
   fi

   local stashparent

   stashparent="`mkdir_stashparent_if_missing "${stashdir}"`"

   local found
   local script

   script="`find_root_setting_file "bin/clone.sh"`"

   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
      return $?
   fi

   case "${url}" in
      /*)
         if can_symlink_it "${directory}"
         then
            operation=link_command
         fi
      ;;

      #
      # don't move up using url
      #
      */\.\./*|\.\./*|*/\.\.|\.\.)
         internal_fail "Faulty url \"${url}\" should have been caught before"
      ;;

      *)
         found="`get_cache_item "${reposdir}" \
                                "${name}" \
                                "${url}" \
                                "${branch}" \
                                "${scm}" \
                                "${tag}" \
                                "${stashdir}"`"

         if [ ! -z "${found}" ]
         then
            url="${found}"

            case "${scm}" in
               git)
                  if can_symlink_it "${url}"
                  then
                     operation=link_command
                  fi
               ;;
            esac

            case "${operation}" in
               link_command)
                 log_info "Using symlink to cached item \"${found}\""
               ;;

               *)
                 log_info "Using cached item \"${found}\""
               ;;
            esac
         fi
      ;;
   esac

   local rval

   if ! "${operation}" "${reposdir}" \
                       "${name}" \
                       "${url}" \
                       "${branch}" \
                       "${scm}" \
                       "${tag}" \
                       "${stashdir}"
   then
      #
      # check if clone is an optional install component
      # it is if it doesn't show up in "required"
      # required is built by mulle-bootstrap usually
      # you specify optionals, by specifying the required
      # clones and leaving the optional out
      #
      local required

      required="`read_root_setting "required"`"
      [ -z "${required}" ] && internal_fail "required missing"

      if ! echo "${required}" | fgrep -s -q -x "${name}" > /dev/null
      then
         log_info "${C_MAGENTA}${C_BOLD}${name}${C_INFO} is missing, but it's not required."

         merge_line_into_file "${REPOS_DIR}/.missing" "${name}"
         return 1  # means just skip
      fi

      return  # means exit
   fi

   if [ "${DONT_WARN_SCRIPTS}" != "YES" ]
   then
      [ -z "${MULLE_BOOTSTRAP_WARN_SCRIPTS_SH}" ] && . mulle-bootstrap-warn-scripts.sh

      warn_scripts_main "${stashdir}/.bootstrap" "${stashdir}" || fail "Ok, aborted"  #sic
   fi

   if [ "${operation}" = "link_command" ]
   then
      return 2
   fi

   return 0
}

##
## CLONE
##
clone_repository()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   [ $# -eq 7 ] || internal_fail "fail"

   log_action "clone" "$@"

   assert_sane_parameters "empty is ok"

   if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = "YES" ] && has_usr_local_include "${name}"
   then
      log_info "${C_MAGENTA}${C_BOLD}${name}${C_INFO} is a system library, so not fetching it"
      return 1
   fi

   if [ -e "${stashdir}" ]
   then
      if [ "${url}" = "${stashdir}" ]
      then
         if is_master_bootstrap_project
         then
            is_minion_bootstrap_project "${stashdir}" || fail "\"${stashdir}\" \
should be a minion but it isn't.
Suggested fix:
   ${C_RESET}${C_BOLD}cd \"${stashdir}\" ; mulle-bootstrap defer \"\
`symlink_relpath "${PWD}" "${stashdir}"`\
\""
            log_info "${C_MAGENTA}${C_BOLD}${name}${C_INFO} is a minion, so cloning is skipped"
            return 1
         fi
      fi
      bury_stash "${reposdir}" "${name}" "${stashdir}"
   fi

   clone_or_symlink "$@"   # pass thru rval
}


##
## CHECKOUT
##
checkout_repository()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   log_action "checkout" "$@"

   local operation

   case "${scm}" in
      git)
         operation="git_checkout"
      ;;
      svn)
         operation="svn_checkout"
      ;;
      *)
         fail "Unknown scm system ${scm}"
      ;;
   esac

   script="`find_build_setting_file "${name}" "bin/checkout.sh"`"
   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
   else
      "${operation}" "$@"
   fi
}


##
## UPDATE
## this like git fetch, does not update repository
##
update_repository()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   log_action "update" "$@"

   local operation

   case "${scm}" in
      git)
         operation="git_fetch"
      ;;
      svn)
         return
      ;;
      *)
         fail "Unknown scm system ${scm}"
      ;;
   esac

   script="`find_build_setting_file "${name}" "bin/update.sh"`"
   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
   else
      "${operation}" "$@"
   fi
}


##
## UPGRADE
## This is a pull

upgrade_repository()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   log_action "upgrade" "$@"

   local operation

   case "${scm}" in
      git)
         operation="git_pull"
      ;;
      svn)
         return
      ;;
      *)
         fail "Unknown scm system ${scm}"
      ;;
   esac

   script="`find_build_setting_file "${name}" "bin/upgrade.sh"`"
   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
   else
      "${operation}" "$@"
   fi
}


#
# Walk repositories with a callback function
#
_update_operation_walk_repositories()
{
   local operation="$1"

   local permissions

   permissions="minion"
   walk_auto_repositories "repositories"  \
                          "${operation}" \
                          "${permissions}" \
                          "${REPOS_DIR}"
}


_update_operation_walk_embedded_repositories()
{
   local operation="$1"

   local permissions

   permissions="minion"
   #
   # embedded repositories can't be symlinked by default
   # embedded repositories are by default not put into
   # stashes (for backwards compatibility)
   #
   (
      STASHES_ROOT_DIR=""
      STASHES_DEFAULT_DIR=""
      OPTION_ALLOW_CREATING_SYMLINKS="${OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS}" ;

      walk_auto_repositories "embedded_repositories"  \
                             "${operation}" \
                             "${permissions}" \
                             "${EMBEDDED_REPOS_DIR}"
   ) || exit 1
}


_update_operation_walk_deep_embedded_auto_repositories()
{
   local operation="$1"

   local permissions

   permissions="minion"

   (
      OPTION_ALLOW_CREATING_SYMLINKS="${OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS}" ;

      walk_deep_embedded_auto_repositories "${operation}" \
                                           "${permissions}"
   ) || exit 1
}


##
## UPDATE
##
update_repositories()
{
   _update_operation_walk_repositories "update_repository"
}


update_embedded_repositories()
{
   _update_operation_walk_embedded_repositories "update_repository"
}


update_deep_embedded_repositories()
{
   _update_operation_walk_deep_embedded_auto_repositories "update_repository"
}


##
## UPGRADE
##
upgrade_repositories()
{
   _update_operation_walk_repositories "upgrade_repository"
}


upgrade_embedded_repositories()
{
   _update_operation_walk_embedded_repositories "upgrade_repository"
}


upgrade_deep_embedded_repositories()
{
   _update_operation_walk_deep_embedded_auto_repositories "upgrade_repository"
}



##
##
##
required_action_for_clone()
{
   local newclone="$1" ; shift

   local newreposdir="$1"  # ususally .bootstrap.repos
   local newname="$2"      # name of the clone
   local newurl="$3"       # URL of the clone
   local newbranch="$4"    # branch of the clone
   local newscm="$5"       # scm to use for this clone
   local newtag="$6"       # tag to checkout of the clone
   local newstashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   local clone

   clone="`clone_of_repository "${reposdir}" "${name}"`"
   if [ -z "${clone}" ]
   then
      log_fluff "${url} is new"
      echo "clone"
      return
   fi

   if [ "${clone}" = "${newclone}" ]
   then
      if [ -e "${newstashdir}" ]
      then
         log_fluff "URL ${url} repository line is unchanged"
         return
      fi

      log_fluff "\"${newstashdir}\" is missing, reget."
      echo "clone"
      return
   fi

   local reposdir

   reposdir="${newreposdir}"

   local name
   local url
   local branch
   local scm
   local tag
   local stashdir

   parse_clone "${clone}"

   log_debug "Change: \"${clone}\" -> \"${newclone}\""

   if [ "${scm}" != "${newscm}" ]
   then
      if ! [ "${scm}" = "symlink" -a "${newscm}" = "git" ]
      then
         log_fluff "SCM has changed from \"${scm}\" to \"${newscm}\", need to refetch"

         if [ "${scm}" != "minion" ]
         then
            log_fluff "Not removing \"${stashdir}\" because it's a minion"
            echo "remove"
         fi

         echo "clone"
         return
      fi
   fi

   if [ "${stashdir}" != "${newstashdir}" ]
   then
      if [ -e "${newstashdir}" ]
      then
         log_fluff "Destination \"${newstashdir}\" already exists. Remove old."
         echo "remove"

         # detect unlucky hacque
         if is_minion_bootstrap_project "${newstashdir}"
         then
            fail "\"${stashdir}\" was renamed to minion \"${newstashdir}\""
         fi
      else
         log_fluff "Destination has changed from \"${stashdir}\" to \"${newstashdir}\", need to move"

         local oldstashdir

         oldstashdir="`get_old_stashdir "${reposdir}" "${name}"`"
         if [ "${oldstashdir}" != "${newstashdir}" ]
         then
            if [ -d "${oldstashdir}" ]
            then
               echo "move ${oldstashdir}"
            else
               log_warning "Can't find ${name} in ${oldstashdir}. Will clone again"
               echo "clone"
            fi
         fi
      fi
   fi

   #
   # if scm is not git, don't try to be clever
   #
   if [ "${scm}" = "symlink" ]
   then
      if [ -e "${newstashdir}" ]
      then
         log_fluff "\"${stashdir}\" is symlink. Ignoring possible differences."
         return
      fi

      log_fluff "\"${newstashdir}\" is missing, reget."
      echo "clone"
      return
   fi

   if [ "${branch}" != "${newbranch}" ]
   then
      log_fluff "Branch has changed from \"${branch}\" to \"${newbranch}\", need to fetch"
      echo "upgrade"
   fi

   if [ "${tag}" != "${newtag}" ]
   then
      log_fluff "Tag has changed from \"${tag}\" to \"${newtag}\", need to check-out"
      echo "checkout"
   fi

   if [ "${url}" != "${newurl}" ]
   then
      log_fluff "URL has changed from \"${url}\" to \"${newurl}\", need to set remote url and fetch"
      echo "set-remote"
      echo "upgrade"
   fi
}


get_old_stashdir()
{
   local reposdir="$1"
   local name="$2"

   [ -z "${reposdir}" ] && internal_fail "reposdir empty"
   [ -z "${name}" ]     && internal_fail "reposdir empty"

   local oldstashdir
   local oldparent

   oldclone="`clone_of_repository "${reposdir}" "${name}"`"

   [ -z "${oldclone}" ] && fail "Old clone information for \"${name}\" in \"${reposdir}\" is missing"

   url="`_url_part_from_clone "${oldclone}"`"
   name="`_canonical_clone_name "${url}"`"
   dstdir="`_dstdir_part_from_clone "${oldclone}"`"

   oldparent="`parentclone_of_repository "${reposdir}" "${name}"`"
   if [ ! -z "${oldparent}" ]
   then
      # figure out what the old stashdir prefix was and remove it
      oldprefix="`_dstdir_part_from_clone "${oldparent}"`"
      dstdir="${dstdir#$oldprefix/}"
   fi

   oldstashdir="`computed_stashdir "${url}" "${name}" "${dstdir}"`"

   echo "${oldstashdir}"
}


auto_update_minions()
{
   local minions="$1"

   local minion

   log_debug ":auto_update_minions: (${minions})"

   IFS="
"
   for minion in ${minions}
   do
      IFS="${DEFAULT_IFS}"

      if [ -z "${minion}" ]
      then
         continue
      fi

      log_debug "${C_INFO}Updating minion \"${minion}\" ..."

      [ ! -d "${minion}" ] && fail "Minion \"${minion}\" is gone"

      bootstrap_auto_update "${minion}" "${minion}"
   done

   IFS="${DEFAULT_IFS}"
}


work_clones()
{
   local reposdir="$1"
   local clones="$2"
   local autoupdate="$3"

   local clone
   local name
   local url
   local branch
   local scm
   local tag
   local stashdir
   local dstdir

   local actionitems
   local remember
   local repotype
   local oldstashdir

   case "${reposdir}" in
      *embedded)
        repotype="embedded "
      ;;

      *)
        repotype=""
      ;;
   esac

   log_debug "Working \"${clones}\""

   IFS="
"
   for clone in ${clones}
   do
      IFS="${DEFAULT_IFS}"

      if [ -z "${clone}" ]
      then
         continue
      fi

      #
      # optimization, try not to redo fetches
      #
      echo "${__IGNORE__}" | fgrep -s -q -x "${clone}" > /dev/null
      if [ $? -eq 0 ]
      then
         continue
      fi

      log_debug "${C_INFO}Doing clone \"${clone}\" ..."

      __REFRESHED__="`add_line "${__REFRESHED__}" "${clone}"`"

      parse_raw_clone "${clone}"
      process_raw_clone

      stashdir="${dstdir}"
      [ -z "${stashdir}" ] && internal_fail "empty stashdir"

      case "${name}" in
         http:*|https:*)
            internal_fail "failed name: ${name}"
      esac

      case "${stashdir}" in
         http:*|https:*)
            internal_fail "failed stashdir: ${stashdir}"
      esac

      if is_minion_bootstrap_project "${name}"
      then
         log_fluff "Is a minion, ignoring possible changes"
         clone="`echo "${name};${name};${branch};minion;${tag}" | sed 's/;*$//'`"
         remember="YES"
      else
         actionitems="`required_action_for_clone "${clone}" \
                                                 "${reposdir}" \
                                                 "${name}" \
                                                 "${url}" \
                                                 "${branch}" \
                                                 "${scm}" \
                                                 "${tag}" \
                                                 "${stashdir}"`" || exit 1

         log_debug "${C_INFO}Actions for \"${name}\": ${actionitems:-none}"

         IFS="
"
         for item in ${actionitems}
         do
            IFS="${DEFAULT_IFS}"

            remember="YES"

            case "${item}" in
               "checkout")
                  checkout_repository "${reposdir}" \
                                      "${name}" \
                                      "${url}" \
                                      "${branch}" \
                                      "${scm}" \
                                      "${tag}" \
                                      "${stashdir}"
               ;;

               "clone")
                  clone_repository "${reposdir}" \
                                   "${name}" \
                                   "${url}" \
                                   "${branch}" \
                                   "${scm}" \
                                   "${tag}" \
                                   "${stashdir}"

                  case "$?" in
                     1)
                        # skipped
                        continue
                     ;;
                     2)
                        # if we used a symlink, we want to memorize that
                        scm="symlink"
                     ;;

                     3)
                        exit 1
                     ;;
                  esac
               ;;

               "ignore")
                  remember="NO"
               ;;

               move*)
                  oldstashdir="${item:5}"

                  log_info "Moving ${repotype}stash ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from \"${oldstashdir}\" to \"${stashdir}\""

                  if ! exekutor mv ${COPYMOVEFLAGS} "${oldstashdir}" "${stashdir}"  >&2
                  then
                     fail "Move failed!"
                  fi
               ;;

               "upgrade")
                  upgrade_repository "${reposdir}" \
                                     "${name}" \
                                     "${url}" \
                                     "${branch}" \
                                     "${scm}" \
                                     "${tag}" \
                                     "${stashdir}"
               ;;

               remove*)
                  oldstashdir="${item:7}"
                  if [ -z "${oldstashdir}" ]
                  then
                     oldstashdir="`get_old_stashdir "${reposdir}" "${name}"`"
                  fi

                  bury_stash "${reposdir}" "${name}" "${oldstashdir}"
               ;;

               "set-remote")
                  log_info "Changing ${repotype}remote to \"${url}\""

                  local remote

                  remote="`git_get_default_remote "${stashdir}"`"
                  if [ -z "${remote}" ]
                  then
                     fail "Could not figure out a remote for \"$PWD/${stashdir}\""
                  fi
                  git_set_url "${stashdir}" "${remote}" "${url}"
               ;;

               *)
                  internal_fail "Unknown action item \"${item}\""
               ;;
            esac
         done

         if [ "${autoupdate}" = "YES" ]
         then
            bootstrap_auto_update "${name}" "${stashdir}"
         fi

         # create clone as it is now
         clone="`echo "${url};${dstdir};${branch};${scm};${tag}" | sed 's/;*$//'`"
      fi

      #
      # always remember, what we have now (except if its a minion)
      #
      if [ "${remember}" = "YES" ]
      then
         # branch could be overwritten
         log_debug "${C_INFO}Remembering ${clone} ..."

         remember_stash_of_repository "${clone}" \
                                      "${reposdir}" \
                                      "${name}"  \
                                      "${stashdir}" \
                                      "${PARENT_CLONE}"
      fi
      mark_stash_as_alive "${reposdir}" "${name}"
   done

   IFS="${DEFAULT_IFS}"
}

#
#
#
fetch_once_embedded_repositories()
{
   log_debug "fetch_once_embedded_repositories"

   (
      STASHES_DEFAULT_DIR=""
      STASHES_ROOT_DIR=""
      OPTION_ALLOW_CREATING_SYMLINKS="${OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS}" ;

      local clones

      clones="`read_root_setting "embedded_repositories"`" ;
      work_clones "${EMBEDDED_REPOS_DIR}" "${clones}" "NO"
   ) || exit 1
}


#
#
#
fetch_once_minions_embedded_repositories()
{
   log_debug "fetch_once_minions_embedded_repositories"

   local minions

   minions="`read_root_setting minions`"

   local minion

   IFS="
"
   for minion in ${minions}
   do
      IFS="${DEFAULT_IFS}"

      if [ -z "${minion}" ]
      then
         continue
      fi

      log_debug "${C_INFO}Doing minion \"${minion}\" ..."

      local autodir

      autodir="${BOOTSTRAP_DIR}.auto/.deep/${minion}.d"

      if [ ! -d "${autodir}" ]
      then
         log_fluff "${autodir} not present, so done"
         continue
      fi

      local autodir

      reposdir="${REPOS_DIR}/.deep/${minion}.d"

      (
         STASHES_DEFAULT_DIR=""
         STASHES_ROOT_DIR=""
         OPTION_ALLOW_CREATING_SYMLINKS="${OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS}" ;

         local clones

         clones="`read_setting "${autodir}/embedded_repositories"`" ;
         work_clones "${reposdir}" "${clones}" "NO"
      ) || exit 1
   done

   IFS="${DEFAULT_IFS}"
}


_fetch_once_deep_embedded_repository()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   local autodir

   autodir="${BOOTSTRAP_DIR}.auto/.deep/${name}.d"

   if [ ! -d "${autodir}" ]
   then
      log_fluff "${autodir} not present, so done"
      return
   fi

   reposdir="${reposdir}/.deep/${name}.d"
   (
      STASHES_DEFAULT_DIR=""
      STASHES_ROOT_DIR="${stashdir}"  # hackish
      OPTION_ALLOW_CREATING_SYMLINKS="${OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS}" ;
      PARENT_REPOSITORY_NAME="${name}"
      PARENT_CLONE="${clone}"

      local clones

      # ugliness
      clones="`read_setting "${autodir}/embedded_repositories"`" ;
      work_clones "${reposdir}" "${clones}" "NO"
   ) || exit 1
}


# but not minions
fetch_once_deep_embedded_repositories()
{
   log_debug "fetch_once_deep_embedded_repositories"

   local permissions

   walk_auto_repositories "repositories"  \
                          "_fetch_once_deep_embedded_repository" \
                          "${permissions}" \
                          "${REPOS_DIR}"
}


extract_minion_precis()
{
   local minions

   minions="`read_root_setting minions`"
   auto_update_minions "${minions}"
}


fetch_loop_repositories()
{
   local loops
   local before
   local after

   log_debug "fetch_loop_repositories"

   loops=""
   before=""

   __IGNORE__=""

   while :
   do
      loops="${loops}X"
      case "${loops}" in
         XXXXXXXXXXXXXXXX)
            internal_fail "Loop overflow in worker loop"
         ;;
      esac

      after="${before}"
      before="`read_root_setting "repositories" | sort`"
      if [ "${after}" = "${before}" ]
      then
         log_fluff "Repositories file is unchanged, so done"
         break
      fi

      if [ -z "${__IGNORE__}" ]
      then
         log_fluff "Get back in the ring to take another swing"
      fi

      __REFRESHED__=""

      work_clones "${REPOS_DIR}" "${before}" "YES"

      __IGNORE__="`add_line "${__IGNORE__}" "${__REFRESHED__}"`"

   done
}

                      #----#
### Main fetch loop   #    #    #----#
                      #----#    #----#    #----#

assume_stashes_are_zombies()
{
   if [ -d "${REPOS_DIR}" ]
   then
      zombify_embedded_repository_stashes
      [ "${OPTION_EMBEDDED_ONLY}" = "YES" ] && return

      zombify_repository_stashes
      zombify_deep_embedded_repository_stashes
   fi
}


bury_zombies_in_graveyard()
{
   if [ -d "${REPOS_DIR}" ]
   then
      bury_embedded_repository_zombies
      [ "${OPTION_EMBEDDED_ONLY}" = "YES" ] && return

      bury_repository_zombies
      bury_deep_embedded_repository_zombies
   fi
}


#
# the main fetch loop as documented somewhere with graphviz
#
fetch_loop()
{
   unpostpone_trace

   # this is wrong, we just do "stashes" though
   assume_stashes_are_zombies

   bootstrap_auto_create

   if is_master_bootstrap_project
   then
     log_info "Extracting minions' precis ..."

      extract_minion_precis

      fetch_once_minions_embedded_repositories
   fi

   log_info "Checking repositories ..."

   fetch_once_embedded_repositories

   if [ "${OPTION_EMBEDDED_ONLY}" = "NO" ]
   then
      fetch_loop_repositories

      fetch_once_deep_embedded_repositories || exit 1
   fi

   bootstrap_auto_final

   bury_zombies_in_graveyard
}

#
# the three commands
#
_common_fetch()
{

   fetch_loop "${REPOS_DIR}"

   #
   # do this afterwards, because brews will have been composited
   # now
   #
   case "${BREW_PERMISSIONS}" in
      fetch|update|upgrade)
         brew_install_brews
      ;;
   esac

   check_tars
}


_common_update()
{
   case "${BREW_PERMISSIONS}" in
      update|upgrade)
         brew_update_main
      ;;
   esac

   update_embedded_repositories
   [ "${OPTION_EMBEDDED_ONLY}" = "YES" ] && return

   update_repositories "$@"
   update_deep_embedded_repositories
}


_common_upgrade()
{
   case "${BREW_PERMISSIONS}" in
      upgrade)
         brew_upgrade_main
      ;;
   esac

   upgrade_embedded_repositories
   [ "${OPTION_EMBEDDED_ONLY}" = "YES" ] && return

   upgrade_repositories "$@"
   upgrade_deep_embedded_repositories

   _common_fetch  # update what needs to be update
}


_common_main()
{
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ]      && . mulle-bootstrap-repositories.sh
   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]          && . mulle-bootstrap-settings.sh

   local OPTION_CHECK_USR_LOCAL_INCLUDE="NO"
   local MULLE_FLAG_FOLLOW_SYMLINKS="NO"
   local OPTION_ALLOW_CREATING_SYMLINKS="NO"
   local OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS="NO"
   local OPTION_ALLOW_SEARCH_CACHES="YES"
   local OPTION_EMBEDDED_ONLY="NO"
   local OVERRIDE_BRANCH
   local DONT_WARN_SCRIPTS="NO"

   local ROOT_DIR="`pwd -P`"
   local CACHES_PATH
   local CLONE_CACHE

   #
   # where we look for symlink sources
   # user can set also set via environment "MULLE_BOOTSTRAP_CACHES_PATH"
   #
   # "repository" caches can and usually are outside the project folder
   # this can be multiple paths!
   CACHES_PATH="`read_config_setting "caches_path" "${MULLE_BOOTSTRAP_CACHES_PATH}"`"

   # stuff clones get intermediate saved too, default empty
   CLONE_CACHE="`read_config_setting "clone_cache"`"
   CACHES_PATH="`add_path "${CACHES_PATH}" "${CLONE_CACHE}"`"

   OPTION_CHECK_USR_LOCAL_INCLUDE="`read_config_setting "check_usr_local_include" "NO"`"
   OVERRIDE_BRANCH="`read_config_setting "override_branch"`"


   DONT_WARN_SCRIPTS="`read_config_setting "dont_warn_scripts" "${MULLE_FLAG_ANSWER:-NO}"`"

   if [ "${DONT_WARN_SCRIPTS}" = "YES" ]
   then
      log_verbose "Script checking disabled"
   fi

   case "${UNAME}" in
      mingw)
      ;;

      *)
         OPTION_ALLOW_CREATING_SYMLINKS="`read_config_setting "symlinks" "${MULLE_FLAG_ANSWER}"`"
         OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS="`read_config_setting "embedded_symlinks" "NO"`"
      ;;
   esac

   #
   # it is useful, that fetch understands build options and
   # ignores them
   #
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            ${USAGE}
         ;;

         -cu|--check-usr-local|--check-usr-local)
            OPTION_CHECK_USR_LOCAL_INCLUDE="YES"
         ;;

         -e|--embedded-only)
            OPTION_EMBEDDED_ONLY="YES"
         ;;

         # update symlinks, dangerous (duplicate to flags for laziness reasons)
         --follow-symlinks)
            MULLE_FLAG_FOLLOW_SYMLINKS="YES"
         ;;

         # allow creating symlinks instead of clones for repositories
         -l|--symlink-creation|--symlinks)
            OPTION_ALLOW_CREATING_SYMLINKS="YES"
         ;;

         #
         # create symlinks instead of clones for embedded_repositories
         # and deep embedded_repositories. If the clones are symlinked
         # this will be ignored, except if follow-symlinks is
         # active. --follow-symlinks is really not safe!
         #
         --embedded-symlink-creation|--embedded-symlinks)
            OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS="YES"
         ;;

         --no-caches)
            OPTION_ALLOW_SEARCH_CACHES="NO"
         ;;

         --no-symlink-creation|--no-symlinks)
            MULLE_FLAG_FOLLOW_SYMLINKS="NO"
            OPTION_ALLOW_CREATING_SYMLINKS="NO"
            OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS="NO"
         ;;

         # TODO: outdated!
         # build options with no parameters
         -K|--clean|-k|--no-clean|--use-prefix-libraries|--debug|--release)
            if [ -z "${MULLE_BOOTSTRAP_WILL_BUILD}" ]
            then
               log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown fetch option $1"
               ${USAGE}
            fi
         ;;

         # build options with one parameter
         # TODO: outdated!
         -j|--cores|-c|--configuration|--prefix)
            if [ -z "${MULLE_BOOTSTRAP_WILL_BUILD}" ]
            then
               log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown fetch option $1"
               ${USAGE}
            fi

            if [ $# -eq 1 ]
            then
               log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Missing parameter to fetch option $1"
               ${USAGE}
            fi
            shift
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown fetch option $1"
            ${USAGE}
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_BOOTSTRAP_AUTO_UPDATE_SH}" ]     && . mulle-bootstrap-auto-update.sh
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   [ -z "${MULLE_BOOTSTRAP_SCM_SH}" ]             && . mulle-bootstrap-scm.sh
   [ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ]         && . mulle-bootstrap-scripts.sh
   [ -z "${MULLE_BOOTSTRAP_ZOMBIFY_SH}" ]         && . mulle-bootstrap-zombify.sh

   #
   # should we check for '/usr/local/include/<name>' and don't fetch if
   # present (somewhat dangerous, because we do not check versions)
   #

   if [ "${COMMAND}" = "fetch" ]
   then
      if [ $# -ne 0 ]
      then
         log_error "Additional parameters not allowed for fetch (" "$@" ")"
         ${USAGE}
      fi
   fi

   #
   # Run prepare scripts if present
   #
   case "${COMMAND}" in
      update|upgrade)
         if dir_is_empty "${REPOS_DIR}"
         then
            log_info "Nothing to update, fetch first"

            return 0
         fi
      ;;
   esac

   local default_permissions

   #
   # possible values none|fetch|update|upgrade
   # the local scheme with addictions really works
   # best on darwin, linux can't use bottles locally
   #
   default_permissions="none"
   case "${UNAME}" in
      darwin|linux)
         default_permissions="upgrade"
      ;;
   esac

   BREW_PERMISSIONS="`read_config_setting "brew_permissions" "${default_permissions}"`"
   case "${BREW_PERMISSIONS}" in
      none|fetch|update|upgrade)
      ;;

      *)
        fail "brew_permissions must be either: none|fetch|update|upgrade)"
      ;;
   esac

   remove_file_if_present "${REPOS_DIR}/.build_done"
   remove_file_if_present "${REPOS_DIR}/.bootstrap_fetch_done"
   create_file_if_missing "${REPOS_DIR}/.bootstrap_fetch_started"

   if [ "${BREW_PERMISSIONS}" != "none" ]
   then
      [ -z "${MULLE_BOOTSTRAP_BREW_SH}" ] && . mulle-bootstrap-brew.sh
   fi

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   case "${COMMAND}" in
      update)
         _common_update "$@"
      ;;

      upgrade)
         _common_upgrade "$@"
      ;;
   esac

   _common_fetch "$@"

   remove_file_if_present "${REPOS_DIR}/.bootstrap_fetch_started"

   #
   # only say we are done if a build_order was created
   #
   if [ -f "${BOOTSTRAP_DIR}.auto/build_order" ]
   then
      create_file_if_missing "${REPOS_DIR}/.bootstrap_fetch_done"
   fi

   if read_yes_no_config_setting "upgrade_gitignore" "YES"
   then
      if [ -d .git ]
      then
         append_dir_to_gitignore_if_needed "${BOOTSTRAP_DIR}.auto"
         append_dir_to_gitignore_if_needed "${BOOTSTRAP_DIR}.local"
         append_dir_to_gitignore_if_needed "${DEPENDENCIES_DIR}"
         if [ "${brew_permissions}" != "none" ]
         then
            append_dir_to_gitignore_if_needed "${ADDICTIONS_DIR}"
         fi
         append_dir_to_gitignore_if_needed "${REPOS_DIR}"
         if [ ! -z "${STASHES_DEFAULT_DIR}" -a -d "${STASHES_DEFAULT_DIR}"  ]
         then
            append_dir_to_gitignore_if_needed "${STASHES_DEFAULT_DIR}"
         fi
      fi
   fi
}


fetch_main()
{
   log_debug "::: fetch begin :::"

   USAGE="fetch_usage"
   COMMAND="fetch"
   _common_main "$@"

   log_debug "::: fetch end :::"
}


update_main()
{
   log_debug "::: update begin :::"

   USAGE="fetch_usage"
   COMMAND="update"
   _common_main "$@"

   log_debug "::: update end :::"
}


upgrade_main()
{
   log_debug "::: upgrade begin :::"

   USAGE="fetch_usage"
   COMMAND="upgrade"
   _common_main "$@"

   log_debug "::: upgrade end :::"
}
