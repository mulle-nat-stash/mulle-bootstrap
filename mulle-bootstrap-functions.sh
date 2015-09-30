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
fi


C_ERROR="${C_RED}"
log_error()
{
   echo "${C_ERROR}$*${C_RESET}" >&2
}


C_WARNING="${C_YELLOW}"
log_warning()
{
   if [ "$MULLE_BOOTSTRAP_TERSE" != "YES" ]
   then
      echo "${C_WARNING}$*${C_RESET}" >&2
   fi
}


C_INFO="${C_CYAN}"
log_info()
{
   if [ "$MULLE_BOOTSTRAP_TERSE" != "YES" ]
   then
      echo "${C_INFO}$*${C_RESET}" >&2
   fi
}


C_FLUFF="${C_GREEN}"
log_fluff()
{
   if [ "$MULLE_BOOTSTRAP_VERBOSE" = "YES"  ]
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
   fail "**** mulle-bootstrap internal error ****
$*"
}



eval_exekutor()
{
   if [ "$MULLE_BOOTSTRAP_DRY_RUN" = "YES" -o "$MULLE_BOOTSTRAP_TRACE" = "YES" ]
   then
      echo "$@" >&2
   fi

   if [ "$MULLE_BOOTSTRAP_DRY_RUN" != "YES" ]
   then
      eval "$@"
   fi
}

exekutor()
{
   if [ "$MULLE_BOOTSTRAP_DRY_RUN" = "YES" -o "$MULLE_BOOTSTRAP_TRACE" = "YES" ]
   then
      echo "$@" >&2
   fi

   if [ "$MULLE_BOOTSTRAP_DRY_RUN" != "YES" ]
   then
      "$@"
   fi
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


relative_path_between()
{
   python -c "import os.path; print os.path.relpath(\'$1\', \'$2\')"
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


user_say_yes()
{
  local  x

  x="nix"
  while [ "$x" != "y" -a "$x" != "n" -a "$x" != "" ]
  do
     echo "${C_YELLOW}$* (${C_WHITE}y${C_YELLOW}/${C_GREEN}N${C_YELLOW})${C_RESET}" >&2
     read x
  done

  [ "$x" = "y" ]
  return $?
}


is_dir_empty()
{
   local empty

   empty=`ls "$1"/* 2> /dev/null` 2> /dev/null
   [ "$empty" = "" ]
}


dir_has_files()
{
   local empty

   empty=`ls "$1"/* 2> /dev/null` 2> /dev/null
   [ "$empty" != "" ]
}


fetch_brew_if_needed()
{
   local last_update
   local binary

   last_update="${HOME}/.mulle-bootstrap/brew-update"

   binary=`which brew`
   if [ "${binary}" = "" ]
   then
      user_say_yes "Brew isn't installed on this system.
Install brew now (Linux or OS X should work) ? "
      if [ $? -ne 0 ]
      then
         return 1
      fi
      if [ "`uname`" = 'Darwin' ]
      then
         exekutor ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 1
      else
         exekutor ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" || exit 1
      fi

      exekutor mkdir -p "`dirname "${last_update}"`" 2> /dev/null
      exekutor touch "${last_update}"
      return 1
   fi
   return 0
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


#
# consider . .. ~ or absolute paths as unsafe
# anything starting with a $ is probably also bad
# this just catches some obvious problems, not all
# when in the environment, clones_subdir may be ..
#
assert_sane_path()
{
   case "$1"  in
      \$*|~/.|..|./|../|/*)
         log_error "refuse unsafe path ${C_WHITE}$1"
         exit 1
      ;;
   esac
}


# http://askubuntu.com/questions/152001/how-can-i-get-octal-file-permissions-from-command-line
lso()
{
   ls -aldG "$@" | \
   awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print }' | \
   awk '{print $1}'
}
