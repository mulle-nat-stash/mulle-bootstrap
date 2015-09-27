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
COMMAND=${1:-"install"}

. mulle-bootstrap-local-environment.sh
. mulle-bootstrap-warn-scripts.sh


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
   echo "usage: mulle-bootstrap-fetch.sh <install|nonrecursive|update>" 2>&1
   exit 1
   ;;
esac


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
      ln -s -f "$src" "$dst" || exit 1
      if [ "$tag" != "" ]
      then
         name="`basename "${dst}"`"
         echo "tag ${tag} will be ignored, due to symlink" >&2
         echo "if you want to checkout this tag do:" >&2
         echo "(cd .repos/${name}; git checkout \"${tag}\" )" >&2
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

   SYMLINK_FORBIDDEN=`read_config_setting "symlink_forbidden"`

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


checkout()
{
   local clone
   local cmd
   local name1
   local name2
   local tag
   local dstname

   clone="$1"
   cmd="$2"
   name1="$3"
   name2="$4"
   tag="$5"
   dstname="$6"

   local srcname
   local script
   local operation
   local flag
   local found

   srcname="${clone}"
   script=`read_repo_setting "${name1}" bin/"${cmd}.sh"`
   operation="git_command"

   # simplify this crap copy/paste code
   if [ -x "${script}" ]
   then
      "${script}" || exit 1
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
Use it instead of cloning ${clone} ?"
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

      "${operation}" "${srcname}" "${dstname}" "${tag}" || exit 1
       warn_scripts "${dstname}/.bootstrap" "${dstname}" || exit 1 # sic
   fi

   script=`read_repo_setting "${name1}" "bin/post-${cmd}.sh"`
   if [ -x "${script}" ]
   then
      "${script}" || exit 1
   fi
}


update()
{
   local clone
   local cmd
   local name
   local tag
   local dstname

   clone="$1"
   cmd="$2"
   name="$3"
   dstname="$4"
   tag="$5"

   local script

   if [ ! -L "${dstname}"  ]
   then
      if [ -x "${script}" ]
      then
         "${script}" || exit 1
      else
         git_command "${clone}" "${dstname}" "${tag}" || exit 1
      fi

      script=`read_repo_setting "${name}" "bin/post-${cmd}.sh"`
      if [ -x "${script}" ]
      then
         "${script}" || exit 1
      fi
   fi
}


git_command()
{
   local src
   local dst
   local tag

   src="$1"
   dst="$2"
   tag="$3"

   if [ "${COMMAND}" = "install" ]
   then
      git clone "${src}" "${dst}" || exit 1
   else
      ( cd "${dst}" ; git pull ) || exit 1
   fi

   if [ "${tag}" != "" ]
   then
      (cd "${dst}" ; git checkout "${tag}" )
      if [ $? -ne 0 ]
      then
         echo "Checkout failed, moving ${dst} to ${dst}.failed" >&2
         echo "You need to fix this manually and them move it back." >&2
         echo "Hint: check ${BOOTSTRAP_SUBDIR}/`basename "${dst}"`/TAG" >&2

         rm -rf "${dst}.failed" 2> /dev/null
         mv "${dst}" "${dst}.failed"
         exit 1
      fi
   fi
}


INHERIT_SETTINGS="taps brews gits pips gems buildorder buildignore"


bootstrap_recurse()
{
   local dst
   local name

   dst="$1"
   [ "${PWD}" != "${dst}" ] || fail "configuration error"

   name=`basename "${dst}"`

   # contains own bootstrap ? and not a symlink
   if [ ! -d "${dst}/.bootstrap" ] # -a ! -L "${dst}" ]
   then
      return 1
   fi

   # prepare auto folder if it doesn't exist yet
   if [ ! -d "${BOOTSTRAP_SUBDIR}.auto" ]
   then
      echo "Found a .bootstrap folder for `basename "${dst}"` will set up ${BOOTSTRAP_SUBDIR}.auto" >&2

      mkdir -p "${BOOTSTRAP_SUBDIR}.auto/settings"
      for i in $INHERIT_SETTINGS
      do
         if [ -f "${BOOTSTRAP_SUBDIR}.local/${i}" ]
         then
            cp "${BOOTSTRAP_SUBDIR}}.local/${i}" "${BOOTSTRAP_SUBDIR}.auto/${i}" || exit 1
         else
            if [ -f "${BOOTSTRAP_SUBDIR}/${i}" ]
            then
               cp "${BOOTSTRAP_SUBDIR}/${i}" "${BOOTSTRAP_SUBDIR}.auto/${i}" || exit 1
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
            mv "${BOOTSTRAP_SUBDIR}.auto/${i}" "${BOOTSTRAP_SUBDIR}.auto/${i}.tmp" || exit 1
            cat "${dst}/.bootstrap/${i}" "${BOOTSTRAP_SUBDIR}.auto/${i}.tmp" > "${BOOTSTRAP_SUBDIR}.auto/${i}"  || exit 1
            rm "${BOOTSTRAP_SUBDIR}.auto/${i}.tmp" || exit 1
         else
            cp "${dst}/.bootstrap/${i}" "${BOOTSTRAP_SUBDIR}.auto/${i}" || exit 1
         fi
      fi
   done

   #
   # link up other non-inheriting settings
   #
   if dir_has_files "${dst}/.bootstrap/settings"
   then
      local relative

      mkdir -p "${BOOTSTRAP_SUBDIR}.auto/settings/${name}" 2> /dev/null
      relative=`compute_relative "${BOOTSTRAP_SUBDIR}"`
      find "${dst}/.bootstrap/settings" -type f -depth 1 -print0 | \
      xargs -0 -I % ln -s -f "${relative}/../../"% "${BOOTSTRAP_SUBDIR}.auto/settings/${name}"

      # flatten folders into our own settings
      find "${dst}/.bootstrap/settings" -type d -depth 1 -print0 | \
      xargs -0 -I % ln -s -f "${relative}/../"% "${BOOTSTRAP_SUBDIR}.auto/settings"
   fi


   return 0
}


