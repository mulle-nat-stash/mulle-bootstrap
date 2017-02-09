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
      -cs   :  check /usr/local for duplicates
      -e    :  fetch embedded repositories only
      -i    :  ignore wrongly checked out branches
      -nr   :  ignore .bootstrap folders of fetched repositories
      -u    :  try to update symlinked folders as well (not recommended)
      -es   :  allow embedded symlinks (very experimental)

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


write_protect_directory()
{
   if [ -d "$1" ]
   then
      #
      # ensure basic structure is there to squelch linker warnings
      #
      exekutor mkdir "$1/Frameworks" 2> /dev/null
      exekutor mkdir "$1/lib" 2> /dev/null
      exekutor mkdir "$1/include" 2> /dev/null

      log_info "Write-protecting ${C_RESET_BOLD}$1${C_INFO} to avoid spurious header edits"
      exekutor chmod -R a-w "$1"
   fi
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
   if [ "${tarballs}" != "" ]
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
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   assert_sane_parameters "empty reposdir is ok"

   local branchlabel

   branchlabel="branch"
   if [ -z "${branch}" -a ! -z "${tag}" ]
   then
      branchlabel="tag"
      branch="${tag}"
   fi

   local srcname
   local linkname
   local directory

   srcname="`basename -- ${url}`"
   linkname="`basename -- ${stashdir}`"
   directory="`dirname -- "${stashdir}"`"

   if [ "${MULLE_FLAG_EXECUTOR_DRY_RUN}" != "YES" ]
   then
      (
         cd "${directory}" ;
         if [ ! -e "${url}" ]
         then
            fail "${C_RESET}${C_BOLD}${url}${C_ERROR} does not exist ($PWD)"
         fi
      ) || exit 1
   fi

   #
   # relative paths look nicer, but could fail in more complicated
   # settings, when you symlink something, and that repo has symlinks
   # itself
   #
   if read_yes_no_config_setting "absolute_symlinks" "NO"
   then
      local real

      real="`( cd "${directory}" ; realpath "${url}")`" || fail "failed to get realpath of $url"
      log_fluff "Converted symlink \"${url}\" to \"${real}\""
      url="${real}"
   fi

   log_info "Symlinking ${C_MAGENTA}${C_BOLD}${srcname}${C_INFO} ..."
   exekutor ln -s -f "${url}" "${stashdir}" || fail "failed to setup symlink \"${stashdir}\" (to \"${url}\")"

   if [ ! -z "${branch}" ]
   then
      log_warning "The intended ${branchlabel} ${C_RESET_BOLD}${branch}${C_WARNING} will be ignored, because"
      log_warning "the repository is symlinked."
      log_warning "If you want to checkout this ${branchlabel} do:"
      log_warning "${C_RESET_BOLD}(cd ${stashdir}; git checkout ${GITOPTIONS} \"${branch}\" )${C_WARNING}"
   fi
}


ask_symlink_it()
{
   local  clone

   clone="$1"

   if [ ! -d "${clone}" ]
   then
      fail "You need to check out ${clone} yourself, as it's not there."
   fi

   #
   # check if checked out
   #
   if [ -d "${clone}"/.git ]
   then
       # if bare repo, we can only clone anyway
      if git_is_bare_repository "${clone}"
      then
         log_info "${clone} is a bare git repository. So cloning"
         log_info "is the only way to go."
         return 1
      fi

      flag=1  # means clone it
      if [ "${OPTION_ALLOW_CREATING_SYMLINKS}" = "YES" ]
      then
         local prompt

         prompt="Should ${clone} be symlinked instead of cloned ?
NO is safe, but you often say YES here."

         if [ ! -z "${tag}" ]
         then
            prompt="${prompt} (Since tag ${tag} is set, NO is more reasonable)"
         fi

         user_say_yes "$prompt"
         flag=$?
      fi

      if [ $flag -ne 0 ]
      then
         return $flag
      fi
   fi

   # can only symlink because not a .git repo yet
   if [ "${OPTION_ALLOW_CREATING_SYMLINKS}" = "YES" ]
   then
      log_info "${clone} is not a git repository (yet ?)"
      log_info "So symlinking is the only way to go."

      return 0
   fi

   case "${UNAME}" in
      minwgw)
         fail "Can't symlink on $UNAME, as symlinks don't exist"
      ;;

      *)
         fail "Can't symlink embedded repositories by default. \
Use --embedded-symlinks option to allow it"
      ;;
   esac
}



