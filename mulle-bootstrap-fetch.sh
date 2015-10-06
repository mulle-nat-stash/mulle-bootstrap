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
. mulle-bootstrap-warn-scripts.sh
. mulle-bootstrap-local-environment.sh
. mulle-bootstrap-brew.sh


usage()
{
   cat <<EOF
usage: fetch <install|nonrecursive|update> [repos]*
   install      : clone or symlink non-exisiting repositories and other resources
   nonrecursive : like above, but ignore .bootstrap folders of repositories
   update       : pull repositories

   You can specify the names of the repositories to update or fetch.
   Currently available names are:
EOF
   (cd "${CLONES_SUBDIR}" ; ls -1d ) 2> /dev/null
}


check_and_usage_and_help()
{
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
}


if [ "$1" = "-h" -o "$1" = "--help" ]
then
   COMMAND=help
else
   if [ -z "${COMMAND}" ]
   then
      COMMAND=${1:-"install"}
      shift
   fi

   if [ "${MULLE_BOOTSTRAP}" = "mulle-bootstrap" ]
   then
      COMMAND="install"
   fi
fi

check_and_usage_and_help


link_command()
{
   local src
   local dst
   local tag
   local name

   src="$1"
   dst="$2"
   tag="$3"

   if [ -e "${src}" ]
   then
      echo "${src} does not exist ($PWD)" >&2
      exit 1
   fi

   if [ "${COMMAND}" = "install" ]
   then
      exekutor ln -s -f "$src" "$dst" || fail "failed to setup symlink \"$dst\" (to \"$src\")"
      if [ "$tag" != "" ]
      then
         name="`basename "${dst}"`"
         echo "tag ${tag} will be ignored, due to symlink" >&2
         echo "if you want to checkout this tag do:" >&2
         echo "(cd .repos/${name}; git ${GITFLAGS} checkout \"${tag}\" )" >&2
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
      echo "You need to check out ${clone} yourself, as it's not there." >&2 || exit 1
   fi

   SYMLINK_FORBIDDEN="`read_config_setting "symlink_forbidden"`"

   # check if checked out
   if [ -d "${clone}"/.git ]
   then
      flag=1  # mens clone it
      if [ "${SYMLINK_FORBIDDEN}" != "YES" ]
      then
         user_say_yes "Should ${clone} be symlinked instead of cloned ?
   You usually say NO to this, even more so, if tag is set (tag=${tag})"
         flag=$?
      fi
      [ $flag -eq 0 ]
      return $?
   fi

    # if bare repo, we can only clone anyway
   if [ -f "${clone}"/HEAD -a -d "${clone}/refs" ]
   then
      echo "${clone} looks like a bare git repository. So cloning" >&2
      echo "is the only way to go." >&2
      return 1
   fi

   # can only symlink because not a .git repo yet
   if [ "${SYMLINK_FORBIDDEN}" != "YES" ]
   then
      echo "${clone} is not a git repository (yet ?)" >&2
      echo "So symlinking is the only way to go." >&2
      return 0
   fi

   echo "SYMLINK_FORBIDDEN=YES, can't symlink" >&2
   exit 1
}


run_fetch_settings_script()
{
   local  name

   name="$1"
   shift

   [ -z "$name" ] && internal_fail "name is empty"

   local script

   script="`read_fetch_setting "bin/${name}.sh"`"
   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
   fi
}


