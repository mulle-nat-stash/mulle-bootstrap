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

# Escape sequence and resets, should use tput here instead of ANSI

if [ "${MULLE_BOOTSTRAP_NO_COLOR}" != "YES" ]
then
   case `uname` in
      Darwin|Linux|FreeBSD)
         C_RESET="\033[0m"

         # Useable Foreground colours, for black/white white/black
         C_RED="\033[0;31m"     C_GREEN="\033[0;32m"
         C_BLUE="\033[0;34m"    C_MAGENTA="\033[0;35m"
         C_CYAN="\033[0;36m"

         C_BR_RED="\033[0;91m"
         C_BOLD="\033[1m"
         C_FAINT="\033[2m"

         C_RESET_BOLD="${C_RESET}${C_BOLD}"
         trap 'printf "${C_RESET}"' TERM EXIT
         ;;
   esac
fi


C_ERROR="${C_RED}${C_BOLD}"
log_error()
{
   printf "${C_ERROR}%b${C_RESET}\n" "$*" >&2
}


C_WARNING="${C_MAGENTA}${C_BOLD}"
log_warning()
{
   if [ "${MULLE_BOOTSTRAP_TERSE}" != "YES" ]
   then
      printf "${C_WARNING}%b${C_RESET}\n" "$*" >&2
   fi
}


C_INFO="${C_CYAN}${C_BOLD}"
log_info()
{
   if [ "${MULLE_BOOTSTRAP_TERSE}" != "YES" ]
   then
      printf "${C_INFO}%b${C_RESET}\n" "$*" >&2
   fi
}


C_FLUFF="${C_GREEN}${C_BOLD}"
log_fluff()
{
   if [ "${MULLE_BOOTSTRAP_VERBOSE}" = "YES"  ]
   then
      printf "${C_FLUFF}%b${C_RESET}\n" "$*" >&2
   fi
}


C_TRACE="${C_FLUFF}${C_FAINT}"
log_trace()
{
   printf "${C_TRACE}%b${C_RESET}\n" "$*" >&2
}


C_TRACE2="${C_RESET}${C_FAINT}"
log_trace2()
{
   printf "${C_TRACE2}%b${C_RESET}\n" "$*" >&2
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
   fail "${C_RED}*** internal error: ${C_BR_RED}$*"
}



eval_exekutor()
{
   if [ "${MULLE_BOOTSTRAP_DRY_RUN}" = "YES" -o "${MULLE_BOOTSTRAP_TRACE}" = "YES" ]
   then
      echo "==> " "$@" >&2
   fi

   if [ "${MULLE_BOOTSTRAP_DRY_RUN}" != "YES" ]
   then
      eval "$@"
   fi
}


logging_eval_exekutor()
{
   echo "==>" "$@"
   eval_exekutor "$@"
}


exekutor()
{
   if [ "${MULLE_BOOTSTRAP_DRY_RUN}" = "YES" -o "${MULLE_BOOTSTRAP_TRACE}" = "YES" ]
   then
      echo "==>" "$@" >&2
   fi

   if [ "${MULLE_BOOTSTRAP_DRY_RUN}" != "YES" ]
   then
      "$@"
   fi
}


logging_exekutor()
{
   echo "==>" "$@"
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
         name=`dirname -- "$name"`
         depth=`expr $depth + 1`
      done
   fi
   echo "$depth"
}


