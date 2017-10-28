#! /usr/bin/env bash
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
MULLE_BOOTSTRAP_BREW_SH="included"


_brew_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_BOOTSTRAP_EXECUTABLE}  ${COMMAND} [options] [repositories]

   You can specify the names of the formulae to ${COMMAND}.

Options:
   -cs        : check /usr/local for duplicates
EOF

   case "${UNAME}" in
      darwin)
         cat <<EOF >&2
   -c         : change @rpath for shared libraries and frameworks
   -n         : don't change @rpath for shared libraries (if config option is set)
   -f <rpath> : @rpath for Frameworks (default: ${OPTION_RPATH_FRAMEWORKS})
   -l <rpath> : @rpath for shared libraries (default: ${OPTION_RPATH_LIBRARIES})
EOF
      ;;
   esac

   echo >&2

   exit 1
}

#
# Install brew into "addictions" via git clone
# this has the following advantages:
#    When fetching libraries or binaries they will
#    automatically appear in addictions/bin and addictions/lib / addictionsinclude
#    It's all local (!) to the project. Due to it being a git clone
#    and dependencies being wiped occasionally, its better to have a second
#    directory
#

fetch_brew_if_needed()
{
   [ ! -z "${BREW}" ] ||  internal_fail "BREW undefined"

   if [ -x "${BREW}" ]
   then
      return
   fi

   if [ -d "${ADDICTIONS_DIR}" ]
   then
      fail "There is already an \"${ADDICTIONS_DIR}\" folder here ($PWD), move it away"
   fi

   case "${UNAME}" in
      darwin)
         log_info "Installing OS X brew"
         _git_clone https://github.com/Homebrew/brew.git "${ADDICTIONS_DIR}"
      ;;

      linux)
         log_info "Installing Linux brew"
         _git_clone https://github.com/Linuxbrew/brew.git "${ADDICTIONS_DIR}"
       ;;

      *)
         fail "Missing brew support for ${UNAME}"
      ;;
   esac

   if [ ! -x "${BREW}" ]
   then
      fail "brew was not successfully installed (PATH=$PATH)"
   fi

   #
   # if brew is from clone cache update it
   #
   if [ ! -z "${CLONE_CACHE}" ]
   then
      "${BREW}" update
   fi

   return 1
}


walk_brews()
{
   log_debug "walk_brews" "$@"

   local brews="$1"; shift
   local callback="$1"; shift

   local formula

   IFS="
"
   for formula in ${brews}
   do
      IFS="${DEFAULT_IFS}"
      if ! ${callback} "${formula}" "$@"
      then
         break
      fi
   done

   IFS="${DEFAULT_IFS}"

}


_brew_action()
{
   local formula="$1" ; shift
   local brewcmd="$1"

   if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = "YES" ] && has_usr_local_include "${formula}"
   then
      log_info "${C_MAGENTA}${C_BOLD}${formula}${C_INFO} is a system library, so not installing it"
      return
   fi

   local versions

   case "${brewcmd}" in
      install)
         versions="`exekutor ${BREW} ls --versions "${formula}" 2> /dev/null`"

         if [ -z "${versions}" ]
         then
            log_info "Installing ${C_MAGENTA}${C_BOLD}${formula}${C_INFO} ..."
            exekutor "${BREW}" install "${formula}" || exit 1

            log_info "Force linking it, in case it was keg-only"
            exekutor "${BREW}" link --force "${formula}" || exit 1
         else
            log_info "${C_MAGENTA}${C_BOLD}${formula}${C_INFO} is already installed."
         fi
      ;;

      upgrade)
         log_info "Upgrading ${C_MAGENTA}${C_BOLD}${formula}${C_INFO} ..."
         exekutor "${BREW}" upgrade "${formula}"
      ;;
   esac
}


darwin_get_shared_library_id()
{
   otool -L "$1" | \
      sed -n '2p' | \
      sed 's/^\([^(]*\).*$/\1/' | \
      sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}


darwin_hack_shared_library()
{
   local path="$1"
   local rpath="$2"

   chmod u+w "${path}" || return 1

   install_name_tool -id "${rpath}" "${path}" || return 2
   log_fluff "Otool \"${path}\": `otool -L "${path}"`"

   chmod u-w "${path}"

   echo "${path}"

   return 0
}


