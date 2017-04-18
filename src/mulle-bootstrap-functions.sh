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

[ ! -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && echo "double inclusion of functions" >&2 && exit 1
MULLE_BOOTSTRAP_FUNCTIONS_SH="included"

MULLE_BOOTSTRAP_FUNCTIONS_VERSION="3.0"

#
# WARNING! THIS FILE IS A LIBRARY USE BY OTHER PROJECTS
#          DO NOT CASUALLY RENAME, REORGANIZE STUFF
#
# ####################################################################
#                          Execution
# ####################################################################
# Execution
#

exekutor_trace()
{
   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" -o "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      local arrow

      [ -z "${MULLE_EXECUTABLE_PID}" ] && internal_fail "MULLE_EXECUTABLE_PID not set"

      if [ "${PPID}" -ne "${MULLE_EXECUTABLE_PID}" ]
      then
         arrow="=[${PPID}]=>"
      else
         arrow="==>"
      fi

      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "${arrow}" "$@" >&2
      else
         echo "${arrow}" "$@" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi
}


exekutor_trace_output()
{
   local redirect="$1"; shift
   local output="$1"; shift

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" -o "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      local arrow

      [ -z "${MULLE_EXECUTABLE_PID}" ] && internal_fail "MULLE_EXECUTABLE_PID not set"

      if [ "${PPID}" -ne "${MULLE_EXECUTABLE_PID}" ]
      then
         arrow="=[${PPID}]=>"
      else
         arrow="==>"
      fi

      if [ -z "${MULLE_EXEKUTOR_LOG_DEVICE}" ]
      then
         echo "${arrow}" "$@" "${redirect}" "${output}" >&2
      else
         echo "${arrow}" "$@" "${redirect}" "${output}" > "${MULLE_EXEKUTOR_LOG_DEVICE}"
      fi
   fi
}



exekutor()
{
   exekutor_trace "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      "$@"
   fi
}


eval_exekutor()
{
   exekutor_trace "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      ( eval "$@" )
   fi
}


redirect_exekutor()
{
   local output="$1"; shift

   exekutor_trace_output '>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      ( "$@" ) > "${output}"
   fi
}


redirect_append_exekutor()
{
   local output="$1"; shift

   exekutor_trace_output '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      ( "$@" ) >> "${output}"
   fi
}


_redirect_append_eval_exekutor()
{
   local output="$1"; shift

   exekutor_trace_output '>>' "${output}" "$@"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ]
   then
      ( eval "$@" ) >> "${output}"
   fi
}

#
# output eval trace also into logfile
#
logging_redirekt_exekutor()
{
   local output="$1"; shift

   local arrow

   if [ "${PPID}" -ne "${MULLE_EXECUTABLE_PID}" ]
   then
      arrow="=[${PPID}]=>"
   else
      arrow="==>"
   fi

   echo "${arrow}" "$@" > "${output}"

   redirect_append_exekutor "${output}" "$@"
}


logging_redirect_eval_exekutor()
{
   local output="$1"; shift

   # overwrite
   local arrow

   if [ "${PPID}" -ne "${MULLE_EXECUTABLE_PID}" ]
   then
      arrow="=[${PPID}]=>"
   else
      arrow="==>"
   fi

   echo "${arrow}" "$*" > "${output}" # to stdout

   # append
   _redirect_append_eval_exekutor "${output}" "$@"
}



