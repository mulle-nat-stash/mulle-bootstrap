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
. mulle-bootstrap-brew.sh
. mulle-bootstrap-scm.sh
. mulle-bootstrap-scripts.sh
. mulle-bootstrap-auto-update.sh


usage()
{
   cat <<EOF >&2
usage:
   mulle-bootstrap fetch [-f] <install|nonrecursive|update>
   -f           : override dirty harry check

   install      : clone or symlink non-exisiting repositories and other resources
   nonrecursive : like above, but ignore .bootstrap folders of repositories
   update       : execute `git pull` in fetched repositories

   You can specify the names of the repositories to update.
   Currently available names are:
EOF
   (cd "${CLONESFETCH_SUBDIR}" ; ls -1 ) 2> /dev/null
}



while :
do
   if [ "$1" = "-h" -o "$1" = "--help" ]
   then
      usage >&2
      exit 1
   fi

   if [ "$1" = "-f" ]
   then
      FORCE="YES"
      [ $# -eq 0 ] || shift
      continue
   fi

   break
done



if [ -z "${COMMAND}" ]
then
   COMMAND=${1:-"install"}
   [ $# -eq 0 ] || shift
fi

if [ "${MULLE_BOOTSTRAP}" = "mulle-bootstrap" ]
then
   COMMAND="install"
fi


case "$COMMAND" in
   install)
      ;;
   nonrecursive)
     COMMAND=install
     DONT_RECURSE="YES"
      ;;
   update)
      ;;
   *)
      usage >&2
      exit 1
      ;;
esac



#
# Use brews for stuff we don't tag
#
install_taps()
{
   local tap
   local taps

   log_fluff "Looking for taps"

   taps=`read_fetch_setting "taps" | sort | sort -u`
   if [ "${taps}" != "" ]
   then
      fetch_brew_if_needed

      local old

      old="${IFS:-" "}"
      IFS="
"
      for tap in ${taps}
      do
         IFS="${old}"
         exekutor "${BREW}" tap "${tap}" > /dev/null || exit 1
      done
      IFS="${old}"
   else
      log_fluff "No taps found"
   fi
}



write_protect_directory()
{
   if [ -d "${1}" ]
   then
      #
      # ensure basic structure is there to squelch linker warnings
      #
      exekutor mkdir "${1}/Frameworks" 2> /dev/null
      exekutor mkdir "${1}/lib" 2> /dev/null
      exekutor mkdir "${1}/include" 2> /dev/null

      log_info "Write-protecting ${C_RESET_BOLD}${1}${C_INFO} to avoid spurious header edits"
      exekutor chmod -R a-w "${1}"
   fi
}

#
# brews are now installed using a local brew
# if we are on linx
#
install_brews()
{
   local brew
   local brews
   local brewcmd

   install_taps

   log_fluff "Looking for brews"

   case "${COMMAND}" in
      install)
         brewcmd="install"
         ;;
      update)
         brewcmd="upgrade"
         ;;
   esac

   brews=`read_fetch_setting "brews" | sort | sort -u`
   if [ -z "${brews}" ]
   then
      log_fluff "No brews found"
      return
   fi

   if [ -d "${ADDICTION_SUBDIR}" ]
   then
      log_fluff "Unprotecting \"${ADDICTION_SUBDIR}\" for ${command}."
      exekutor chmod -R u+w "${ADDICTION_SUBDIR}"
   fi

   local old
   local flag

   old="${IFS:-" "}"
   IFS="
"
   for formula in ${brews}
   do
      IFS="${old}"

      if [ ! -x "${BREW}" ]
      then
         brew_update_if_needed "${formula}"
         flag=$?

         if [ $flag -eq 2 ]
         then
            log_info "No brewing being done."
            write_protect_directory "${ADDICTION_SUBDIR}"
            return 1
         fi
      fi

      local versions

      versions=""
      if [ "$brewcmd" = "install" ]
      then
         versions="`${BREW} ls --versions "${formula}" 2> /dev/null`"
      fi

      if [ -z "${versions}" ]
      then
         log_fluff "brew ${brewcmd} \"${formula}\""
         exekutor "${BREW}" "${brewcmd}" "${formula}" || exit 1

         log_info "Force linking it, in case it was keg-only"
         exekutor "${BREW}" link --force "${formula}" || exit 1
      else
         log_info "\"${formula}\" is already installed."
      fi
   done

   write_protect_directory "${ADDICTION_SUBDIR}"

   IFS="${old}"
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

   tarballs="`read_fetch_setting "tarballs" | sort | sort -u`"
   if [ "${tarballs}" != "" ]
   then
      local old

      old="${IFS:-" "}"
      IFS="
