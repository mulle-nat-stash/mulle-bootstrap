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

# Escape sequence and resets
if [ "${MULLE_BOOTSTRAP_NO_COLOR}" != "YES" ]
then
   C_RESET="\033[0m"

   # Foreground colours
   C_BLACK="\033[0;30m"   C_RED="\033[0;31m"    C_GREEN="\033[0;32m"
   C_YELLOW="\033[0;33m"  C_BLUE="\033[0;34m"   C_MAGENTA="\033[0;35m"
   C_CYAN="\033[0;36m"    C_WHITE="\033[0;37m"  C_BR_BLACK="\033[0;90m"

   C_BR_RED="\033[0;91m"

   trap 'printf "${C_RESET}"' TERM EXIT
fi


C_ERROR="${C_RED}"
log_error()
{
   echo "${C_ERROR}$*${C_RESET}" >&2
}


C_WARNING="${C_YELLOW}"
log_warning()
{
   if [ "${MULLE_BOOTSTRAP_TERSE}" != "YES" ]
   then
      echo "${C_WARNING}$*${C_RESET}" >&2
   fi
}


C_INFO="${C_CYAN}"
log_info()
{
   if [ "${MULLE_BOOTSTRAP_TERSE}" != "YES" ]
   then
      echo "${C_INFO}$*${C_RESET}" >&2
   fi
}


C_FLUFF="${C_GREEN}"
log_fluff()
{
   if [ "${MULLE_BOOTSTRAP_VERBOSE}" = "YES"  ]
   then
      echo "${C_FLUFF}$*${C_RESET}" >&2
   fi
}


C_TRACE="${C_FLUFF}"
log_trace()
{
   echo "${C_TRACE}$*${C_RESET}" >&2
}


C_TRACE2="${C_WHITE}"
log_trace2()
{
   echo "${C_TRACE2}$*${C_RESET}" >&2
}


#
# some common functions
#
fail()
{
   log_error "$@"
   exit 1
}


internal_fail()
{
   fail "${C_BR_RED}*** internal error: ${C_RED}$*"
}



eval_exekutor()
{
   if [ "${MULLE_BOOTSTRAP_DRY_RUN}" = "YES" -o "${MULLE_BOOTSTRAP_TRACE}" = "YES" ]
   then
      echo "$@" >&2
   fi

   if [ "${MULLE_BOOTSTRAP_DRY_RUN}" != "YES" ]
   then
      eval "$@"
   fi
}


logging_eval_exekutor()
{
   echo "$@"
   eval_exekutor "$@"
}


exekutor()
{
   if [ "${MULLE_BOOTSTRAP_DRY_RUN}" = "YES" -o "${MULLE_BOOTSTRAP_TRACE}" = "YES" ]
   then
      echo "$@" >&2
   fi

   if [ "${MULLE_BOOTSTRAP_DRY_RUN}" != "YES" ]
   then
      "$@"
   fi
}


logging_exekutor()
{
   echo "$@"
   exekutor "$@"
}


is_yes()
{
   local s

   s=`echo "${1}" | tr '[:lower:]' '[:upper:]'`
   case "${s}" in
      YES|Y|1)
         return 0
      ;;
      NO|N|0|"")
         return 1
      ;;

      *)
         fail "$2 should contain YES or NO (or be empty)"
      ;;
   esac
}


concat()
{
   local i
   local s

   for i in "$@"
   do
      if [ "${i}" != "" ]
      then
         if [ "${s}" != "" ]
         then
            s="${s} ${i}"
         else
            s="${i}"
         fi
      fi
   done

   echo "${s}"
}


path_depth()
{
   local name
   local depth

   name="$1"
   depth=0

   if [ "${name}" != "" ]
   then
      while [ "$name" != "." ]
      do
         name=`dirname "$name"`
         depth=`expr $depth + 1`
      done
   fi
   echo "$depth"
}


#
# stolen from:
# http://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac
# ----
#
_prepend_path_if_relative()
{
   case "$2" in
      /* )
         echo "$2"
         ;;
      * )
         echo "$1/$2"
         ;;
   esac
}


resolve_symlinks()
{
   local dir_context path

   path="`readlink "$1"`"
   if [ $? -eq 0 ]
   then
      dir_context=`dirname "$1"`
      resolve_symlinks "`_prepend_path_if_relative "$dir_context" "$path"`"
   else
      echo "$1"
   fi
}


_canonicalize_dir_path()
{
    (cd "$1" 2>/dev/null && pwd -P)
}


_canonicalize_file_path()
{
    local dir file

    dir="` dirname "$1"`"
    file="`basename "$1"`"
    (cd "${dir}" 2>/dev/null && echo "`pwd -P`/${file}")
}


canonicalize_path()
{
   if [ -d "$1" ]
   then
      _canonicalize_dir_path "$1"
   else
      _canonicalize_file_path "$1"
   fi
}


realpath()
{
   canonicalize_path "`resolve_symlinks "$1"`"
}

# ----

relative_path_between()
{
   python -c "import os.path; print os.path.relpath( '$1', '$2')"
}


compute_relative()
{
   local depth
   local relative
   local name

   name="$1"

   depth=`path_depth "${name}"`
   if [ "${depth}" -gt 0 ]
   then
      relative=".."
      while [ "$depth" -gt 1 ]
      do
         relative="${relative}/.."
         depth=`expr $depth - 1`
      done
   fi
   echo "${relative}"
}


remove_absolute_path_prefix_up_to()
{
   local s
   local prefix

   s="$1"
   prefix="$2"

   if [ "`basename "${s}"`" = "${prefix}" ]
   then
      return 0
   fi

   echo "${s}" | sed "s|^.*/${prefix}/\(.*\)*|\1|g"
}