# ####################################################################
#                            Strings
# ####################################################################
#
is_yes()
{
   local s

   s=`echo "$1" | tr '[:lower:]' '[:upper:]'`
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


add_cmake_path_if_exists()
{
   local line="$1"
   local path="$2"

   if [ ! -e "${path}" ]
   then
      echo "${line}"
   else
      if [ -z "${line}" ]
      then
         echo "${path}"
      else
         echo "${line};${path}"
      fi
   fi
}


add_cmake_path()
{
   local line="$1"
   local path="$2"


   if [ -z "${line}" ]
   then
      echo "${path}"
   else
      echo "${line};${path}"
   fi
}


add_line()
{
   local lines="$1"
   local line="$2"

   if [ -z "${lines}" ]
   then
      echo "${line}"
   else
      echo "${lines}
${line}"
   fi
}


escape_linefeeds()
{
   local text

   text="`echo "$@" | sed -e 's/|/\\|/g'`"
   /bin/echo -n "${text}" | tr '\012' '|'
}


unescape_linefeeds()
{
   echo "$@" | tr '|' '\012' | sed -e 's/\\$/|/g' -e '/^$/d'
}


#
# expands ${LOGNAME} and ${LOGNAME:-foo}
#
expand_environment_variables()
{
    local string="$1"

    local key
    local value
    local prefix
    local suffix
    local next

    key="`echo "${string}" | sed -n 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\2/p'`"
    if [ ! -z "${key}" ]
    then
       prefix="`echo "${string}" | sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\1/'`"
       suffix="`echo "${string}" | sed 's/^\(.*\)\${\([A-Za-z_][A-Za-z0-9_:-]*\)}\(.*\)$/\3/'`"
       value="`eval echo \$\{${key}\}`"
       if [ -z "${value}" ]
       then
          log_verbose "${key} expanded to empty string ($1)"
       fi

       next="${prefix}${value}${suffix}"
       if [ "${next}" != "${string}" ]
       then
          expand_environment_variables "${prefix}${value}${suffix}"
          return
       fi
    fi

    echo "${string}"
}



# ####################################################################
#                             Path handling
# ####################################################################
# 0 = ""
# 1 = /
# 2 = /tmp
# ...
#
path_depth()
{
   local name="$1"

   local depth

   depth=0

   if [ ! -z "${name}" ]
   then
      depth=1

      while [ "$name" != "." -a "${name}" != '/' ]
      do
         name="`dirname -- "$name"`"
         depth="`expr "$depth" + 1`"
      done
   fi
   echo "$depth"
}


#
# cuts off last extension only
#
extension_less_basename()
{
   local  filename

   filename="`basename -- "$1"`"
   echo "${filename%.*}"
}


path_concat()
{
   local i
   local s
   local sep

   for i in "$@"
   do
      sep="/"
      case "$i" in
        ""|"."|"./")
          continue
        ;;

        "/*")
          sep=""
        ;;

        "*/")
          i="`echo "${i}" | sed 's|/$||/g'`"
        ;;

      esac

      if [ -z "${s}" ]
      then
        s="$i"
      else
        s="${s}/${i}"
      fi
   done

   echo "${s}"
}


_canonicalize_dir_path()
{
   (
      cd "$1" 2>/dev/null &&
      pwd -P
   )  || exit 1
}


_canonicalize_file_path()
{
   local dir file

   dir="`dirname -- "$1"`"
   file="`basename -- "$1"`"
   (
     cd "${dir}" 2>/dev/null &&
     echo "`pwd -P`/${file}"
   ) || exit 1
}


canonicalize_path()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ -d "$1" ]
   then
      _canonicalize_dir_path "$1"
   else
      _canonicalize_file_path "$1"
   fi
}

#
# canonicalizes existing paths
# fails for files / directories that do not exist
#
realpath()
{
   [ -e "$1" ] || fail "only use realpath on existing files ($1)"

   canonicalize_path "`resolve_symlinks "$1"`"
}


# ----
# stolen from: https://stackoverflow.com/questions/2564634/convert-absolute-path-into-relative-path-given-a-current-directory-using-bash
# because the python dependency irked me
# there must be no ".." or "." in the path
#
__relative_path_between()
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


