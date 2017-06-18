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
MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH="included"


## option parsing common

#
# variables called flag. because they are indirectly set by flags
#
bootstrap_dump_env()
{
   log_trace "FULL trace started"
   log_trace "ARGS:${C_TRACE2} ${MULLE_ARGUMENTS}"
   log_trace "PWD :${C_TRACE2} `pwd -P 2> /dev/null`"
   log_trace "ENV :${C_TRACE2} `env | sort`"
   log_trace "LS  :${C_TRACE2} `ls -a1F`"
}


bootstrap_setup_trace()
{
   case "${1}" in
      VERBOSE)
         MULLE_FLAG_LOG_VERBOSE="YES"
      ;;

      FLUFF)
         MULLE_FLAG_LOG_FLUFF="YES"
         MULLE_FLAG_LOG_VERBOSE="YES"
         MULLE_FLAG_LOG_EXEKUTOR="YES"
      ;;

      TRACE)
         MULLE_FLAG_LOG_SETTINGS="YES"
         MULLE_FLAG_LOG_EXEKUTOR="YES"
         MULLE_FLAG_LOG_FLUFF="YES"
         MULLE_FLAG_LOG_VERBOSE="YES"
         bootstrap_dump_env
      ;;

      1848)
         MULLE_FLAG_LOG_SETTINGS="YES"
         MULLE_FLAG_LOG_FLUFF="YES"
         MULLE_FLAG_LOG_VERBOSE="YES"
         MULLE_FLAG_VERBOSE_BUILD="YES"

         bootstrap_dump_env

         if [ "${MULLE_TRACE_POSTPONE}" = "NO" ]
         then
            log_trace "1848 trace (set -x) started"
            set -x
            PS4="+ ${ps4string} + "
         fi
      ;;
   esac
}


bootstrap_technical_option_usage()
{
   if [ ! -z "${MULLE_TRACE}" ]
   then
      cat <<EOF
   -lc       : cache search log output
   -ld       : additional debug output
   -le       : external command execution log output
   -lm       : extended dependency analysis output
   -ls       : extended settings log output
   -t        : enable shell trace
   -tpwd     : emit shortened PWD during trace
   -tr       : also trace resolver
   -ts       : also trace settings
   -s        : be silent

   [Check source for more options]
EOF
   fi
}