darwin_hack_shared_libraries()
{
   local rpathprefix="$1"

   local name
   local path
   local rpath
   local i

   local hacked

   hacked=""
   IFS="
"
   for i in `find "${ADDICTIONS_DIR}/lib" -name "*.dylib" -print`
   do
      IFS="${OLDIFS}"

      path="`resolve_symlinks "${i}"`"

      echo "${hacked}" | fgrep -s -q -x "${path}" > /dev/null
      if [ $? -eq 0 ]
      then
         continue
      fi

      local libid

      #
      # maybe overzealous, but try to keep dylibname as given
      # in the executable
      #
      libid="`darwin_get_shared_library_id "${path}"`"
      if [ -z "${libid}" ]
      then
         log_warning "\"${path}\" is not really a dylib"
         continue
      fi

      name="`basename -- "${libid}"`"
      rpath="`add_component "${rpathprefix}" "${name}"`"

      log_info "Setting id on library \"${name}\" to \"${rpath}\" ..."
      if ! darwin_hack_shared_library "${path}" "${rpath}"
      then
         fail "Could not hack \"${i}\"'s @rpath."
      fi

      hacked="`add_line "${hacked}" "${path}"`"
   done

   IFS="${OLDIFS}"
}


#
# this needs to become more sophisticated, because
# there could be bundles inside the framework
#
darwin_hack_frameworks()
{
   local rpathprefix="$1"

   local name
   local path
   local rpath
   local framework
   local frameworkname
   local i

   IFS="
"
   for i in `find "${ADDICTIONS_DIR}/Frameworks/"*.framework -maxdepth 1 -print 2>/dev/null`
   do
      IFS="${OLDIFS}"

      name="`basename -- "${i}"`"
      framework="`dirname -- "${i}"`"
      frameworkname="`basename -- "${framework}" .framework`"

      if [ "${name}" != "${frameworkname}" ]
      then
         continue
      fi

      path="`resolve_symlinks "${i}"`"
      rpath="`add_component "${rpathprefix}" "${frameworkname}.framework"`"
      rpath="`add_component "${rpath}" "${name}"`"

      log_info "Setting id on framework \"${frameworkname}\" to \"${rpath}\" ..."
      if ! darwin_hack_shared_library "${path}" "${rpath}"
      then
         fail "Could not hack \"${i}\"'s @rpath."
      fi
   done

   IFS="${OLDIFS}"
}


find_brews()
{
   log_fluff "Looking for brew formulae"

   brews="`read_root_setting "brews" | sort | sort -u`"
   if [ ! -z "${brews}" ]
   then
      echo "${brews}"
      return
   fi

   (
      MULLE_BOOTSTRAP_SETTINGS_NO_AUTO=YES
      read_root_setting "brews" | sort | sort -u
   )
}

#
# brews are now installed using a local brew
# if we are on linx
#
_brew_install_brews()
{
   log_debug "_brew_install_brews" "$@"

   local brewcmd="$1" ; shift
   local brews="$@"

   [ -z "${brewcmd}" ] && internal_fail "empty brewcmd"

   if [ -z "${brews}" ]
   then
      brews="`find_brews`"
      if [ -z "${brews}" ]
      then
         log_fluff "No brews found"
         return
      fi
   fi

   fetch_brew_if_needed

   if [ "${brewcmd}" = "update" ]
   then
      exekutor "${BREW}" update
      return
   fi

   local flag

   walk_brews "${brews}" _brew_action "${brewcmd}"
}


brew_install_brews()
{
   log_debug "brew_install_brews" "$@"

   local unprotect

   unprotect=
   if [ -d "${ADDICTIONS_DIR}" ]
   then
      log_fluff "Unprotecting \"${ADDICTIONS_DIR}\" for ${command}."
      exekutor chmod -R u+w "${ADDICTIONS_DIR}"
      unprotect="YES"
   fi

   _brew_install_brews "$@"

   if [ "${unprotect}" = "YES" ]
   then
      write_protect_directory "${ADDICTIONS_DIR}"
   fi
}


brew_fetch_loop()
{
   [ -z "${MULLE_BOOTSTRAP_AUTO_UPDATE_SH}" ] && . mulle-bootstrap-auto-update.sh

   bootstrap_auto_create

   if is_master_bootstrap_project
   then
      log_info "Extracting minions' brews ..."

      [ -z "${MULLE_BOOTSTRAP_FETCH_SH}" ] && . mulle-bootstrap-fetch.sh

      extract_minion_precis
   fi
}