mkdir_if_missing()
{
   if [ ! -d "${1}" ]
   then
      log_fluff "Creating ${C_WHITE}$1${C_FLUFF} (`pwd -P`)"
      exekutor mkdir -p "$1" || fail "failed to create directory \"$1\""
   fi
}


#
# consider . .. ~ or absolute paths as unsafe
# anything starting with a $ is probably also bad
# this just catches some obvious problems, not all
#
assert_sane_subdir_path()
{
   case "$1"  in
      \$*|~/.|..|./|../|/*)
         log_error "refuse unsafe path ${C_WHITE}$1"
         exit 1
      ;;
   esac
}


assert_sane_path()
{
   case "$1"  in
      \$*|~/*|..|.|/|./|../*)
         log_error "refuse unsafe path ${C_WHITE}$1"
         exit 1
      ;;
   esac
}


rmdir_safer()
{
   if [ -d "$1" ]
   then
      assert_sane_path "$1"
      exekutor chmod -R u+w "$1" || fail "Failed to make $1 writable"
      exekutor rm -rf "$1" || fail "failed to remove ${1}"
   fi
}


user_say_yes()
{
  local  x

  x=`read_config_setting "answer" "ASK"`
  while [ "$x" != "Y" -a "$x" != "YES" -a  "$x" != "N"  -a  "$x" != "NO"  -a "$x" != "" ]
  do
     echo "${C_YELLOW}$* (${C_WHITE}y${C_YELLOW}/${C_GREEN}N${C_YELLOW})${C_RESET}" >&2
     read x
     x=`echo "${x}" | tr '[:lower:]' '[:upper:]'`
  done

  [ "$x" = "Y" -o "$x" = "YES" ]
  return $?
}


dir_can_be_rmdir()
{
   local empty

   if [ ! -d "$1" ]
   then
      return 2
   fi

   empty="`ls -A "$1" 2> /dev/null`"
   [ "$empty" = "" ]
}


# this does not check for hidden files
dir_has_files()
{
   local empty
   local result

   empty=`ls "$1"/* 2> /dev/null` 2> /dev/null
   [ "$empty" != "" ]
   result=$?

   if [ "$result" -eq 1 ]
   then
      log_fluff "Directory \"$1\" has no files"
   else
      log_fluff "Directory \"$1\" has files"
   fi
   return "$result"
}


#
# first find a project with matching name, otherwise find
# first nearest project
#
find_xcodeproj()
{
   local found
   local expect
   local depth

   found=""
   expect="$1"
   depth=1000
   #     IFS='\0'

   for i in `find . -name "*.xcodeproj" -print`
   do
      match=`basename "${i}" .xcodeproj`
      if [ "$match" = "$expect" ]
      then
         echo "$i"
         return 0
      fi

      new_depth=`path_depth "$i"`
      if [ "$new_depth" -lt "$depth" ]
      then
         found="${i}"
         depth="$new_depth"
      fi
   done

   if [ "$found" != "" ]
   then
      echo "${found}"
      return 0
   fi

   return 1
}


canonical_clone_name()
{
   local url

   url="${1}"

   basename "${url}" .git
}


# http://askubuntu.com/questions/152001/how-can-i-get-octal-file-permissions-from-command-line
lso()
{
   ls -aldG "$@" | \
   awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print }' | \
   awk '{print $1}'
}


run_script()
{
   local script

   script="$1"
   shift

   [ ! -z "$script" ] || internal_fail "script is empty"

   if [ -x "${script}" ]
   then
      log_info "Executing script ${C_WHITE}${script}${C_INFO}"
      exekutor "${script}" "$@" || fail "script \"${script}\" did not run successfully"
   else
      if [ ! -e "${script}" ]
      then
         fail "script \"${script}\" not found ($PWD)"
      else
         fail "script \"${script}\" not executable"
      fi
   fi
}


run_log_script()
{
   echo "$@"
   run_script "$@"
}