bootstrap_technical_flags()
{
   case "$1" in
      -n|--dry-run)
         MULLE_FLAG_EXEKUTOR_DRY_RUN="YES"
      ;;

      -lc|--log-cache)
         MULLE_FLAG_LOG_CACHE="YES"
      ;;

      -ld|--log-debug)
         MULLE_FLAG_LOG_DEBUG="YES"
      ;;

      -le|--log-execution)
         MULLE_FLAG_LOG_EXEKUTOR="YES"
      ;;

      -lm|--log-merge)
         MULLE_FLAG_LOG_MERGE="YES"
      ;;

      -ls|--log-settings)
         MULLE_FLAG_LOG_SETTINGS="YES"
      ;;

      -lsc|--log-script-calls)
         MULLE_FLAG_LOG_SCRIPTS="YES"
      ;;

      -t|--trace)
         MULLE_TRACE="1848"
         COPYMOVEFLAGS="-v"
         GITOPTIONS="`concat "${GITOPTIONS}" "-v"`"
         MULLE_TRACE_PATHS_FLIP_X="YES"
         MULLE_TRACE_RESOLVER_FLIP_X="YES"
         MULLE_TRACE_SETTINGS_FLIP_X="YES"
         ps4string='${BASH_SOURCE[1]##*/}:${LINENO}'
      ;;

      -tf|--trace-filepaths)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"
         MULLE_TRACE_PATHS_FLIP_X="NO"
      ;;

      -tfpwd|--trace-full-pwd)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"
         ps4string='${BASH_SOURCE[1]##*/}:${LINENO} \"\w\"'
      ;;

      -tp|--trace-profile)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"
         case "${UNAME}" in
            linux)
               ps4string='$(date "+%s.%N (${BASH_SOURCE[1]##*/}:${LINENO})")'
            ;;
            *)
               ps4string='$(date "+%s (${BASH_SOURCE[1]##*/}:${LINENO})")'
            ;;
         esac
      ;;

      -tpo|--trace-postpone)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"
         MULLE_TRACE_POSTPONE="YES"
      ;;

      -tpwd|--trace-pwd)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"
         ps4string='${BASH_SOURCE[1]##*/}:${LINENO} \".../\W\"'
      ;;

      -tr|--trace-resolver)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"
         MULLE_TRACE_RESOLVER_FLIP_X="NO"
      ;;

      -ts|--trace-settings)
         [ "${MULLE_TRACE}" = "1848" ] || fail "option \"$1\" must be specified after -t"
         MULLE_TRACE_SETTINGS_FLIP_X="NO"
      ;;

      -tx|--trace-options)
         set -x
      ;;

      -v|--verbose)
        [ "${MULLE_TRACE}" = "1848" ] && log_warning "${MULLE_EXECUTABLE_FAIL_PREFIX}: -v after -t invalidates -t"

         MULLE_TRACE="VERBOSE"
         GITOPTIONS="`concat "${GITOPTIONS}" "-v"`"
      ;;

      -vv|--very-verbose)
        [ "${MULLE_TRACE}" = "1848" ] && log_warning "${MULLE_EXECUTABLE_FAIL_PREFIX}: -vv after -t invalidates -t"

         MULLE_TRACE="FLUFF"
         COPYMOVEFLAGS="-v"
         GITOPTIONS="`concat "${GITOPTIONS}" "-v"`"
      ;;

      -vvv|--very-verbose-with-settings)
        [ "${MULLE_TRACE}" = "1848" ] && log_warning "${MULLE_EXECUTABLE_FAIL_PREFIX}: -vvv after -t invalidates -t"

         MULLE_TRACE="TRACE"
         COPYMOVEFLAGS="-v"
         GITOPTIONS="`concat "${GITOPTIONS}" "-v"`"
      ;;

      -s|--silent)
         MULLE_TRACE=
         MULLE_FLAG_LOG_TERSE="YES"
         GITOPTIONS="`concat "${GITOPTIONS}" "-v"`"
      ;;

      *)
         return 1
      ;;
   esac

   return 0
}


bootstrap_define_expansion()
{
   local keyvalue

   keyvalue="$1"

   is_bootstrap_project || fail "This is not a ${MULLE_EXECUTABLE} project"

   if [ -z "${keyvalue}" ]
   then
      fail "Missing key, directly after -D"
      mulle_bootstrap_usage
   fi

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh

   local key
   local value

   key="`echo "${keyvalue}" | cut -d= -f1 | tr '[a-z]' '[A-Z]'`"
   if [ -z "${key}" ]
   then
      key="${keyvalue}"
      value="YES"
   else
      value="`echo "${keyvalue}" | cut -d= -f2-`"
   fi

   local path

   path="${BOOTSTRAP_DIR}.local/${key}"
   mkdir_if_missing "`dirname -- "${path}"`"
   redirect_exekutor "${path}" echo "# commandline argument -D${keyvalue}
${value}"
}


bootstrap_ensure_consistency()
{
   if dirty_harry
   then
      log_error "A previous fetch or update was incomplete.
Suggested resolution (in $PWD):
    ${C_RESET_BOLD}${MULLE_EXECUTABLE} clean dist${C_ERROR}
    ${C_RESET_BOLD}${MULLE_EXECUTABLE}${C_ERROR}

Or do you feel lucky ? Then try again with
   ${C_RESET_BOLD}${MULLE_EXECUTABLE} -f ${MULLE_ARGUMENTS}${C_ERROR}
But you've gotta ask yourself one question: Do I feel lucky ?
Well, do ya, punk?"
      exit 1
   fi
}