_brew_common_install()
{
   log_debug "_brew_common_install" "$@"

   if [ $# -ne 0 ]
   then
      log_error "Additional parameters not allowed for fetch (" "$@" ")"
      ${USAGE}
   fi

   brew_fetch_loop

   brew_install_brews "install" "$@"

   if read_yes_no_config_setting "update_gitignore" "YES"
   then
      if [ -d .git ]
      then
         append_dir_to_gitignore_if_needed "${ADDICTIONS_DIR}"
      fi
   fi
}


_brew_common_update()
{
   log_debug "_brew_common_update" "$@"

   if [ $# -ne 0 ]
   then
      log_error "Additional parameters not allowed for update (" "$@" ")"
      ${USAGE}
   fi

   brew_install_brews "update"
}


_brew_common_upgrade()
{
   log_debug "_brew_common_upgrade" "$@"

   brew_install_brews "upgrade" "$@"
}


_brew_common_main()
{
   log_debug "_brew_common_main" "$@"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]          && . mulle-bootstrap-settings.sh

   local OPTION_CHECK_USR_LOCAL_INCLUDE
   local OPTION_CHANGE_RPATH
   local OPTION_RPATH_LIBRARY
   local OPTION_RPATH_FRAMEWORK

   OPTION_CHECK_USR_LOCAL_INCLUDE="`read_config_setting "check_usr_local_include" "NO"`"
   OPTION_CHANGE_RPATH="`read_config_setting "change_rpath" "NO"`"
   # @rpath/../Resources is lazy and wrong, but so convenient for quick hacks
   OPTION_RPATH_LIBRARY="`read_config_setting "rpath_library" "@rpath/../Resources"`"
   OPTION_RPATH_FRAMEWORK="`read_config_setting "rpath_framework" "@rpath/../Frameworks"`"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            ${USAGE}
         ;;

         -cs|--check-usr-local-include)
            OPTION_CHECK_USR_LOCAL_INCLUDE="YES"
            ;;

         -f|--rpath-framework)
            [ $# -eq 1 ] && fail "missing argument to $1"
            shift
            OPTION_RPATH_FRAMEWORK="$1"
         ;;

         -l|--rpath-library)
            [ $# -eq 1 ] && fail "missing argument to $1"
            shift
            OPTION_RPATH_LIBRARY="$1"
         ;;

         -n|--no-rpath)
            OPTION_CHANGE_RPATH="NO"
         ;;

         -r|--rpath)
            OPTION_CHANGE_RPATH="YES"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown ${COMMAND} option $1"
            ${USAGE}
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ] && . mulle-bootstrap-scripts.sh
   [ -z "${ADDICTIONS_DIR}" ] && internal_fail "missing ADDICTIONS_DIR"

   #
   # should we check for '/usr/local/include/<name>' and don't fetch if
   # present (somewhat dangerous, because we do not check versions)
   #
   case "${COMMAND}" in
      install)
         _brew_common_install "$@"
      ;;

      update)
         _brew_common_update "$@"
      ;;

      upgrade)
         _brew_common_upgrade "$@"
      ;;

      *)
         internal_fail "Command \"${COMMAND}\" is unknown"
      ;;
   esac

   if [ "${OPTION_CHANGE_RPATH}" = "YES" ]
   then
      case "${UNAME}" in
         darwin)
            if [ ! -z "${OPTION_RPATH_LIBRARY}" ]
            then
               darwin_hack_shared_libraries "${OPTION_RPATH_LIBRARY}"
            fi

            if [ ! -z "${OPTION_RPATH_FRAMEWORK}" ]
            then
               darwin_hack_frameworks "${OPTION_RPATH_FRAMEWORK}"
            fi
         ;;
      esac
   fi
}


brew_upgrade_main()
{
   log_debug "::: brew upgrade begin :::"

   USAGE="_brew_usage"
   COMMAND="upgrade"
   _brew_common_main "$@"

   log_debug "::: brew upgrade end :::"
}


brew_update_main()
{
   log_debug "::: brew update begin :::"

   USAGE="_brew_usage"
   COMMAND="update"
   _brew_common_main "$@"

   log_debug "::: brew update end :::"
}


brew_install_main()
{
   log_debug "::: brew install begin :::"

   USAGE="_brew_usage"
   COMMAND="install"
   _brew_common_main "$@"

   log_debug "::: brew install end :::"
}


brew_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

   log_debug ":brew_initialize:"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ]         && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_SCM_SH}" ]               && . mulle-bootstrap-scm.sh

   BREW="${ADDICTIONS_DIR}/bin/brew"

   :
}

brew_initialize