_relative_path_between()
{
   local a
   local b

   if [ "${MULLE_TRACE_PATHS_FLIP_X}" = "YES" ]
   then
      set +x
   fi

   # remove relative components and './' it upsets the code

   a="`simplified_path "$1"`"
   b="`simplified_path "$2"`"

#   a="`echo "$1" | sed -e 's|/$||g'`"
#   b="`echo "$2" | sed -e 's|/$||g'`"

   [ -z "${a}" ] && internal_fail "Empty path (\$1)"
   [ -z "${b}" ] && internal_fail "Empty path (\$2)"

   __relative_path_between "${b}" "${a}"   # flip args (historic)

   if [ "${MULLE_TRACE_PATHS_FLIP_X}" = "YES" ]
   then
      set -x
   fi
}


#
# $1 is the directory, that we want to access relative from root
# $2 is the root
#
# ex.   /usr/include /usr,  -> include
# ex.   /usr/include /  -> /usr/include
#
# the routine can not deal with ../ and ./
# but is a bit faster than symlink_relpath
#
relative_path_between()
{
   local  a="$1"
   local  b="$2"

   # the function can't do mixed paths

   case "${a}" in
      ../*|*/..|*/../*|..)
         internal_fail "Path \"${a}\" mustn't contain ../"
      ;;

      ./*|*/.|*/./*|.)
         internal_fail "Path \"${a}\" mustn't contain ./"
      ;;


      /*)
         case "${b}" in
            ../*|*/..|*/../*|..)
               internal_fail "Path \"${b}\" mustn't contain ../"
            ;;

            ./*|*/.|*/./*|.)
               internal_fail "Path \"${b}\" mustn't contain ./"
            ;;


            /*)
            ;;

            *)
               internal_fail "Mixing absolute path \"${a}\" and relative path \"${b}\""
            ;;
         esac
      ;;

      *)
         case "${b}" in
            ../*|*/..|*/../*|..)
               internal_fail "Path \"${b}\" mustn't contain ../"
            ;;

            ./*|*/.|*/./*|.)
               internal_fail "Path \"${b}\" mustn't contain ./"
            ;;

            /*)
               internal_fail "Mixing relative path \"${a}\" and absolute path \"${b}\""
            ;;

            *)
            ;;
         esac
      ;;
   esac

   _relative_path_between "${a}" "${b}"
}


#
# compute number of .. needed to return from path
# e.g.  cd "a/b/c" -> cd ../../..
#
compute_relative()
{
   local name="$1"

   local depth
   local relative

   depth="`path_depth "${name}"`"
   if [ "${depth}" -gt 1 ]
   then
      relative=".."
      while [ "$depth" -gt 2 ]
      do
         relative="${relative}/.."
         depth="`expr "${depth}" - 1`"
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
   local s="$1"
   local prefix="$2"

   if [ "`basename -- "${s}"`" = "${prefix}" ]
   then
      return 0
   fi

   echo "${s}" | sed "s|^.*/${prefix}/\(.*\)*|\1|g"
}


#
# this cds into a physical directory, so that .. is relative to it
# e.g. cd a/b/c might  end up being a/c, so .. is a
# if you just go a/b/c then .. is b
#
cd_physical()
{
   cd "$1" || fail "cd: \"$1\" is not reachable from \"`pwd`\""
   cd "`pwd -P`"
}


absolutepath()
{
   case "${1}" in
      '/'*|'~'*)
        simplified_path "${1}"
      ;;

      *)
        simplified_path "`pwd`/${1}"
      ;;
   esac
}


#
# Imagine you are in a working directory `dirname b`
# This function gives the relpath you need
# if you were to create symlink 'b' pointing to 'a'
#
symlink_relpath()
{
   local a
   local b

   a="`absolutepath "$1"`"
   b="`absolutepath "$2"`"

   _relative_path_between "${a}" "${b}"
}


escaped_spaces()
{
   echo "$1" | sed 's/ /\\ /g'
}


combined_escaped_search_path_if_exists()
{
   local i
   local combinedpath

   for i in "$@"
   do
      if [ ! -z "${i}" ]
      then
         i="`escaped_spaces "${i}"`"
         if [ -e "${i}" ]
         then
           if [ -z "$combinedpath" ]
           then
              combinedpath="${i}"
           else
              combinedpath="${combinedpath} ${i}"
           fi
        fi
      fi
   done

   echo "${combinedpath}"
}