extension_less_basename()
{
   local  file

   file="`basename -- "$1"`"
   echo "${file%.*}"
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
      dir_context=`dirname -- "$1"`
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
    file="`basename -- "$1"`"
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
# stolen from: https://stackoverflow.com/questions/2564634/convert-absolute-path-into-relative-path-given-a-current-directory-using-bash
# because the python dependency irked me
#
_relative_path_between()
{
    [ $# -ge 1 ] && [ $# -le 2 ] || return 1
    current="${2:+"$1"}"
    target="${2:-"$1"}"
    [ "$target" != . ] || target=/
    target="/${target##/}"
    [ "$current" != . ] || current=/
    current="${current:="/"}"
    current="/${current##/}"
    appendix="${target##/}"
    relative=''
    while appendix="${target#"$current"/}"
        [ "$current" != '/' ] && [ "$appendix" = "$target" ]; do
        if [ "$current" = "$appendix" ]; then
            relative="${relative:-.}"
            echo "${relative#/}"
            return 0
        fi
        current="${current%/*}"
        relative="$relative${relative:+/}.."
    done
    relative="$relative${relative:+${appendix:+/}}${appendix#/}"
    echo "$relative"
}


relative_path_between()
{
   _relative_path_between "$2" "$1"
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

#   if [ -z "$relative" ]
#   then
#      relative="."
#   fi

   echo "${relative}"
}


remove_absolute_path_prefix_up_to()
{
   local s
   local prefix

   s="$1"
   prefix="$2"

   if [ "`basename -- "${s}"`" = "${prefix}" ]
   then
      return 0
   fi

   echo "${s}" | sed "s|^.*/${prefix}/\(.*\)*|\1|g"
}


escaped_spaces()
{
   echo "$1" | sed 's/ /\\ /g'
}


combined_escaped_search_path()
{
   local i
   local path

   for i in "$@"
   do
      if [ ! -z "$i" ]
      then
         i="`escaped_spaces "$i"`"
         if [ -z "$path" ]
         then
            path="$i"
         else
            path="$path $i"
         fi
      fi
   done

   echo "${path}"
}


mkdir_if_missing()
{
   if [ ! -d "${1}" ]
   then
      log_fluff "Creating \"$1\" (`pwd -P`)"
      exekutor mkdir -p "$1" || fail "failed to create directory \"$1\""
   fi
}


create_file_if_missing()
{
   if [ ! -f "${1}" ]
   then
      log_fluff "Creating \"$1\" (`pwd -P`)"
      exekutor touch "$1" || fail "failed to create \"$1\""
   fi
}


remove_file_if_present()
{
   if [ -f "${1}" ]
   then
      log_fluff "Removing \"$1\" (`pwd -P`)"
      exekutor rm -f "$1" || fail "failed to remove \"$1\""
   fi
}


modification_timestamp()
{
   case "`uname`" in
      Linux )
         stat --printf "%Y\n" "$1"
         ;;
      * )
         stat -f "%m" "$1"
         ;;
   esac
}


simplify_path()
{
   local file

   file="${1}"

   local modification

   # foo/ -> foo
   modification="`echo "${1}" | sed 's|^\(.*\)/$|\1|'`"
   if  [ "${modification}" != "${file}" ]
   then
      simplify_path "${modification}"
      return
   fi

   # ./foo -> foo
   modification="`echo "${1}" | sed 's|^\./\(.*\)$|\1|'`"
   if  [ "${modification}" != "${file}" ]
   then
      simplify_path "${modification}"
      return
   fi

   # foo/. -> foo
   modification="`echo "${1}" | sed 's|^\(.*\)/\.$|\1|'`"
   if  [ "${modification}" != "${file}" ]
   then
      simplify_path "${modification}"
      return
   fi

   # bar/./foo -> bar/foo
   modification="`echo "${1}" | sed 's|^\(.*\)/\./\(.*\)$|\1/\2|'`"
   if  [ "${modification}" != "${file}" ]
   then
      simplify_path "${modification}"
      return
   fi

   # bar/.. -> ""
   modification="`echo "${1}" | sed 's|^\([^/]*\)/\.\.$||'`"
   if  [ "${modification}" != "${file}" ]
   then
      simplify_path "${modification}"
      return
   fi

   # bar/../foo -> foo
   modification="`echo "${1}" | sed 's|^\([^/]*\)/\.\./\(.*\)$|\2|'`"
   if  [ "${modification}" != "${file}" ]
   then
      simplify_path "${modification}"
      return
   fi

   # bar/baz/../foo -> bar/foo
   modification="`echo "${1}" | sed 's|^\(.*\)/\([^/]*\)/\.\./\(.*\)$|\1/\3|'`"
   if  [ "${modification}" != "${file}" ]
   then
      simplify_path "${modification}"
      return
   fi

   echo "${modification}"
}