checkout()
{
   local clone
   local name1
   local name2
   local tag
   local dstname

   clone="$1"
   name1="$2"
   name2="$3"
   dstname="$4"
   tag="$5"

   [ -z "$clone" ]    && internal_fail "clone is empty"
   [ -z "$name1" ]    && internal_fail "name1 is empty"
   [ -z "$name2" ]    && internal_fail "name2 is empty"
   [ -z "$dstname" ]  && internal_fail "dstname is empty"

   local srcname
   local operation
   local flag
   local found

   #
   # this implicitly ensures, that these folders are
   # movable and cleanable by mulle-bootstrap
   # so ppl can't really use  src mistakenly

   if [ -e "${DEPENDENCY_SUBDIR}" -o -e "${CLONESBUILD_SUBDIR}" ]
   then
      log_error "Stale folders ${DEPENDENCY_SUBDIR} and/or ${CLONESBUILD_SUBDIR} found."
      log_error "Please remove them before continuing."
      log_info  "Suggested command: ${C_WHITE}mulle-bootstrap clean output"
      exit 1
   fi

   srcname="${clone}"
   script="`read_repo_setting "${name1}" "bin/${COMMAND}.sh"`"
   operation="git_clone"

   # simplify this crap copy/paste code
   if [ ! -z "${script}" ]
   then
      run_script "${script}" "$@"
   else
      case "${clone}" in
         /*)
            ask_symlink_it "${clone}"
            if [ $? -eq 0 ]
            then
               operation=link_command
            fi
         ;;

         ../*|./*)
            ask_symlink_it "${clone}"
            if [ $? -eq 0 ]
            then
               operation=link_command
               srcname="${CLONES_RELATIVE}/${clone}"
            fi
         ;;

         *)
            found="../${name1}.${tag}"
            if [ ! -d "${found}" ]
            then
               found="../${name1}"
               if [ ! -d "${found}" ]
               then
                  found="../${name2}.${tag}"
                  if [ ! -d "${found}" ]
                  then
                     found="../${name2}"
                     if [ ! -d "${found}" ]
                     then
                        found=""
                     fi
                  fi
               fi
            fi

            if [ "${found}" != ""  ]
            then
               user_say_yes "There is a ${found} folder in the parent
directory of this project.
Use it ?"
               if [ $? -eq 0 ]
               then
                  srcname="${found}"
                  ask_symlink_it "${srcname}"
                  if [ $? -eq 0 ]
                  then
                     operation=link_command
                     srcname="${CLONES_RELATIVE}/${found}"
                  fi
               fi
            fi
         ;;
      esac

      "${operation}" "${srcname}" "${dstname}" "${tag}"
       warn_scripts "${dstname}/.bootstrap" "${dstname}" || exit 1 # sic
   fi

   run_fetch_settings_script "post-install"
}


git_checkout_tag()
{
   local dst
   local tag

   dst="$1"
   tag="$2"

   log_info "Checking out ${C_MAGENTA}${tag}${C_INFO} ..."
   ( exekutor cd "${dst}" ; exekutor git checkout ${GITFLAGS} "${tag}" )

   if [ $? -ne 0 ]
   then
      log_error "Checkout failed, moving ${C_CYAN}${dst}${C_ERROR} to {C_CYAN}${dst}.failed${C_ERROR}"
      log_error "You need to fix this manually and then move it back."
      log_info "Hint: check ${BOOTSTRAP_SUBDIR}/`basename "${dst}"`/TAG" >&2

      rmdir_safer "${dst}.failed"
      exekutor mv "${dst}" "${dst}.failed"
      exit 1
   fi
}


git_clone()
{
   local src
   local dst
   local tag

   src="$1"
   dst="$2"
   tag="$3"

   [ -z "$src" ] && internal_fail "src is empty"
   [ -z "$dst" ] && internal_fail "dst is empty"

   log_info "Cloning ${C_WHITE}${src}${C_INFO} ..."
   exekutor git clone ${GITFLAGS} "${src}" "${dst}" || fail "git clone of \"${src}\" into \"${dst}\" failed"

   if [ "${tag}" != "" ]
   then
      git_checkout_tag "${dst}" "${tag}"
   fi
}


git_pull()
{
   local dst
   local tag

   dst="$1"
   tag="$2"

   [ -z "$dst" ] && internal_fail "dst is empty"

   log_info "Updating ${C_WHITE}${dst}${C_INFO} ..."
   ( exekutor cd "${dst}" ; exekutor git pull ${GITFLAGS} ) || fail "git pull of \"${dst}\" failed"

   if [ "${tag}" != "" ]
   then
      git_checkout_tag "${dst}" "${tag}"
   fi
}


INHERIT_SETTINGS="taps brews gits pips gems buildorder buildignore"


bootstrap_recurse()
{
   local dst
   local name

   dst="$1"

   [ ! -z "${dst}" ] || internal_fail "dst was empty"
   [ "${PWD}" != "${dst}" ] || internal_fail "configuration error"

   name="`basename "${dst}"`"

   # contains own bootstrap ? and not a symlink
   if [ ! -d "${dst}/.bootstrap" ] # -a ! -L "${dst}" ]
   then
      log_fluff "no .bootstrap folder in \"${dst}\" found"
      return 1
   fi

   log_info "Recursively acquiring ${dstname} .bootstrap settings ..."

   # prepare auto folder if it doesn't exist yet
   if [ ! -d "${BOOTSTRAP_SUBDIR}.auto" ]
   then
      echo "Found a .bootstrap folder for `basename "${dst}"` will set up ${BOOTSTRAP_SUBDIR}.auto" >&2

      mkdir_if_missing "${BOOTSTRAP_SUBDIR}.auto/settings"
      for i in $INHERIT_SETTINGS
      do
         if [ -f "${BOOTSTRAP_SUBDIR}.local/${i}" ]
         then
            exekutor cp "${BOOTSTRAP_SUBDIR}}.local/${i}" "${BOOTSTRAP_SUBDIR}.auto/${i}" || exit 1
         else
            if [ -f "${BOOTSTRAP_SUBDIR}/${i}" ]
            then
               exekutor cp "${BOOTSTRAP_SUBDIR}/${i}" "${BOOTSTRAP_SUBDIR}.auto/${i}" || exit 1
            fi
         fi
      done
   fi

   #
   # prepend new contents to old contents
   # of a few select and known files
   #
   for i in $INHERIT_SETTINGS
   do
      if [ -f "${dst}/.bootstrap/${i}" ]
      then
         if [ -f "${BOOTSTRAP_SUBDIR}.auto/${i}" ]
         then
            exekutor mv "${BOOTSTRAP_SUBDIR}.auto/${i}" "${BOOTSTRAP_SUBDIR}.auto/${i}.tmp" || exit 1
            exekutor cat "${dst}/.bootstrap/${i}" "${BOOTSTRAP_SUBDIR}.auto/${i}.tmp" > "${BOOTSTRAP_SUBDIR}.auto/${i}"  || exit 1
            exekutor rm "${BOOTSTRAP_SUBDIR}.auto/${i}.tmp" || exit 1
         else
            exekutor cp "${dst}/.bootstrap/${i}" "${BOOTSTRAP_SUBDIR}.auto/${i}" || exit 1
         fi
      fi
   done

   #
   # link up other non-inheriting settings
   #
   if dir_has_files "${dst}/.bootstrap/settings"
   then
      local relative

      mkdir_if_missing "${BOOTSTRAP_SUBDIR}.auto/settings/${name}"
      relative="`compute_relative "${BOOTSTRAP_SUBDIR}"`"
      exekutor find "${dst}/.bootstrap/settings" -type f -depth 1 -print0 | \
         exekutor xargs -0 -I % ln -s -f "${relative}/../../"% "${BOOTSTRAP_SUBDIR}.auto/settings/${name}"

      # flatten folders into our own settings
      exekutor find "${dst}/.bootstrap/settings" -type d -depth 1 -print0 | \
         exekutor xargs -0 -I % ln -s -f "${relative}/../"% "${BOOTSTRAP_SUBDIR}.auto/settings"
   fi


   return 0
}


ensure_clones_directory()
{
   if [ ! -d "${CLONES_FETCH_SUBDIR}" ]
   then
      if [ "${COMMAND}" = "update" ]
      then
         fail "install first before upgrading"
      fi
      mkdir_if_missing "${CLONES_FETCH_SUBDIR}"
   fi
}


mark_all_zombies()
{
   local i

      # first mark all repos as stale
   if dir_has_files "${CLONES_FETCH_SUBDIR}"
   then
      log_fluff "Marking all repositories as zombies for now"

      for i in `ls -1d "${CLONES_FETCH_SUBDIR}/"*`
      do
         if [ -d "${i}" -o -L "${i}" ]
         then
            exekutor chmod -h 000 "${i}"
         fi
      done
   fi
}


mark_alive()
{
   local dstname

   dstname="$1"

   local permission

   # mark as alive
   if [ -d "${dstname}" -o -L "${dstname}" ] && [ ! -r "${dstname}" ]
   then
      permission="`lso "${CLONES_FETCH_SUBDIR}"`"
      [ ! -z "$permission" ] || fail "failed to get permission of ${CLONES_FETCH_SUBDIR}"
      exekutor chmod -h "${permission}" "${dstname}"

      log_fluff "Marked \${dstname}\" as alive"
   fi
}


log_fetch_action()
{
   local dstname
   local clone

   clone="$1"
   dstname="$2"

   local info

   if [ -L "${clone}" ]
   then
      info="symlinked"
   else
      info=" "
   fi

   log_fluff "$COMMAND ${info}${clone} in ${dstname} ..."
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
   local dstname

   dstname="$4"

   if [ ! -e "${dstname}" ]
   then
      checkout "$@"
      if [ "${COMMAND}" = "install" -a "${DONT_RECURSE}" = "" ]
      then
         bootstrap_recurse "${dstname}"
         if [ $? -eq 0 ]
         then
            return 1
         fi
      fi
   else
      log_fluff "Repository \"${dstname}\" already exists"
   fi
   return 0
}


clone_repository()
{
   local clone

   clone="$1"

   local name1
   local name2
   local tag
   local dstname

   name1="`basename "${clone}" .git`"
   name2="`basename "${clone}"`"
   tag="`read_repo_setting "${name1}" "tag"`" #repo (sic)

   dstname="${CLONES_FETCH_SUBDIR}/${name1}"

   mark_alive "${dstname}"
   log_fetch_action "${clone}" "${dstname}"

   checkout_repository "${clone}" "${name1}" "${name2}" "${dstname}" "${tag}"
}


clone_repositories()
{
   if [ $# -ne 0 ]
   then
      log_error  "Additional parameters not allowed for install"
      usage >&2
      exit 1
   fi

   local stop
   local clones
   local clone

   mark_all_zombies

   stop=0
   while [ $stop -eq 0 ]
   do
      stop=1

      clones="`read_fetch_setting "gits"`"
      if [ "${clones}" != "" ]
      then
         ensure_clones_directory

         for clone in ${clones}
         do
            clone_repository "${clone}"
            if [ $? -eq 1 ]
            then
               stop=0
               break
            fi
         done
      fi
   done
}


update()
{
   local clone
   local name
   local tag
   local dstname

   clone="$1"
   name="$2"
   dstname="$3"
   tag="$4"

   [ -z "$clone" ]    && internal_fail "clone is empty"
   [ -z "$name" ]     && internal_fail "name is empty"
   [ -z "$dstname" ]  && internal_fail "dstname is empty"

   local script

   log_info "Updating \"${dstname}\""
   if [ ! -L "${dstname}"  ]
   then
      script="`read_repo_setting "${name}" "bin/update.sh"`"
      if [ ! -z "${script}" ]
      then
         run_script "${script}" "$@"
      else
         exekutor git_pull "${dstname}" "${tag}"
      fi

      script="`read_repo_setting "${name}" "bin/post-update.sh"`"
      if [ ! -z "${script}" ]
      then
         run_script "${script}" "$@"
      fi
   fi
}


update_repository()
{
   local clone

   clone="$1"

   local name
   local tag
   local dstname

   name="`basename "${clone}" .git`"
   tag="`read_repo_setting "${name}" "tag"`" #repo (sic)

   dstname="${CLONES_FETCH_SUBDIR}/${name}"
   exekutor [ -e "${dstname}" ] || fail "You need to install first, before updating"
   exekutor [ -x "${dstname}" ] || fail "${name} is not anymore in \"gits\""

   log_fetch_action "${clone}" "${dstname}"

   update "${clone}" "${name}" "${dstname}" "${tag}"
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
   local i

   if [ $# -ne 0 ]
   then
      for clone in "$@"
      do
         update_repository "${CLONES_FETCH_SUBDIR}/${clone}"
      done
   else
      clones="`read_fetch_setting "gits"`"
      if [ "${clones}" != "" ]
      then
         for clone in ${clones}
         do
            update_repository "${clone}"
         done
      fi
   fi
}




#
# Use brews for stuff we don't tag
#
install_taps()
{
   local tap
   local taps
   local old

   log_fluff "Looking for taps"

   taps=`read_fetch_setting "taps" | sort | sort -u`
   if [ "${taps}" != "" ]
   then
      local old

      fetch_brew_if_needed

      old="${IFS:-" "}"
      IFS="
"
      for tap in ${taps}
      do
         exekutor brew tap "${tap}" > /dev/null || exit 1
      done
   else
      log_fluff "No taps found"
   fi
}


install_brews()
{
   local brew
   local brews

   install_taps

   log_fluff "Looking for brews"

   brews=`read_fetch_setting "brews" | sort | sort -u`
   if [ "${brews}" != "" ]
   then
      local old

      old="${IFS:-" "}"
      IFS="
"
      for brew in ${brews}
      do
         if [ "`which "${brew}"`" = "" ]
         then
            brew_update_if_needed "${brew}"

            log_fluff "brew ${COMMAND} \"${brew}\""
            exekutor brew "${COMMAND}" "${brew}" || exit 1
         else
            log_info "\"${brew}\" is already installed."
         fi
      done
      IFS="${old}"
   else
      log_fluff "No brews found"
   fi
}


#
# future, download tarballs...
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
install_gems()
{
   local gems
   local gem

   log_fluff "Looking for gems"

   gems="`read_fetch_setting "gems" | sort | sort -u`"
   if [ "${gems}" != "" ]
   then
      local old

      old="${IFS:-" "}"
      IFS="
"
      for gem in ${gems}
      do
         log_fluff "gem install \"${gem}\""

         echo "gem needs sudo to install ${gem}" >&2
         exekutor sudo gem install "${gem}" || exit 1
      done
      IFS="${old}"
   else
      log_fluff "No gems found"
   fi
}


#
# Use pips for stuff we don't tag
#
install_pips()
{
   local pips
   local pip

   log_fluff "Looking for pips"

   pips="`read_fetch_setting "pips" | sort | sort -u`"
   if [ "${pips}" != "" ]
   then
      local old

      old="${IFS:-" "}"
      IFS="
"
      for pip in ${pips}
      do
         log_fluff "pip install \"${gem}\""

         echo "pip needs sudo to install ${pip}" >&2
         exekutor sudo pip install "${pip}" || exit 1
      done
      IFS="${old}"
   else
      log_fluff "No pips found"
   fi
}


main()
{
   log_fluff "::: fetch :::"
   #
   # Run prepare scripts if present
   #
   run_fetch_settings_script "pre-${COMMAND}"


   if [ "${COMMAND}" = "install" ]
   then
      clone_repositories "$@"

      install_brews
      install_gems
      install_pips
      check_tars
   else
      update_repositories "$@"
   fi

   #
   # Run prepare scripts if present
   #
   run_fetch_settings_script "post-${COMMAND}"
}

main "$@"