#
# Use git clones for stuff that gets tagged
# if you specify ../ it will assume you have
# checked it out yourself, If there is something
# checked out already it will use it, or ask
# convetion: .git suffix == repo to clone
#         no .git suffix, try to symlink
#
clone_repositories()
{
   local stop
   local clones
   local clone
   local cmd
   local name1
   local name2
   local tag
   local dstname

   cmd="$1"

   stop=0
   while [ $stop -eq 0 ]
   do
      stop=1

      clones=`read_fetch_setting "gits"`
      if [ "${clones}" != "" ]
      then
         if [ ! -d "${CLONES_FETCH_SUBDIR}" ]
         then
            if [ "${COMMAND}" = "update" ]
            then
               fail "install first before upgrading"
            fi
            mkdir -p "${CLONES_FETCH_SUBDIR}" || exit 1
         fi

         for clone in ${clones}
         do
            name1=`basename "${clone}" .git`
            name2=`basename "${clone}"`
            tag=`read_repo_setting "${name1}" "tag"` #repo (sic)

            dstname="${CLONES_FETCH_SUBDIR}/${name1}"

            case "${cmd}" in
               install)
                  if [ ! -e "${dstname}" ]
                  then
                     checkout "${clone}" "${cmd}" "${name1}" "${name2}" "${tag}" "${dstname}" || exit 1
                     if [ "${COMMAND}" = "install" -a "${DONT_RECURSE}" = "" ]
                     then
                        bootstrap_recurse "${dstname}"
                        if [ $? -eq 0 ]
                        then
                           stop=0
                           break
                        fi
                     fi
                  fi
                  ;;

               update)
                  update "${clone}" "${cmd}" "${name1}" "${tag}" "${dstname}" || exit 1
                  ;;
            esac
         done
      fi
   done
}


brew_update_if_needed()
{
   local stale
   local last_update

   last_update="${HOME}/.mulle-bootstrap/brew-update"

   fetch_brew_if_needed
   if [ $? -eq 1 ]
  	then
	  	return 0  ## just fetched it
	fi

   if [ -f "${last_update}" ]
   then
      stale=`find "${last_update}" -mtime +1 -type f -exec echo '{}' \;`
      if [ -f "${last_update}" -a "$stale" = "" ]
      then
         return 0
      fi
   fi

   user_say_yes "Should brew be updated before installing ?"

   if [ $? -eq 0 ]
   then
   	brew update

	   mkdir -p "`dirname "${last_update}"`" 2> /dev/null
   	touch "${last_update}"
   fi
}


#
# Use brews for stuff we don't tag
#
install_taps()
{
   local tap
   local taps

   taps=`read_fetch_setting "taps" | sort | sort -u`
   if [ "${taps}" != "" ]
   then
      brew_update_if_needed
      for tap in ${taps}
      do
         brew tap "${tap}" > /dev/null || exit 1
      done
   fi
}


install_brews()
{
   local brew
   local brews
   local cmd

   cmd="$1"
   install_taps

   brews=`read_fetch_setting "brews" | sort | sort -u`
   if [ "${brews}" != "" ]
   then
      brew_update_if_needed
      for brew in ${brews}
      do
         if [ "${cmd}" != "install" -o "`which "${brew}"`" = "" ]
         then
            brew "$cmd" "${brew}" || exit 1
         fi
      done
   fi
}

#
# Use gems for stuff we don't tag
#
install_gems()
{
   local gems
   local gem

   gems=`read_fetch_setting "gems" | sort | sort -u`
   if [ "${gems}" != "" ]
   then
      for gem in ${gems}
      do
         echo "gem needs sudo to install ${gem}" >&2
         sudo gem install "${gem}" || exit 1
      done
   fi
}

#
# Use pips for stuff we don't tag
#
install_pips()
{
   local pips
   local pip

   pips=`read_fetch_setting "pips" | sort | sort -u`
   if [ "${pips}" != "" ]
   then
      for pip in ${pips}
      do
         echo "pip needs sudo to install ${pip}" >&2
         sudo pip install "${pip}" || exit 1
      done
   fi
}


main()
{
   #
   # Run prepare scripts if present
   #
   script=`read_fetch_setting "bin/pre-${COMMAND}.sh"`
   if [ -x "${script}" ]
   then
      "${script}" || exit 1
   fi

   clone_repositories "${COMMAND}"

   install_brews "${COMMAND}"
   install_gems
   install_pips

   #
   # Run prepare scripts if present
   #
   script=`read_fetch_setting "bin/post-${COMMAND}.sh"`
   if [ -x "${script}" ]
   then
      "${script}" || exit 1
   fi
}

main