bootstrap_should_defer_to_master()
{
   local command="$1"

   #
   # if we have a.bootstrap.local/is_minion file then
   # some commands can't run, and some commands are re-executed in master
   # and some commands (like fetch and clean) are executed locally AND in the
   # master
   #

   if ! is_minion_bootstrap_project
   then
      return 1
   fi

   if [ "${MULLE_FLAG_DONT_DEFER}" = "YES" ]
   then
      log_verbose "Minion executes locally by request"
      return 1
   fi

   if [ "${MULLE_BOOTSTRAP_DONT_DEFER}" = "YES" ]
   then
      log_fluff "Minion executes locally by environment"
      return 1
   fi

   local masterpath

   . mulle-bootstrap-project.sh

   masterpath="`get_master_of_minion_bootstrap_project`"

   assert_sane_master_bootstrap_project "${masterpath}"

   case "${command}" in
      git|defer|emancipate|library-path|setup-xcode|tag|type|uname|version|xcode)
         log_verbose "Minion executes locally"
      ;;

      show)
         log_verbose "Minion executes partially locally"

         [ -z "${MULLE_BOOTSTRAP_SHOW_SH}" ] && . mulle-bootstrap-show.sh

         (
            [ $# -eq 0 ] || shift
            show_main_header_only "$@"
         ) || exit 1

         log_info "Minion defers to master \"$masterpath\""
         log_info ""

         cd "${masterpath}" || fail "master is missing"
         return 0  # this leads to  main deferring later on (but cd is set!)
      ;;

      refer|dist-clean)
         fail "This is a minion bootstrap project.\n \
${MULLE_EXECUTABLE} ${command}t is not possible."
      ;;

      *)
         log_verbose "Minion defers to master \"$masterpath\" for execution"

         cd "${masterpath}" || fail "master is missing"
         return 0  # this leads to  main deferring later on (but cd is set!)
      ;;
   esac

   return 1
}

# returns 0 if said yes
user_say_yes()
{
   local  x

   x="${MULLE_FLAG_ANSWER:-ASK}"

   while :
   do
      case "$x" in
         [Aa][Ll][Ll])  # doesn't work when executed in subshell
            MULLE_FLAG_ANSWER="YES"
            return 0
         ;;

         [Yy]*)
            return 0
         ;;

         TRACE)
            set -x
         ;;

         [Nn][Oo][Nn][Ee])
            MULLE_FLAG_ANSWER="NONE"
            return 1
         ;;

         [Nn]*)
            return 1
         ;;
      esac

      printf "${C_WARNING}%b${C_RESET} (y/${C_GREEN}N${C_RESET}) > " "$*" >&2
      read x

      if [ -z "${x}" ]
      then
         x="NO"
      fi
   done
}


get_core_count()
{
   count="`nproc 2> /dev/null`"
   if [ -z "$count" ]
   then
      count="`sysctl -n hw.ncpu 2> /dev/null`"
   fi

   if [ -z "$count" ]
   then
      count=2
   fi
   echo $count
}


#
# this is for PATH style variables
#
add_path()
{
   local line="$1"
   local path="$2"

   [ -z "${PATH_SEPARATOR}" ] && fail "PATH_SEPARATOR is undefined"

   case "${UNAME}" in
      mingw)
         path="`echo "${path}" | tr '/' '\\' 2> /dev/null`"
      ;;
   esac

   if [ -z "${line}" ]
   then
      echo "${path}"
   else
      if [ -z "${path}" ]
      then
         echo "${line}"
      else
         echo "${line}${PATH_SEPARATOR}${path}"
      fi
   fi
}


add_path_if_exists()
{
   local line="$1"
   local path="$2"

   if [ -e "${path}" ]
   then
      add_path "$@"
   else
      echo "${line}"
   fi
}



#
# this is for constructing filesystem paths
#
add_component()
{
   local filepath="$1"
   local component="$2"

   [ -z "${COMPONENT_SEPARATOR}" ] && fail "COMPONENT_SEPARATOR is undefined"

   if [ -z "${filepath}" ]
   then
      echo "${component}"
   else
      if [ -z "${component}" ]
      then
         echo "${filepath}"
      else
         echo "${filepath}${COMPONENT_SEPARATOR}${component}"
      fi
   fi
}