_search_git_repo_in_directory()
{
   local directory
   local name
   local branch

   [ $# -ne 3 ] && internal_fail "fail"

   directory="$1"
   name="$2"
   branch="$3"

   local found

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

   found="${directory}/${name}"
   log_fluff "Looking for \"${found}\""
   if [ -d "${found}" ]
   then
      log_fluff "Found \"${name}\" in \"${directory}\""

      echo "${found}"
      return
   fi

   found="${directory}/${name}.git"
   log_fluff "Looking for \"${found}\""
   if [ -d "${found}" ]
   then
      log_fluff "Found \"${name}.git\" in \"${directory}\""

      echo "${found}"
      return
   fi
}


search_git_repo_in_parent_of_root()
{
   local found
   local directory

   directory="`dirname -- "${ROOT_DIR}"`"
   found="`_search_git_repo_in_directory "${directory}" "$@"`" || exit 1
   if [ ! -z "${found}" ]
   then
      _relative_path_between "${found}" "`pwd -P`"
   fi
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

clone_or_symlink()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
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
      git|"" )
         operation="git_clone"
         scmflagsdefault="--recursive"
      ;;

      svn)
         operation="svn_checkout"
      ;;

      *)
         fail "Unknown scm system ${scm}"
      ;;
   esac

   local stashparent

   stashparent="`mkdir_stashparent_if_missing "${stashdir}"`"


   local found
   local script

   script="`find_root_setting_file "bin/clone.sh"`"

   if [ ! -z "${script}" ]
   then
      fetch__run_script "${script}" "$@"
      return $?
   fi

   local relative
   local name2

   relative="`compute_relative "${stashparent}"`"
   [ ! -z "${relative}" ] && relative="${relative}/"

   name2="`basename -- "${url}"`"  # only works for git really

   case "${url}" in
      /*)
         if ask_symlink_it "${url}"
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
         if [ "${OPTION_ALLOW_SEARCH_PARENT}" = "YES" ]
         then
            found="`search_git_repo_in_parent_of_root "${name}" "${branch}"`"
            if [ -z "${found}" ]
            then
               found="`search_git_repo_in_parent_of_root "${name2}" "${branch}"`"
            fi

            if [ ! -z "${found}" ]
            then
               [ "${OPTION_ALLOW_AUTOCLONE_PARENT}" = "YES" ] || user_say_yes "There is a \"${found}\" folder in the parent directory of this project.
(\"${PWD}\"). Use it ?"
               if [ $? -eq 0 ]
               then
                  url="${found}"

                  ask_symlink_it "${url}"
                  if [ $? -eq 0 ]
                  then
                     operation=link_command
                     url="${relative}${found}"
                  fi

                  log_info "Using ${C_MAGENTA}${C_BOLD}${found}${C_INFO} as URL"
               fi
            fi
         fi
      ;;
   esac

   local options

   options="`read_root_setting "${name}.scmflags" "${scmflagsdefault}"`"

   "${operation}" "${reposdir}" \
                  "${name}" \
                  "${url}" \
                  "${branch}" \
                  "${scm}" \
                  "${tag}" \
                  "${stashdir}" \
                  "${options}"

   warn_scripts_main "${stashdir}/.bootstrap" "${stashdir}" || fail "Ok, aborted"  #sic
}

##
## CLONE
##
_clone()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   [ $# -eq 7 ] || internal_fail "fail"

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
`perfect_relative_path_between "${PWD}" "${stashdir}"`\
\""
            log_info "${C_MAGENTA}${C_BOLD}${name}${C_INFO} is a minion, so cloning is skipped"
            return 1
         fi
      fi
      _bury_stash "${reposdir}" "${name}" "${stashdir}"
   fi

   if ! clone_or_symlink "$@"
   then
      fail "failed to fetch $url"
   fi
}


clone_repository()
{
   log_action "clone" "$@"

   _clone "$@"
}


##
## CHECKOUT
##
_checkout()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   local operation

   case "${scm}" in
      git|"" )
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
      fetch__run_script "${script}" "$@"
   else
      "${operation}" "$@"
   fi
}


checkout_repository()
{
   local url="$3"       # URL of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   if [ -L "${stashdir}" -a "${OPTION_ALLOW_FOLLOWING_SYMLINKS}" != "YES" ]
   then
      echo "Ignoring ${stashdir} because it's a symlink"
      return
   fi

   log_action "checkout" "$@"

   _checkout "$@"
}


##
## PULL
##
_pull()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   local operation

   case "${scm}" in
      git|"" )
         operation="git_pull"
      ;;
      svn)
         operation="svn_update"
      ;;
      *)
         fail "Unknown scm system ${scm}"
      ;;
   esac

   script="`find_build_setting_file "${name}" "bin/pull.sh"`"
   if [ ! -z "${script}" ]
   then
      fetch__run_script "${script}" "$@"
   else
      "${operation}" "$@"
   fi
}


update_repository()
{
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   if [ -L "${stashdir}" -a "${OPTION_ALLOW_FOLLOWING_SYMLINKS}" != "YES" ]
   then
      echo "Ignoring ${stashdir} because it's a symlink"
      return
   fi

   log_action "pull" "$@"

   _update "$@"
}


##
## UPDATE
##

_update()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   local operation

   case "${scm}" in
      git|"" )
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
      fetch__run_script "${script}" "$@"
   else
      "${operation}" "$@"
   fi
}


update_repository()
{
   log_action "update" "$@"

   _update "$@"
}


##
## UPDATE
##

_upgrade()
{
   local reposdir="$1"  # ususally .bootstrap.repos
   local name="$2"      # name of the clone
   local url="$3"       # URL of the clone
   local branch="$4"    # branch of the clone
   local scm="$5"       # scm to use for this clone
   local tag="$6"       # tag to checkout of the clone
   local stashdir="$7"  # stashdir of this clone (absolute or relative to $PWD)

   local operation

   case "${scm}" in
      git|"" )
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
      fetch__run_script "${script}" "$@"
   else
      "${operation}" "$@"
   fi
}


upgrade_repository()
{
   log_action "upgrade" "$@"

   _upgrade "$@"
}


#
# Walk repositories with a callback function
#
_operation_walk_repositories()
{
   local operation="$1" ; shift

   local permissions

   permissions=""
   if [ "${OPTION_ALLOW_FOLLOWING_SYMLINKS}" = "YES" ]
   then
      permissions="`add_line "${permissions}" "symlink"`"
   fi

   walk_repositories "repositories"  \
                     "${operation}" \
                     "${permissions}" \
                     "${REPOS_DIR}"
}


_operation_walk_embedded_repositories()
{
   local operation="$1" ; shift

   local permissions

   permissions=""
   if [ "${OPTION_ALLOW_FOLLOWING_SYMLINKS}" = "YES" ]
   then
      permissions="`add_line "${permissions}" "symlink"`"
   fi

   #
   # embedded repositories can't be symlinked by default
   # embedded repositories are by default not put into
   # stashes (for backwards compatibility)
   #
   (
      STASHES_DIR="" ;
      OPTION_ALLOW_CREATING_SYMLINKS="${OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS}" ;

      walk_repositories "embedded_repositories"  \
                        "${operation}" \
                        "${permissions}" \
                        "${REPOS_DIR}/.embedded"
   ) || exit 1
}


_operation_walk_deep_embedded_repositories()
{
   local operation="$1" ; shift

   local permissions

   permissions=""
   if [ "${OPTION_ALLOW_FOLLOWING_SYMLINKS}" = "YES" ]
   then
      permissions="`add_line "${permissions}" "symlink"`"
   fi

   (
      OPTION_ALLOW_CREATING_SYMLINKS="${OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS}" ;

      walk_deep_embedded_repositories "${operation}" \
                                      "${permissions}"
   ) || exit 1
}


##
## FETCH
##

did_fetch_repository()
{
   local name="$2"      # name of the clone

   fetch__run_build_settings_script "did-install" "${name}" "$@"
}


did_fetch_repositories()
{
   walk_clones "did_fetch_repository" "${REPOS_DIR}" "$@"
}


##
## UPDATE
##
update_repositories()
{
   _operation_walk_repositories "update_repository"
}


update_embedded_repositories()
{
   _operation_walk_embedded_repositories "update_repository"
}


update_deep_embedded_repositories()
{
   _operation_walk_deep_embedded_repositories "update_repository"
}


##
## UPGRADE
##
upgrade_repositories()
{
   _operation_walk_repositories "upgrade_repository"
}


upgrade_embedded_repositories()
{
   _operation_walk_embedded_repositories "upgrade_repository"
}


upgrade_deep_embedded_repositories()
{
   _operation_walk_deep_embedded_repositories "upgrade_repository"
}


did_upgrade_repository()
{
   local name="$2"      # name of the clone

   fetch__run_build_settings_script "did-upgrade" "${name}" "$@"
}


did_upgrade_repositories()
{
   walk_clones "did_upgrade_repository" "${REPOS_DIR}" "$@"
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
      log_fluff "URL ${url} repository line is unchanged"
      return
   fi

   local reposdir
   local name
   local url
   local branch
   local scm
   local tag
   local stashdir

   parse_clone "${clone}"

   if is_minion_bootstrap_directory "${stashdir}"
   then
      fail "\"${stashdir}\" is a minion. Don't hand edit master repositories."
   fi

   if [ "${scm}" != "${newscm}" ]
   then
      log_fluff "SCM has changed from \"${scm}\" to \"${newscm}\", need to refetch"
      echo "remove
clone"
      return
   fi

   if [ "${stashdir}" != "${newstashdir}" ]
   then
      log_fluff "Destination has changed from \"${stashdir}\" to \"${newstashdir}\", need to move"
      echo "move"
   fi

   #
   # if scm is not git, don't try to be clever
   #
   if [ ! -z "${scm}"  -a "${scm}" != "git" ]
   then
      echo "remove
clone"
      return
   fi

   if [ "${scm}" != "${newscm}" ]
   then
      echo "remove
clone"
      return
   fi

   if [ "${branch}" != "${newbranch}" ]
   then
      log_fluff "Branch has changed from \"${branch}\" to \"${newbranch}\", need to fetch"
      echo "pull"
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
      echo "pull"
   fi
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

   local actionitems
   local fetched
   local repotype
   local oldstashdir
   local url_is_stash

   case "${reposdir}" in
      *embedded)
        repotype="embedded "
      ;;

      *)
        repotype=""
      ;;
   esac

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
      # optimization, try to no redo fetches
      #
      echo "${__IGNORE__}" | fgrep -s -q -x "${clone}" > /dev/null
      if [ $? -eq 0 ]
      then
         continue
      fi

      __REFRESHED__="`add_line "${__REFRESHED__}" "${clone}"`"

      parse_clone "${clone}" || exit 1

      actionitems="`required_action_for_clone "${clone}" \
                                              "${reposdir}" \
                                              "${name}" \
                                              "${url}" \
                                              "${branch}" \
                                              "${scm}" \
                                              "${tag}" \
                                              "${stashdir}"`" || exit 1

      IFS="
"
      for item in ${actionitems}
      do
         IFS="${DEFAULT_IFS}"

         case "${item}" in
            "checkout")
               log_verbose "Checking out \"${tag}\" in ${repotype}\"`absolutepath ${stashdir}`\""

               checkout_repository "${reposdir}" \
                                   "${name}" \
                                   "${url}" \
                                   "${branch}" \
                                   "${scm}" \
                                   "${tag}" \
                                   "${stashdir}"
            ;;

            "clone")
               log_verbose "Cloning \"${url}\" into ${repotype}\"`absolutepath ${stashdir}`\""

               if clone_repository "${reposdir}" \
                                   "${name}" \
                                   "${url}" \
                                   "${branch}" \
                                   "${scm}" \
                                   "${tag}" \
                                   "${stashdir}"
               then
                  fetched="`add_line "${fetched}" "${name}"`"
               fi
            ;;

            "move")
               oldstashdir="`stash_of_repository "${reposdir}" "${name}"`"
               log_verbose "Moving ${repotype}stash \"${name}\" from \"${oldstashdir}\" to \"`absolutepath ${stashdir}`\""

               exekutor mv ${COPYMOVEFLAGS} "${oldstashdir}" "${stashdir}"
            ;;

            "pull")
               log_verbose "Pulling from \"${url}\" into ${repotype}\"`absolutepath ${stashdir}`\""

               pull_repository "${reposdir}" \
                               "${name}" \
                               "${url}" \
                               "${branch}" \
                               "${scm}" \
                               "${tag}" \
                               "${stashdir}"
            ;;

            "remove")
               log_verbose "Removing old ${repotype}stash \"`absolutepath ${oldstashdir}`\""

               oldstashdir="`stash_of_repository "${reposdir}" "${name}"`"
               rmdir_safer "${oldstashdir}"
            ;;

            "set-remote")
               log_verbose "Changing ${repotype}remote to \"${url}\""

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
         bootstrap_auto_update "${stashdir}"
      fi

      #
      # always remember, what we have now
      #
      remember_stash_of_repository "${clone}" \
                                   "${reposdir}" \
                                   "${name}"  \
                                   "${url}" \
                                   "${branch}" \
                                   "${scm}" \
                                   "${tag}" \
                                   "${stashdir}"

      mark_stash_as_alive "${reposdir}" "${name}"

      if [ ! -L "${stashdir}" -o "${OPTION_ALLOW_FOLLOWING_SYMLINKS}" = "YES" ]
      then
         (
            local embedded_clones;

            OPTION_ALLOW_CREATING_SYMLINKS="${OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS}" ;
            MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="YES" ;
            STASHES_DIR=""

            cd_physical "${stashdir}" &&
            embedded_clones="`read_root_setting "embedded_repositories"`" &&
            work_clones "${REPOS_DIR}/.embedded" "${embedded_clones}" "NO"  > /dev/null
         ) || exit 1
      else
         log_fluff "Not following \"${stashdir}\" to embedded repositories of \"${name}\" because it's a symlink"
         # but need to mark them as alive
         (
            cd_physical "${stashdir}" &&
            mark_all_stashes_as_alive "${REPOS_DIR}/.embedded"
         ) || exit 1
      fi
   done

   IFS="${DEFAULT_IFS}"

   if [ ! -z "${fetched}" ]
   then
      echo "${fetched}"
   fi
}


#
#
#
work_all_repositories()
{
   local fetched
   local all_fetched
   local loops

   local before
   local after

   (
      STASHES_DIR="" ;
      OPTION_ALLOW_CREATING_SYMLINKS="${OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS}" ;

      before="`read_root_setting "embedded_repositories"`" ;
      work_clones "${REPOS_DIR}/.embedded" "${before}" "NO"
   ) || exit 1

   [  -z "${STASHES_DIR}" ] && internal_fail "hein"

   if [ -z "${OPTION_EMBEDDED_ONLY}" ]
   then
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
         before="`read_root_setting "repositories" | sed 's/[ \t]*$//' | sort`"
         if [ "${after}" = "${before}" ]
         then
            log_fluff "Repositories file is unchanged, so done"
            break
         fi

         __REFRESHED__=""

         fetched="`work_clones "${REPOS_DIR}" "${before}" "YES"`" || exit 1
         all_fetched="`add_line "${all_fetched}" "${fetched}"`"

         __IGNORE__="`add_line "${__IGNORE__}" "${__REFRESHED__}"`"

         log_fluff "Get back in the ring to take another swing"
      done

      if [ ! -z "${fetched}" ]
      then
         echo "${fetched}"
      fi
   fi
}

                      #----#
### Main fetch loop   #    #    #----#
                      #----#    #----#    #----#

assume_stashes_are_zombies()
{
   zombify_embedded_repository_stashes
   if [ -z "${OPTION_EMBEDDED_ONLY}" ]
   then
      zombify_repository_stashes
      zombify_deep_embedded_repository_stashes
   fi
}


bury_zombies_in_graveyard()
{
   bury_embedded_repository_zombies
   if [ -z "${OPTION_EMBEDDED_ONLY}" ]
   then
      bury_repository_zombies
      bury_deep_embedded_repository_zombies
   fi
}


run_post_fetch_scripts()
{
   if [ -z "${OPTION_EMBEDDED_ONLY}" ]
   then
      did_fetch_repositories "$@"
      fetch__run_root_settings_script "post-fetch" "$@"
   fi
}


run_post_update_scripts()
{
   # makes no sense to me to run scripts here
   :
}


run_post_upgrade_scripts()
{
   if [ -z "${OPTION_EMBEDDED_ONLY}" ]
   then
      did_upgrade_repositories "$@"
      fetch__run_root_settings_script "post-upgrade" "$@"
   fi
}


#
# the main fetch loop as documented somewhere with graphviz
#
fetch_loop()
{
   local fetched
   local is_master

   unpostpone_trace

   is_master_bootstrap_project
   is_master=$?

   if [ "${is_master}" -ne 0 ]
   then
      assume_stashes_are_zombies
   else
      log_fluff "Skipping zombie checks, because project is master"
   fi

   bootstrap_auto_create

   fetched="`work_all_repositories`" || exit 1

   bootstrap_auto_final

   if [ "${is_master}" -ne 0 ]
   then
      bury_zombies_in_graveyard
   fi

   echo "${fetched}"
}

#
# the three commands
#
_common_fetch()
{
   local fetched

   fetched="`fetch_loop "${REPOS_DIR}"`" || exit 1

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

   run_post_fetch_scripts "${fetched}"
}


_common_update()
{
   case "${BREW_PERMISSIONS}" in
      update|upgrade)
         brew_update_main
      ;;
   esac

   update_embedded_repositories
   if [ ! -z "${OPTION_EMBEDDED_ONLY}" ]
   then
      return
   fi

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
   if [ ! -z "${OPTION_EMBEDDED_ONLY}" ]
   then
      return
   fi

   local upgraded=""

   upgraded="`upgrade_repositories "$@"`"
   upgrade_deep_embedded_repositories

   _common_fetch  # update what needs to be update

   run_post_upgrade_scripts "${upgraded}"
}


_common_main()
{
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ]      && . mulle-bootstrap-repositories.sh
   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]          && . mulle-bootstrap-settings.sh

   local OPTION_CHECK_USR_LOCAL_INCLUDE
   local OPTION_ALLOW_CREATING_SYMLINKS
   local OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS
   local OPTION_ALLOW_SEARCH_PARENT
   local OPTION_ALLOW_AUTOCLONE_PARENT
   local OPTION_EMBEDDED_ONLY

   OPTION_CHECK_USR_LOCAL_INCLUDE="`read_config_setting "check_usr_local_include" "NO"`"

   case "${UNAME}" in
      mingw)
         OPTION_ALLOW_CREATING_SYMLINKS=
      ;;

      *)
         OPTION_ALLOW_CREATING_SYMLINKS="`read_config_setting "symlink_allowed" "${MULLE_FLAG_ANSWER}"`"
      ;;
   esac

   OPTION_ALLOW_SEARCH_PARENT="${MULLE_FLAG_ANSWER}"
   OPTION_ALLOW_AUTOCLONE_PARENT="${MULLE_FLAG_ANSWER}"

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

         -aa|--allow-autoclone-parent)
            OPTION_ALLOW_SEARCH_PARENT="YES"
            OPTION_ALLOW_AUTOCLONE_PARENT="YES"
         ;;

         -ap|--allow-parent-search)
            OPTION_ALLOW_SEARCH_PARENT="YES"
         ;;

         -as|--allow-symlink-creation)
            OPTION_ALLOW_CREATING_SYMLINKS="YES"
         ;;

         -aes|--allow-embedded-symlink-creation|--embedded-symlinks)
            OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS="YES"
         ;;

         -cs|--check-usr-local-include)
            OPTION_CHECK_USR_LOCAL_INCLUDE="YES"
            ;;

         -e|--embedded-only)
            OPTION_EMBEDDED_ONLY="YES"
         ;;

         -fs|--follow-symlinks)
            OPTION_ALLOW_FOLLOWING_SYMLINKS="YES"
         ;;

         -in|--ignore-branch)
            OPTION_IGNORE_BRANCH="YES"
         ;;

         -np|--no-parent-search)
            OPTION_ALLOW_SEARCH_PARENT=
         ;;

         -ns|--no-symlink-creation|--no-symlinks)
            OPTION_ALLOW_CREATING_EMBEDDED_SYMLINKS=
            OPTION_ALLOW_CREATING_SYMLINKS=
         ;;


         # build options with no parameters
         -K|--clean|-k|--no-clean|--use-prefix-libraries|--debug|--release)
            if [ -z "${MULLE_BOOTSTRAP_WILL_BUILD}" ]
            then
               log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown fetch option $1"
               ${USAGE}
            fi
         ;;

         # build options with one parameter
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


   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   [ -z "${MULLE_BOOTSTRAP_SCM_SH}" ]             && . mulle-bootstrap-scm.sh
   [ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ]         && . mulle-bootstrap-scripts.sh
   [ -z "${MULLE_BOOTSTRAP_WARN_SCRIPTS_SH}" ]    && . mulle-bootstrap-warn-scripts.sh
   [ -z "${MULLE_BOOTSTRAP_AUTO_UPDATE_SH}" ]     && . mulle-bootstrap-auto-update.sh
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
   local fetched
   local upgraded

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

   remove_file_if_present "${REPOS_DIR}/.bootstrap_fetch_done"
   create_file_if_missing "${REPOS_DIR}/.bootstrap_fetch_started"

   if [ "${BREW_PERMISSIONS}" != "none" ]
   then
      [ -z "${MULLE_BOOTSTRAP_BREW_SH}" ] && . mulle-bootstrap-brew.sh
   fi

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   case "${COMMAND}" in
      fetch)
         _common_fetch "$@"
      ;;

      update)
         _common_update "$@"
      ;;

      upgrade)
         _common_upgrade "$@"
      ;;
   esac

   remove_file_if_present "${REPOS_DIR}/.bootstrap_fetch_started"
   create_file_if_missing "${REPOS_DIR}/.bootstrap_fetch_done"

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
         if [ "${STASHES_DIR}" = "stashes" ]
         then
            append_dir_to_gitignore_if_needed "${STASHES_DIR}"
         fi
      fi
   fi
}


fetch_main()
{
   log_fluff "::: fetch begin :::"

   USAGE="fetch_usage"
   COMMAND="fetch"
   _common_main "$@"

   log_fluff "::: fetch end :::"
}


update_main()
{
   log_fluff "::: update begin :::"

   USAGE="fetch_usage"
   COMMAND="update"
   _common_main "$@"

   log_fluff "::: update end :::"
}


upgrade_main()
{
   log_fluff "::: upgrade begin :::"

   USAGE="fetch_usage"
   COMMAND="upgrade"
   _common_main "$@"

   log_fluff "::: upgrade end :::"
}