"
      for tar in ${tarballs}
      do
         IFS="${old}"
         if [ ! -f "$tar" ]
         then
            fail "tarball \"$tar\" not found"
         fi
         log_fluff "tarball \"$tar\" found"
      done
      IFS="${old}"
   else
      log_fluff "No tarballs found"
   fi
}


#
# Use gems for stuff we don't tag
#
# install_gems()
# {
#    local gems
#    local gem

#    log_fluff "Looking for gems"

#    gems="`read_fetch_setting "gems" | sort | sort -u`"
#    if [ "${gems}" != "" ]
#    then
#       local old

#       old="${IFS:-" "}"
#       IFS="
# "
#       for gem in ${gems}
#       do
#          IFS="${old}"
#          log_fluff "gem install \"${gem}\""

#          echo "gem needs sudo to install ${gem}" >&2
#          exekutor sudo gem install "${gem}" || exit 1
#       done
#       IFS="${old}"
#    else
#       log_fluff "No gems found"
#    fi
# }


#
# Use pips for stuff we don't tag
#
# install_pips()
# {
#    local pips
#    local pip

#    log_fluff "Looking for pips"

#    pips="`read_fetch_setting "pips" | sort | sort -u`"
#    if [ "${pips}" != "" ]
#    then
#       local old

#       old="${IFS:-" "}"
#       IFS="
# "
#       for pip in ${pips}
#       do
#          IFS="${old}"
#          log_fluff "pip install \"${gem}\""

#          echo "pip needs sudo to install ${pip}" >&2
#          exekutor sudo pip install "${pip}" || exit 1
#       done
#       IFS="${old}"
#    else
#       log_fluff "No pips found"
#    fi
# }


#
###
#
link_command()
{
   local src
   local dst
   local tag

   src="$1"
   dst="$2"
   tag="$3"

   local dstdir
   dstdir="`dirname -- "${dst}"`"

   if [ ! -e "${dstdir}/${src}" -a "${MULLE_BOOTSTRAP_DRY_RUN}" != "YES" ]
   then
      fail "${C_RESET}${C_BOLD}${dstdir}/${src}${C_ERROR} does not exist ($PWD)"
   fi

   if [ "${COMMAND}" = "install" ]
   then
      #
      # relative paths look nicer, but could fail in more complicated
      # settings, when you symlink something, and that repo has symlinks
      # itself
      #
      if read_yes_no_config_setting "absolute_symlinks" "NO"
      then
         local real

         real="`( cd "${dstdir}" ; realpath "${src}")`"
         log_fluff "Converted symlink \"${src}\" to \"${real}\""
         src="${real}"
      fi

      log_info "Symlinking ${C_MAGENTA}${C_BOLD}`basename -- ${src}`${C_INFO} ..."
      exekutor ln -s -f "$src" "$dst" || fail "failed to setup symlink \"$dst\" (to \"$src\")"

      if [ "$tag" != "" ]
      then
         local name

         name="`basename -- "${dst}"`"
         log_warning "tag ${tag} will be ignored, due to symlink" >&2
         log_warning "if you want to checkout this tag do:" >&2
         log_warning "${C_RESET}${C_BOLD}(cd .repos/${name}; git ${GITFLAGS} checkout \"${tag}\" )${C_WARNING}" >&2
      fi
   fi

   # when we link, we assume that dependencies are there
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

      flag=1  # mens clone it
      if [ "${SYMLINK_FORBIDDEN}" != "YES" ]
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

      [ $flag -eq 0 ]
      return $?
   fi

   # can only symlink because not a .git repo yet
   if [ "${SYMLINK_FORBIDDEN}" != "YES" ]
   then
      log_info "${clone} is not a git repository (yet ?)"
      log_info "So symlinking is the only way to go."
      return 0
   fi

   fail "Can't symlink"
}



log_fetch_action()
{
   local dstdir
   local url

   url="$1"
   dstdir="$2"

   local info

   if [ -L "${url}" ]
   then
      info=" symlinked "
   else
      info=" "
   fi

   log_fluff "Perform ${COMMAND}${info}${url} in ${dstdir} ..."
}