unpostpone_trace()
{
   if [ ! -z "${MULLE_TRACE_POSTPONE}" -a "${MULLE_TRACE}" = "1848" ]
   then
      set -x
      PS4="+ ${ps4string} + "
   fi
}

#
# version must be <= min_major.min_minor
#
check_version()
{
   local version
   local min_major
   local min_minor

   version="$1"
   min_major="$2"
   min_minor="$3"

   local major
   local minor

   if [ -z "${version}" ]
   then
      return 0
   fi

   major="`echo "${version}" | head -1 | cut -d. -f1`"
   if [ "${major}" -lt "${min_major}" ]
   then
      return 0
   fi

   if [ "${major}" -ne "${min_major}" ]
   then
      return 1
   fi

   minor="`echo "${version}" | head -1 | cut -d. -f2`"
   [ "${minor}" -le "${min_minor}" ]
}


# figure out if we need to run refresh
dirty_harry()
{
   log_debug ":dirty_harry:"

   [ -f "${REPOS_DIR}/.fetch_started" ]
}


build_needed()
{
   log_debug ":build_needed:"

   [ -z "${REPOS_DIR}" ] && internal_fail "REPOS_DIR undefined"

   local build_done

   build_done="${REPOS_DIR}/.build_done"
   if [ ! -f "${build_done}" ]
   then
      log_verbose "Need build because \"${build_done}\" does not exist."
      return 0
   fi

   local progress
   local complete

   #
   # sort  and unique, because people can redo builds manually
   # which will add duplicate lines
   #
   progress="`read_setting "${build_done}" | sort`"
   complete="`read_root_setting "build_order" | sort`"

   if [ "${progress}" != "${complete}" ]
   then
      log_verbose "Need build because \"${build_done}\" is different to \"build_order\""
      return 0
   fi

   return 1
}


fetch_needed()
{
   log_debug ":fetch_needed:"

   [ -z "${REPOS_DIR}" ] && internal_fail "REPOS_DIR undefined"

   local  referencefile

   referencefile="${REPOS_DIR}/.fetch_done"
   if [ ! -f "${referencefile}" ]
   then
      log_verbose "Need fetch because \"${referencefile}\" does not exist."
      return 0
   fi

   local creator

   creator="`cat "${BOOTSTRAP_DIR}.auto/.creator" 2> /dev/null`"
   if [ ! -z "${creator}" -a "${creator}" != "${MULLE_EXECUTABLE}" ]
   then
      if [ -d "${BOOTSTRAP_DIR}.auto" ]
      then
         log_verbose "Need fetch because ${BOOTSTRAP_DIR}.auto was created by \"${creator}\"."
      else
         log_verbose "Need fetch because ${BOOTSTRAP_DIR}.auto does not exist."
      fi
      return 0
   fi

   local bootstrapdir="${BOOTSTRAP_DIR}"

   [ -z "${bootstrapdir}" ] && internal_fail "BOOTSTRAP_DIR undefined"

   if [ "${BOOTSTRAP_DIR}" -ot "${BOOTSTRAP_DIR}.local" ]
   then
      bootstrapdir="${BOOTSTRAP_DIR}.local"
   fi

   if [ "${referencefile}" -ot "${bootstrapdir}" ]
   then
      log_verbose "Need fetch because \"${bootstrapdir}\" is modified"
      return 0
   fi

   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ] && . mulle-bootstrap-repositories.sh

   local stashdir

   IFS="
"
   for stashdir in `all_repository_stashes ${REPOS_DIR}`
   do
      IFS="${DEFAULT_IFS}"

      if [ "${referencefile}" -ot "${stashdir}/${BOOTSTRAP_DIR}" ]
      then
         log_verbose "Need fetch because \"${stashdir}/${BOOTSTRAP_DIR}\" is modified"
         return 0
      fi
   done

   local minions

   minions="`read_root_setting "minions"`"

   IFS="