combined_escaped_search_path()
{
   local i
   local combinedpath

   for i in "$@"
   do
      if [ ! -z "${i}" ]
      then
         i="`escaped_spaces "${i}"`"
         if [ -z "$combinedpath" ]
         then
            combinedpath="${i}"
         else
            combinedpath="${combinedpath} ${i}"
         fi
      fi
   done

   echo "${combinedpath}"
}


_simplify_components()
{
   local i
   local result

   [ -z "${MULLE_BOOTSTRAP_ARRAY_SH}" ] && . mulle-bootstrap-array.sh

   result= # voodoo linux fix ?
   IFS="
"
   for i in $*
   do
      IFS="${DEFAULT_IFS}"

      case "${i}" in
         # ./foo -> foo
         ./)
         ;;

         # bar/.. -> ""
         ../)
            if [ -z "${result}" ]
            then
               result="`array_add "${result}" "../"`"
            else
               if [ "${result}" != "/" ]
               then
                  result="`array_remove_last "${result}"`"
               fi
               # /.. -> /
            fi
         ;;


         # foo/ -> foo
         "/")
            if [ -z "${result}" ]
            then
               result="${i}"
            fi
         ;;

         *)
            result="`array_add "${result}" "${i}"`"
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"

   echo "${result}"
}


_path_from_components()
{
   local components

   components="$1"

   local i
   local composedpath  # renamed this from path, fixes crazy bug on linux ?

   IFS="
"
   for i in $components
   do
      composedpath="${composedpath}${i}"
   done

   IFS="${DEFAULT_IFS}"

   if [ -z "${composedpath}" ]
   then
      echo "."
   else
      echo "${composedpath}" | sed 's|^\(..*\)/$|\1|'
   fi
}


#
# _simplified_path() works on paths that may or may not exist
# it makes prettier relative or absolute paths
# you can't have | in your path though
#
_simplified_path()
{
   local filepath="$1"

   [ -z "${filepath}" ] && fail "empty path given"

   local i
   local last
   local result
   local remove_empty

#   log_printf "${C_INFO}%b${C_RESET}\n" "$filepath"

   remove_empty="NO"  # remove trailing slashes

   IFS="/"
   for i in ${filepath}
   do
#      log_printf "${C_FLUFF}%b${C_RESET}\n" "$i"
      case "$i" in
         \.)
           remove_empty="YES"
           continue
         ;;

         \.\.)
           # remove /..
           remove_empty="YES"

           if [ "${last}" = "|" ]
           then
              continue
           fi

           if [ ! -z "${last}" -a "${last}" != ".." ]
           then
              result="$(sed '$d' <<< "${result}")"
              last="$(sed -n '$p' <<< "${result}")"
              continue
           fi
         ;;

         ~*)
            fail "Can't deal with ~ filepaths"
         ;;

         "")
            if [ "${remove_empty}" = "NO" ]
            then
               last='|'
               result='|'
            fi
            continue
         ;;
      esac

      remove_empty="YES"

      last="${i}"
      if [ -z "${result}" ]
      then
         result="${i}"
      else
         result="${result}
${i}"
      fi
   done

   IFS="${DEFAULT_IFS}"

   if [ -z "${result}" ]
   then
      echo "."
      return
   fi

   if [ "${result}" = '|' ]
   then
      echo "/"
      return
   fi

   printf "%s" "${result}" | tr -d '|' | tr '\012' '/'
   echo
}


simplified_path()
{
   if [ "${MULLE_TRACE_PATHS_FLIP_X}" = "YES" ]
   then
      set +x
   fi

   if [ ! -z "$1" ]
   then
      _simplified_path "$@"
   else
      echo "."
   fi

   if [ "${MULLE_TRACE_PATHS_FLIP_X}" = "YES" ]
   then
      set -x
   fi
}