search_git_repo_in_parent_directory()
{
   local name
   local branch

   name="$1"
   branch="$2"

   local found

   if [ ! -z "${branch}" ]
   then
      found="../${name}.${branch}"
      if [ -d "${found}" ]
      then
         echo "${found}"
         return
      fi
   fi

   found="../${name}"
   if [ -d "${found}" ]
   then
      echo "${found}"
      return
   fi

   found="../${name}.git"
   if [ -d "${found}" ]
   then
      echo "${found}"
      return
   fi
}


checkout()
{
   local url
   local name
   local dstdir
   local branch
   local tag
   local scm

   name="$1"
   url="$2"
   dstdir="$3"
   branch="$4"
   tag="$5"
   scm="$6"

   [ ! -z "$name" ]   || internal_fail "name is empty"
   [ ! -z "$url" ]    || internal_fail "url is empty"
   [ ! -z "$dstdir" ] || internal_fail "dstdir is empty"

   local relative
   local name2

   relative="`dirname -- "${dstdir}"`"
   relative="`compute_relative "${relative}"`"
   if [ ! -z "${relative}" ]
   then
      relative="${relative}/"
   fi
   name2="`basename -- "${url}"`"  # only works for git really

   local operation
   local map
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
         fail "unknown scm system ${scm}"
         ;;
   esac

   local found
   local src
   local script

   src="${url}"
   script="`find_repo_setting_file "${name}" "bin/${COMMAND}.sh"`"

   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
   else
      case "${url}" in
         /*)
            if git_is_bare_repository "${url}"
            then
               :
            else
               ask_symlink_it "${src}"
               if [ $? -eq 0 ]
               then
                  operation=link_command
               fi
            fi
         ;;

         ../*|./*)
            if git_is_bare_repository "${url}"
            then
               :
            else
               ask_symlink_it "${src}"
               if [ $? -eq 0 ]
               then
                  operation=link_command
                  src="${relative}${url}"
               fi
            fi
         ;;

         *)
            found="`search_git_repo_in_parent_directory "${name}" "${branch}"`"
            if [ -z "${found}" ]
            then
               found="`search_git_repo_in_parent_directory "${name2}" "${branch}"`"
            fi

            if [ ! -z "${found}" ]
            then
               user_say_yes "There is a \"${found}\" folder in the parent directory of this project.
(\"${PWD}\"). Use it ?"
               if [ $? -eq 0 ]
               then
                  src="${found}"

                  if git_is_bare_repository "${src}"
                  then
                     :
                  else
                     ask_symlink_it "${src}"
                     if [ $? -eq 0 ]
                     then
                        operation=link_command
                        src="${relative}${found}"
                     fi
                  fi
               fi
            fi

         ;;
      esac

      local scmflags

      scmflags="`read_repo_setting "${name}" "checkout" "${scmflagsdefault}"`"
      "${operation}" "${src}" "${dstdir}" "${branch}" "${tag}" "${scmflags}"
      mulle-bootstrap-warn-scripts.sh "${dstdir}/.bootstrap" "${dstdir}" || fail "Ok, aborted"  #sic
   fi
}


ensure_clone_branch_is_correct()
{
   local dstdir
   local branch

   dstdir="${1}"
   branch="${2}"

   local actual

   if [ ! -z "${branch}" ]
   then
      actual="`git_get_branch "${dstdir}"`"
      if [ "${actual}" != "${branch}" ]
      then
         fail "Repository \"${dstdir}\" checked-out branch is \"${actual}\".
But \"${branch}\" is specified.
Suggested fix:
   mulle-bootstrap clean dist
   mulle-bootstrap"
      fi
   fi
}


did_clone_repository()
{
   local name
   local url
   local branch

   name="$1"
   url="$2"
   branch="$3"

   local dstdir

   dstdir="${CLONESFETCH_SUBDIR}/${name}"
   run_build_settings_script "${name}" "${url}" "${dstdir}" "did-install" "${dstdir}" "${name}"
}

#
# Use git clones for stuff that gets tagged
# if you specify ../ it will assume you have
# checked it out yourself, If there is something
# checked out already it will use it, or ask
# convention: .git suffix == repo to clone
#          no .git suffix, try to symlink
#
checkout_repository()
{
   local name
   local url
   local dstdir
   local branch

   name="$1"
   url="$2"
   dstdir="$3"
   branch="$4"

   local flag

   if [ ! -e "${dstdir}" ]
   then
      checkout "$@"
      flag=1

      if [ "${COMMAND}" = "install" -a "${DONT_RECURSE}" = "" ]
      then
         local old_bootstrap

         old_bootstrap="${BOOTSTRAP_SUBDIR}"

         BOOTSTRAP_SUBDIR="${dstdir}/.bootstrap"
         clone_embedded_repositories "${dstdir}/"
         BOOTSTRAP_SUBDIR="${old_bootstrap}"

         bootstrap_auto_update "${name}" "${url}" "${dstdir}"
         flag=$?
      fi

      run_build_settings_script "${name}" "${url}" "${dstdir}" "post-${COMMAND}" "$@"

      # means we recursed and should start fetch from top
      if [ ${flag} -eq 0 ]
      then
         return 1
      fi
   else
      ensure_clone_branch_is_correct "${dstdir}" "${branch}"

      log_fluff "Repository \"${dstdir}\" already exists"
   fi

   return 0
}



clone_repository()
{
   local name
   local url
   local branch
   local scm

   name="$1"
   url="$2"
   branch="$3"
   scm="$4"

   local tag
   local dstdir
   local flag
   local doit

   tag="`read_repo_setting "${name}" "tag"`" #repo (sic)
   dstdir="${CLONESFETCH_SUBDIR}/${name}"

   doit=1
   if [ "${DO_CHECK_USR_LOCAL_INCLUDE}" = "YES" ]
   then
      has_usr_local_include "${name}"
      doit=$?
   fi

   flag=0
   if [ $doit -ne 0 ]
   then
      log_fetch_action "${name}" "${dstdir}"

      # mark the checkout progress, so that we don't do incomplete fetches and
      # later on happily build

      create_file_if_missing "${CLONESFETCH_SUBDIR}/.fetch_update_started"

      checkout_repository "${name}" "${url}" "${dstdir}" "${branch}" "${tag}" "${scm}"
      flag=$?

      remove_file_if_present "${CLONESFETCH_SUBDIR}/.fetch_update_started"
   else
      log_info "${C_MAGENTA}${C_BOLD}${name}${C_INFO} is a system library, so not fetching it"
   fi

   return $flag
}



clone_repositories()
{
   local stop
   local clones
   local clone
   local old
   local name
   local url
   local fetched
   local match
   local branch
   local scm
   local rval

   old="${IFS:-" "}"
   fetched=""

   stop=0
   while [ $stop -eq 0 ]
   do
      stop=1

      clones="`read_fetch_setting "repositories"`"
      if [ "${clones}" != "" ]
      then
         ensure_clones_directory

         IFS="
"
         for clone in ${clones}
         do
            IFS="${old}"

            clone="`expanded_setting "${clone}"`"

            # avoid superflous updates
            match="`echo "${fetched}" | grep -x "${clone}"`"
            # could remove prefixes here https:// http://

            if [ "${match}" != "${clone}" ]
            then
               fetched="${fetched}
${clone}"

               name="`canonical_name_from_clone "${clone}"`"
               url="`url_from_clone "${clone}"`"
               branch="`branch_from_clone "${clone}"`"
               scm="`scm_from_clone "${clone}"`"

               clone_repository "${name}" "${url}" "${branch}" "${scm}"

               if [ $? -eq 1 ]
               then
                  stop=0
                  break
               fi
            fi
         done
      fi
   done

   IFS="
"
   for clone in ${fetched}
   do
      IFS="${old}"

      clone="`expanded_setting "${clone}"`"

      name="`canonical_name_from_clone "${clone}"`"
      url="`url_from_clone "${clone}"`"
      branch="`branch_from_clone "${clone}"`"

      did_clone_repository "${name}" "${url}" "${branch}"
   done

   IFS="${old}"
}


clone_embedded_repository()
{
   local dstprefix
   local clone

   dstprefix="$1"
   clone="$2"

   local name
   local url
   local dstdir
   local branch
   local tag
   local scm

   name="`canonical_name_from_clone "${clone}"`"
   url="`url_from_clone "${clone}"`"
   branch="`branch_from_clone "${clone}"`"
   scm="`scm_from_clone "${clone}"`"
   tag="`read_repo_setting "${name}" "tag"`" #repo (sic)
   dstdir="${dstprefix}${name}"

   log_fetch_action "${name}" "${dstdir}"

   if [ ! -d "${dstdir}" ]
   then
      create_file_if_missing "${CLONESFETCH_SUBDIR}/.fetch_update_started"

      #
      # embedded_repositories are just cloned, no symlinks,
      #
      local old_forbidden

      old_forbidden="${SYMLINK_FORBIDDEN}"

      SYMLINK_FORBIDDEN="YES"
      checkout "${name}" "${url}" "${dstdir}" "${branch}" "${tag}" "${scm}"
      SYMLINK_FORBIDDEN="${old_forbidden}"

      if read_yes_no_config_setting "update_gitignore" "YES"
      then
         if [ -d .git ]
         then
            append_dir_to_gitignore_if_needed "${dstdir}"
         fi
      fi

      # memo that we did this with a symlink
      # store it inside the possibly recursed dstprefix dependency
      local symlinkcontent
      local symlinkdir
      local symlinkrelative

      symlinkrelative=`compute_relative "${CLONESFETCH_SUBDIR}/.embedded"`
      symlinkdir="${dstprefix}${CLONESFETCH_SUBDIR}/.embedded"
      mkdir_if_missing "${symlinkdir}"
      symlinkcontent="${symlinkrelative}/${dstdir}"

      log_fluff "Remember embedded repository \"${name}\" via \"${symlinkdir}/${name}\""
      exekutor ln -s "${symlinkcontent}" "${symlinkdir}/${name}"

      run_build_settings_script "${name}" "${url}" "${dstdir}" "post-${COMMAND}" "$@"
   else
      ensure_clone_branch_is_correct "${dstdir}" "${branch}"

      log_fluff "Repository \"${dstdir}\" already exists"
   fi

   remove_file_if_present "${CLONESFETCH_SUBDIR}/.fetch_update_started"
}


clone_embedded_repositories()
{
   local dstprefix

   dstprefix="$1"

   local clones
   local clone
   local old

   old="${IFS:-" "}"

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="YES"
   export MULLE_BOOTSTRAP_SETTINGS_NO_AUTO

   clones="`read_fetch_setting "embedded_repositories"`"
   if [ "${clones}" != "" ]
   then
      IFS="
"
      for clone in ${clones}
      do
         IFS="${old}"

         clone="`expanded_setting "${clone}"`"

         clone_embedded_repository "${dstprefix}" "${clone}"
      done

      remove_file_if_present "${CLONESFETCH_SUBDIR}/.fetch_update_started"

   fi

   IFS="${old}"

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO=
}


# return 0, all cool
# return 1, is symlinked
# return 2, .bootstrap/repositories changed
# return 3, is symlinked and .bootstrap/repositories changed

update()
{
   local name
   local url
   local branch
   local tag
   local dstdir
   local scm

   name="$1"
   url="$2"
   dstdir="$3"
   branch="$4"
   tag="$5"
   scm="$6"

   [ ! -z "$url" ]           || internal_fail "url is empty"
   exekutor [ -d "$dstdir" ] || internal_fail "dstdir \"${dstdir}\" is wrong ($PWD)"
   [ ! -z "$name" ]          || internal_fail "name is empty"

   local operation

   case "${scm}" in
      git|"" )
         operation="git_pull"
         ;;
      svn)
         operation="svn_update"
         ;;
      *)
         fail "unknown scm system ${scm}"
         ;;
   esac

   local script
   local before_r
   local before_e
   local after_r
   local after_e
   local rval

   before_r=`modification_timestamp "${dstdir}/.bootstrap/repositories" 2> /dev/null`
   before_e=`modification_timestamp "${dstdir}/.bootstrap/embedded_repositories" 2> /dev/null`

   rval=0
   if [ ! -L "${dstdir}" ]
   then
      run_repo_settings_script "${name}" "${dstdir}" "pre-update" "$@"

      script="`find_repo_setting_file "${name}" "bin/update.sh"`"
      if [ ! -z "${script}" ]
      then
         run_script "${script}" "$@"
      else
         "${operation}" "${dstdir}" "${branch}" "${tag}"
      fi

      run_repo_settings_script "${name}" "${dstdir}" "post-update" "$@"
   else
      ensure_clone_branch_is_correct "${dstdir}" "${branch}"
      log_info "Repository ${C_MAGENTA}${C_BOLD}${name}${C_INFO} exists and is symlinked, so not updated."

      rval=1
   fi

   after_r=`modification_timestamp "${dstdir}/.bootstrap/repositories" 2> /dev/null`
   after_e=`modification_timestamp "${dstdir}/.bootstrap/embedded_repositories" 2> /dev/null`

   if [ "${before_r}" != "${after_r}" -o "${before_e}" != "${after_e}" ]
   then
      rval="`expr "$rval" + 2`"
   fi

   return "$rval"
}


update_repository()
{
   local name
   local url
   local branch
   local dstdir

   name="$1"
   url="$2"
   branch="$3"
   dstdir="${CLONESFETCH_SUBDIR}/${name}"

   local name
   local tag
   local rval

   tag="`read_repo_setting "${name}" "tag"`" #repo (sic)

   exekutor [ -x "${dstdir}" ] || fail "\"${name}\" is not accesible anymore in \"repositories\""

   log_fetch_action "${url}" "${dstdir}"

   update "${name}" "${url}" "${dstdir}" "${branch}" "${tag}"
   rval=$?
   #update will return 1 if repo is symlinked

   if [ "${DONT_RECURSE}" = "" ]
   then
      if [ $rval -eq 0 -o $rval -eq 2 ]
      then
         local old_bootstrap
#      local old_fetch

         old_bootstrap="${BOOTSTRAP_SUBDIR}"
#      old_fetch="${CLONESFETCH_SUBDIR}"

         BOOTSTRAP_SUBDIR="${dstdir}/.bootstrap"
#      CLONESFETCH_SUBDIR="${dstdir}/.repos"

         update_embedded_repositories "${dstdir}/"

         BOOTSTRAP_SUBDIR="${old_bootstrap}"
#      CLONESFETCH_SUBDIR="${old_fetch}"
      fi
   fi

   ensure_clone_branch_is_correct "${dstdir}" "${branch}"
   [ $rval -eq 0 -o $rval -eq 2 ]
   return $?
}


did_update_repository()
{
   local name
   local url

   name="$1"
   url="$2"

   local dstdir

   dstdir="${CLONESFETCH_SUBDIR}/${name}"

   run_build_settings_script "${name}" "${url}" "${dstdir}" "did-update" "${dstdir}" "${name}"
}


#
# Use git clones for stuff that gets tagged
# if you specify ../ it will assume you have
# checked it out yourself, If there is something
# checked out already it will use it, or ask
# convention: .git suffix == repo to clone
#          no .git suffix, try to symlink
#
update_repositories()
{
   local clones
   local clone
   local name
   local i
   local old

   old="${IFS:-" "}"

   if [ $# -ne 0 ]
   then
      IFS="
"
      for name in "$@"
      do
         IFS="${old}"
         create_file_if_missing "${CLONESFETCH_SUBDIR}/.fetch_update_started"
            update_repository "${name}" "${CLONESFETCH_SUBDIR}/${name}"
         remove_file_if_present "${CLONESFETCH_SUBDIR}/.fetch_update_started"
      done

      IFS="
"
      for name in "$@"
      do
         IFS="${old}"
         create_file_if_missing "${CLONESFETCH_SUBDIR}/.fetch_update_started"
            did_update_repository "${name}" "${CLONESFETCH_SUBDIR}/${name}"
         remove_file_if_present "${CLONESFETCH_SUBDIR}/.fetch_update_started"
         done
      IFS="${old}"
      return
   fi

   local stop
   local url
   local updated
   local match
   local branch
   local scm
   local dstdir
   local rval

   updated=""

   stop=0
   while [ $stop -eq 0 ]
   do
      stop=1

      clones="`read_fetch_setting "repositories"`"
      clones="`echo "${clones}" | sed '1!G;h;$!d'`"  # reverse lines

      if [ "${clones}" != "" ]
      then
         IFS="
"
         for clone in ${clones}
         do
            IFS="${old}"

            clone="`expanded_setting "${clone}"`"

            # avoid superflous updates
            match="`echo "${updated}" | grep -x "${clone}"`"

            if [ "${match}" != "${clone}" ]
            then
               updated="${updated}
${clone}"

               name="`canonical_name_from_clone "${clone}"`"
               url="`url_from_clone "${clone}"`"
               branch="`branch_from_clone "${clone}"`"

               dstdir="${CLONESFETCH_SUBDIR}/${name}"

               create_file_if_missing "${CLONESFETCH_SUBDIR}/.fetch_update_started"

                  if [ -e "${dstdir}" ]
                  then
                     update_repository "${name}" "${url}" "${branch}"
                     rval=$?
                  else
                     scm="`scm_from_clone "${clone}"`"
                     clone_repository "${name}" "${url}" "${branch}" "${scm}"
                     rval=1
                  fi

               remove_file_if_present "${CLONESFETCH_SUBDIR}/.fetch_update_started"


               if [ $rval -eq 1 ]
               then
                  stop=0
                  break
               fi
            fi
         done
      fi
   done

   IFS="${old}"
}


update_embedded_repositories()
{
   local dstprefix

   dstprefix="$1"

   local clones
   local clone
   local old
   local name
   local url
   local branch
   local scm

   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="YES"
   export MULLE_BOOTSTRAP_SETTINGS_NO_AUTO

   old="${IFS:-" "}"

   clones="`read_fetch_setting "embedded_repositories"`"
   clones="`echo "${clones}" | sed '1!G;h;$!d'`"  # reverse lines

   if [ "${clones}" != "" ]
   then
      IFS="
"
      for clone in ${clones}
      do
         IFS="${old}"

         clone="`expanded_setting "${clone}"`"

         name="`canonical_name_from_clone "${clone}"`"
         url="`url_from_clone "${clone}"`"
         branch="`branch_from_clone "${clone}"`"

         tag="`read_repo_setting "${name}" "tag"`" #repo (sic)
         dstdir="${dstprefix}${name}"

         local doit

         doit=1
         if [ "${DO_CHECK_USR_LOCAL_INCLUDE}" = "YES" ]
         then
            has_usr_local_include "${name}"
            doit=$?
         fi

         if [ $doit -ne 0 ]
         then
            log_fetch_action "${name}" "${dstdir}"

            create_file_if_missing "${CLONESFETCH_SUBDIR}/.fetch_update_started"

            if [ -e "${dstdir}" ]
            then
               update "${name}" "${url}" "${dstdir}" "${branch}" "${tag}"
            else
               clone_embedded_repository "${dstprefix}" "${clone}"
            fi

            remove_file_if_present "${CLONESFETCH_SUBDIR}/.fetch_update_started"
         else
            log_info "${C_MAGENTA}${C_BOLD}${name}${C_INFO} is a system library, so not updating"
         fi
      done
   fi

   IFS="${old}"
   MULLE_BOOTSTRAP_SETTINGS_NO_AUTO=
}


main()
{
   log_verbose "::: fetch :::"

   SYMLINK_FORBIDDEN="`read_config_setting "symlink_forbidden"`"
   export SYMLINK_FORBIDDEN

   #
   # should we check for '/usr/local/include/<name>' and don't fetch if
   # present (somewhat dangerous, because we do not check versions)
   #
   DO_CHECK_USR_LOCAL_INCLUDE="`read_config_setting "check_usr_local_include" "NO"`"
   export DO_CHECK_USR_LOCAL_INCLUDE

   if [ "${COMMAND}" = "install" ]
   then
      if [ $# -ne 0 ]
      then
         log_error  "Additional parameters not allowed for install"
         usage >&2
         exit 1
      fi
   fi

   [ -z "${FORCE}" ] && ensure_consistency

   #
   # Run prepare scripts if present
   #
   if [ "${COMMAND}" = "install" ]
   then
       install_brews

#
# remove these, as they aren't installing locally
#
#      install_gems
#      install_pips

      clone_repositories
      clone_embedded_repositories

      check_tars
   else
      update_repositories "$@"
      update_embedded_repositories
   fi

   #
   # Run prepare scripts if present
   #
   create_file_if_missing "${CLONESFETCH_SUBDIR}/.fetch_update_started"

   run_fetch_settings_script "post-${COMMAND}" "$@"

   remove_file_if_present "${CLONESFETCH_SUBDIR}/.fetch_update_started"

   if read_yes_no_config_setting "update_gitignore" "YES"
   then
      if [ -d .git ]
      then
         append_dir_to_gitignore_if_needed "${BOOTSTRAP_SUBDIR}.auto"
         append_dir_to_gitignore_if_needed "${BOOTSTRAP_SUBDIR}.local"
         append_dir_to_gitignore_if_needed "${DEPENDENCY_SUBDIR}"
         append_dir_to_gitignore_if_needed "${ADDICTION_SUBDIR}"
         append_dir_to_gitignore_if_needed "${CLONES_SUBDIR}"
      fi
   fi
}

main "$@"