"
   for stashdir in ${minions}
   do
      IFS="${DEFAULT_IFS}"

      if [ "${referencefile}" -ot "${stashdir}/${BOOTSTRAP_DIR}" ]
      then
         log_verbose "Need fetch because \"${stashdir}/${BOOTSTRAP_DIR}\" is modified"
         return 0
      fi
   done

   IFS="${DEFAULT_IFS}"

   return 1
}

#
# and clean up some other cruft
#
set_fetch_needed()
{
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh

   remove_file_if_present "${REPOS_DIR}/.fetch_started"
   remove_file_if_present "${REPOS_DIR}/.fetch_done"
}


assert_mulle_bootstrap_version()
{
   local version

   # has to be read before .auto is setup
   version="`read_raw_setting "version"`"

   if check_version "$version" "${MULLE_EXECUTABLE_VERSION_MAJOR}" "${MULLE_EXECUTABLE_VERSION_MINOR}"
   then
      return
   fi

   fail "This ${BOOTSTRAP_DIR} requires ${MULLE_EXECUTABLE} version ${version} at least, you have ${MULLE_EXECUTABLE_VERSION}"
}


_git_get_branch()
{
   local directory="${1:-${PWD}}"

   (
      cd "${directory}" &&
      git rev-parse --abbrev-ref HEAD 2> /dev/null
   ) || fail "Could not get branch for \"${directory}\""
}


_git_get_url()
{
   local directory="${1:-${PWD}}"
   local remote="$2"

   [ -d "${directory}" ] || internal_fail "wrong \"${directory}\""

   (
      cd "${directory}" ;
      git config --get "remote.${remote}.url" 2> /dev/null
   ) || fail "unknown \"${remote}\" in \"${directory}\" (`pwd`)"
}