#
# consider . .. ~ or absolute paths as unsafe
# anything starting with a $ is probably also bad
# this just catches some obvious problems, not all
#
assert_sane_subdir_path()
{
   local file

   file="`simplified_path "$1"`"

   case "$file"  in
      "")
         log_error "refuse empty subdirectory"
         exit 1
      ;;

      \$*|~|..|.|/*)
         log_error "refuse unsafe subdirectory path \"$1\""
         exit 1
      ;;
   esac
}


assert_sane_path()
{
   local file

   file="`simplified_path "$1"`"

   case "$file" in
      \$*|~|${HOME}|..|.)
         log_error "refuse unsafe path \"$1\""
         exit 1
      ;;

      ""|/*)
         if [ `path_depth "${file}"` -le 2 ]
         then
            log_error "refuse suspicious path \"$1\""
            exit 1
         fi
      ;;
   esac
}


prepend_to_search_path_if_missing()
{
   local fullpath="$1"; shift

   local new_path
   local tail_path
   local binpath

   tail_path=""
   new_path=""

   local oldifs
   local i

   oldifs="$IFS"
   IFS=":"

   for i in $fullpath
   do
      IFS="${oldifs}"

      # shims stay in front (homebrew)
      case "$i" in
         */shims/*)
            new_path="`add_path "${new_path}" "$i"`"
         ;;
      esac
   done

   #
   #
   #
   while [ $# -gt 0 ]
   do
      binpath="$1"
      shift

      binpath="`absolutepath "${binpath}"`"

      IFS=":"
      for i in $fullpath
      do
         IFS="${oldifs}"

         # don't duplicate if already in there
         case "$i" in
           "${binpath}/"|"${binpath}")
               binpath=""
               break
         esac
      done
      IFS="${oldifs}"

      if [ -z "${binpath}" ]
      then
         continue
      fi

      tail_path="`add_path "${tail_path}" "${binpath}"`"
   done

   IFS=":"
   for i in $fullpath
   do
      IFS="${oldifs}"

      # shims stay in front (homebrew)
      case "$i" in
         */shims/*)
            continue;
         ;;

         *)
            tail_path="`add_path "${tail_path}" "${i}"`"
         ;;
      esac
   done
   IFS="${oldifs}"

   add_path "${new_path}" "${tail_path}"
}


# ####################################################################
#                        Files and Directories
# ####################################################################
#
mkdir_if_missing()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ ! -d "$1" ]
   then
      log_fluff "Creating \"$1\" ($PWD)"
      exekutor mkdir -p "$1" || fail "failed to create directory \"$1\""
   fi
}



dir_is_empty()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ ! -d "$1" ]
   then
      return 2
   fi

   local empty

   empty="`ls -A "$1" 2> /dev/null`"
   [ "$empty" = "" ]
}


rmdir_safer()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ -d "$1" ]
   then
      assert_sane_path "$1"
      exekutor chmod -R u+w "$1"  >&2 || fail "Failed to make $1 writable"
      exekutor rm -rf "$1"  >&2 || fail "failed to remove $1"
   fi
}


rmdir_if_empty()
{
   [ -z "$1" ] && internal_fail "empty path"

   if dir_is_empty "$1"
   then
      exekutor rmdir "$1"  >&2 || fail "failed to remove $1"
   fi
}


_create_file_if_missing()
{
   local path="$1" ; shift

   [ -z "${path}" ] && internal_fail "empty path"

   if [ -f "${path}" ]
   then
      return
   fi

   local directory

   directory="`dirname "${path}"`"
   if [ ! -z "${directory}" ]
   then
      mkdir_if_missing "${directory}"
   fi

   log_fluff "Creating \"${path}\""
   if [ ! -z "$*" ]
   then
      redirect_exekutor "${path}" echo "$*" || fail "failed to create \"{path}\""
   else
      exekutor touch "${path}"  || fail "failed to create \"${path}\""
   fi
}


merge_line_into_file()
{
  local path="$1"
  local line="$2"

  if fgrep -s -q -x "${name}" "${path}" 2> /dev/null
  then
     return
  fi
  redirect_append_exekutor "${path}" echo "${line}"
}


create_file_if_missing()
{
  _create_file_if_missing "$1" "# intentionally blank file"
}


remove_file_if_present()
{
   [ -z "$1" ] && internal_fail "empty path"

   if [ -e "$1" ]
   then
      log_fluff "Removing \"$1\""
      exekutor chmod u+w "$1"  >&2 || fail "Failed to make $1 writable"
      exekutor rm -f "$1"  >&2 || fail "failed to remove \"$1\""
   fi
}

#
# the target of the symlink must exist
#
create_symlink()
{
   local url="$1"       # URL of the clone
   local stashdir="$2"  # stashdir of this clone (absolute or relative to $PWD)
   local absolute="$3"

   local srcname
   local directory

   [ -e "${url}" ]        || fail "${C_RESET}${C_BOLD}${url}${C_ERROR} does not exist ($PWD)"
   [ ! -z "${absolute}" ] || fail "absolute must be YES or NO"

   url="`absolutepath "${url}"`"
   url="`realpath "${url}"`"  # resolve symlinks

   srcname="`basename -- ${url}`"
   directory="`dirname -- "${stashdir}"`"
   directory="`realpath "${directory}"`"  # resolve symlinks

   mkdir_if_missing "${directory}"

   #
   # relative paths look nicer, but could fail in more complicated
   # settings, when you symlink something, and that repo has symlinks
   # itself
   #
   if [ "${absolute}" = "NO" ]
   then
      url="`symlink_relpath "${url}" "${directory}"`"
   fi

   log_info "Symlinking ${C_MAGENTA}${C_BOLD}${srcname}${C_INFO} as \"${url}\" in \"${directory}\" ..."
   exekutor ln -s -f "${url}" "${stashdir}"  >&2 || fail "failed to setup symlink \"${stashdir}\" (to \"${url}\")"
}


modification_timestamp()
{
   case "${UNAME}" in
      linux|mingw)
         stat --printf "%Y\n" "$1"
         ;;
      * )
         stat -f "%m" "$1"
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


#
# this does not check for hidden files, ignores directories
# optionally give filetype f or d as second agument
#
dir_has_files()
{
   local dirpath="$1"; shift

   local flags
   case "$1" in
      f)
         flags="-type f"
         shift
      ;;

      d)
         flags="-type d"
         shift
      ;;
   esac

   local empty
   local result

   empty="`find "${dirpath}" -xdev -mindepth 1 -maxdepth 1 -name "[a-zA-Z0-9_-]*" ${flags} "$@" -print 2> /dev/null`"
   [ ! -z "$empty" ]
}



has_usr_local_include()
{
   local name="$1"

   if [ -d "${USR_LOCAL_INCLUDE}/${name}" ]
   then
      return 0
   fi

   local include_name

   include_name="`echo "${name}" | tr '-' '_'`"

   [ -d "${USR_LOCAL_INCLUDE}/${include_name}" ]
}


write_protect_directory()
{
   if [ -d "$1" ]
   then
      #
      # ensure basic structure is there to squelch linker warnings
      #
      log_fluff "Create default lib/include/Frameworks in $1"
      exekutor mkdir "$1/Frameworks" 2> /dev/null
      exekutor mkdir "$1/lib" 2> /dev/null
      exekutor mkdir "$1/include" 2> /dev/null

      log_verbose "Write-protecting ${C_RESET_BOLD}$1${C_VERBOSE} to avoid spurious header edits"
      exekutor chmod -R a-w "$1"
   fi
}


# ####################################################################
#                               Init
# ####################################################################
functions_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

   log_debug ":functions_initialize:"

   :
}


functions_initialize