#
# consider . .. ~ or absolute paths as unsafe
# anything starting with a $ is probably also bad
# this just catches some obvious problems, not all
#
assert_sane_subdir_path()
{
   local file

   file="`simplify_path "${1}"`"

   if [ -z "${file}" ]
   then
         log_error "refuse unsafe subdirectory path \"$1\""
         exit 1
   fi

   case "$file"  in
      \$*|~|..|.|/*)
         log_error "refuse unsafe subdirectory path \"$1\""
         exit 1
      ;;
   esac
}


assert_sane_path()
{
   local file

   file="`simplify_path "${1}"`"

   if [ -z "${file}" ]
   then
         log_error "refuse unsafe path \"$1\""
         exit 1
   fi

   case "$file"  in
      \$*|~|${HOME}|..|.|/)
         log_error "refuse unsafe path \"$1\""
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
     printf "${C_WARNING}%b${C_RESET} (y/${C_GREEN}N${C_RESET}) > " "$*" >&2
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

   local match
   local new_depth

   for i in `find . -name "*.xcodeproj" -print`
   do
      match=`basename -- "${i}" .xcodeproj`
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


# deal with stuff like
# foo
# https://www./foo.git
# host:foo
#
canonical_clone_name()
{
   local  url

   url="$1"

   # cut off scheme part

   case "$url" in
      *:*)
         url="`echo "$@" | sed 's/^\(.*\):\(.*\)/\2/'`"
         ;;
   esac

   extension_less_basename "$url"
}


count_clone_components()
{
  echo "$@" | tr ';' '\012' | wc -l | awk '{ print $1 }'
}


url_from_clone()
{
   echo "$@" | cut '-d;' -f 1
}


_name_part_from_clone()
{
   echo "$@" | cut '-d;' -f 2
}


_branch_part_from_clone()
{
   echo "$@" | cut '-d;' -f 3
}


_scm_part_from_clone()
{
   echo "$@" | cut '-d;' -f 4
}


canonical_name_from_clone()
{
   local url
   local name
   local branch

   url="`url_from_clone "$@"`"
   name="`_name_part_from_clone "$@"`"

   if [ ! -z "${name}" -a "${name}" != "${url}" ]
   then
      canonical_clone_name "${name}"
      return
   fi

   canonical_clone_name "${url}"
}


branch_from_clone()
{
   local count

   count="`count_clone_components "$@"`"
   if [ "$count" -ge 3 ]
   then
      _branch_part_from_clone "$@"
   fi
}


scm_from_clone()
{
   local count

   count="`count_clone_components "$@"`"
   if [ "$count" -ge 4 ]
   then
      _scm_part_from_clone "$@"
   fi
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
      log_fluff "Executing script \"${script}\" $1"
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


ensure_clones_directory()
{
   if [ ! -d "${CLONESFETCH_SUBDIR}" ]
   then
      if [ "${COMMAND}" = "update" ]
      then
         fail "install first before upgrading"
      fi
      mkdir_if_missing "${CLONESFETCH_SUBDIR}"
   fi
}


ensure_consistency()
{
   if [ -f "${CLONESFETCH_SUBDIR}/.fetch_update_started" ]
   then
      log_error "A previous fetch or update was incomplete.
Suggested resolution (in $PWD):
    ${C_RESET_BOLD}mulle-bootstrap clean dist${C_ERROR}
    ${C_RESET_BOLD}mulle-bootstrap${C_ERROR}

Or do you feel lucky ?
   ${C_RESET_BOLD}rm ${CLONESFETCH_SUBDIR}/.fetch_update_started${C_ERROR}
and try again. But you've gotta ask yourself one question: Do I feel lucky ?
Well, do ya, punk? "
      exit 1
   fi
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