#
# expands ${setting} and ${setting:-foo}
#
_expanded_variables()
{
   local string="$1"
   local altbootstrap="$2"
   local context="$3"

   local key
   local value
   local prefix
   local suffix
   local next
   local default
   local tmp
   local rval

   rval=0
   key="`echo "${string}" | sed -n 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:.\/&;#@-]*\)}\(.*\)$/\2/p'`"
   if [ -z "${key}" ]
   then
      echo "${string}"
      return $rval
   fi

   prefix="`echo "${string}" | sed -n 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:.\/&;#@-]*\)}\(.*\)$/\1/p'`"
   suffix="`echo "${string}" | sed -n 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:.\/&;#@-]*\)}\(.*\)$/\3/p'`"

   default="" # crazy linux bug, where local vars are reused ?
   tmp="`echo "${key}" | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)[:][-]\(.*\)$/\1/p'`"
   if [ ! -z "${tmp}" ]
   then
      default="`echo "${key}" | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)[:][-]\(.*\)$/\2/p'`"
      key="${tmp}"
   fi

   case "${key}" in
      GIT_BRANCH)
         value="`_git_get_branch "${ROOT_DIR}"`"
      ;;

      GIT_REMOTE_*)
         local remote
         local url

         remote="`sed 's/GIT_REMOTE_\(.*\)/\1/' <<< "${key}"`"
         remote="`tr '[A-Z]' '[a-z]' <<< "${remote}"`"
         url="`_git_get_url "${ROOT_DIR}" "${remote}"`"
         value="`dirname "${url}"`"
      ;;

      *)
         if [ ! -z "${altbootstrap}" ]
         then
            local xdefault

            xdefault="`(
               BOOTSTRAP_DIR="${altbootstrap}"
               MULLE_BOOTSTRAP_SETTINGS_NO_AUTO="YES"

               read_root_setting "${key}"
            )`"

            default="${xdefault:-${default}}"
         fi

         value="`read_root_setting "${key}"`"
         if [ -z "${value}" ]
         then
            if [ -z "${default}" ]
            then
               log_warning "\${${key}} expanded to the empty string (${context}: \"${string}\")."
               rval=1
            else
               log_setting "Root setting for ${C_MAGENTA}${key}${C_SETTING} set to default ${C_MAGENTA}${default}${C_SETTING}"
               value="${default}"
            fi
         fi
      ;;
   esac


   next="${prefix}${value}${suffix}"
   if [ "${next}" = "${string}" ]
   then
      fail "\"${string}\" expands to itself (${context})"
   fi

   _expanded_variables "${next}" "${altbootstrap}" "${context}"
   if [ $? -ne 0 ]
   then
      rval=1
   fi

   return $rval
}


expanded_variables()
{
   local string=$1
   local value
   local rval

   value="`_expanded_variables "$@"`"
   rval=$?

   echo "$value"

   if [ "${string}" != "${value}" ] # $1 could not contain any $
   then
      if [ -z "${value}" ]
      then
         log_warning "Expanded \"${string}\" to empty string"
      else
         log_setting "Expanded \"${string}\" to \"${value}\""
      fi
   fi

   return $rval
}


is_bootstrap_project()
{
   local  masterpath="${1:-.}"

   [ -d "${masterpath}/${BOOTSTRAP_DIR}" -o -d "${masterpath}/${BOOTSTRAP_DIR}.local" ]
}


is_master_bootstrap_project()
{
   local  masterpath="${1:-.}"

   [ -f "${masterpath}/${BOOTSTRAP_DIR}.local/is_master" ]
}


is_minion_bootstrap_project()
{
   local  minionpath="${1:-.}"

   [ -f "${minionpath}/${BOOTSTRAP_DIR}.local/is_minion" ]
}


assert_sane_master_bootstrap_project()
{
   local  masterpath="$1"

   if [ -d "${masterpath}/${BOOTSTRAP_DIR}" ]
   then
      fail "master project at \"${masterpath}\" must not have a \"${BOOTSTRAP_DIR}\" folder"
   fi

   if ! is_master_bootstrap_project "${masterpath}"
   then
      fail "\"${masterpath}\" is not a master project"
   fi
}

#
# read local environment
# source this file
# there should be nothing project specific in here
# especially no setting or config reads
#
local_environment_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

   # name of the bootstrap folder, maybe changes this to .bootstrap9 for
   # some version ?
   BOOTSTRAP_DIR=".bootstrap"

   # can't reposition this because of embedded reposiories
   REPOS_DIR="${BOOTSTRAP_DIR}.repos"

   # can't reposition this because of embedded reposiories
   EMBEDDED_REPOS_DIR="${BOOTSTRAP_DIR}.repos/.embedded"

   # where regular repos are cloned to, when there is no path given
   STASHES_DEFAULT_DIR="stashes"

   # used by embedded repositories to change location
   STASHES_ROOT_DIR=""

   COMPONENT_SEPARATOR="/"

   log_fluff "${UNAME} detected"
   case "${UNAME}" in
      mingw)
         # be verbose by default on MINGW because its so slow
         if [ -z "${MULLE_TRACE}" ]
         then
           MULLE_FLAG_LOG_VERBOSE="YES"
         fi

         PATH_SEPARATOR=';'
         USR_LOCAL_LIB=~/lib
         USR_LOCAL_INCLUDE=~/include
      ;;

      "")
         fail "UNAME not set yet"
      ;;

      *)
         PATH_SEPARATOR=':'
         USR_LOCAL_LIB=/usr/local/lib
         USR_LOCAL_INCLUDE=/usr/local/include
      ;;
   esac

   #
   # default archive
   #
   case "${UNAME}" in
      darwin)
         DEFAULT_ARCHIVE_CACHE="${HOME}/Library/Caches/mulle-bootstrap/archives"
      ;;
   esac

}


local_environment_main()
{
   log_debug ":local_environment_main:"
   # source_environment

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" ]
   then
      log_trace "Dry run is active."
   fi

   :
}


local_environment_initialize
