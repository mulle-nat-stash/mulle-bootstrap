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

[ ! -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && echo "double inclusion of functions" >&2 && exit 1
MULLE_BOOTSTRAP_FUNCTIONS_SH="included"

MULLE_BOOTSTRAP_FUNCTIONS_VERSION="2.0"

#
# WARNING! THIS FILE IS A LIBRARY USE BY OTHER PROJECTS
#          DO NOT CASUALLY RENAME, REORGANIZE STUFF
#
# ####################################################################
#                          Execution
# ####################################################################
# Execution
#
eval_exekutor()
{
   if [ "${MULLE_EXECUTOR_DRY_RUN}" = "YES" -o "${MULLE_EXECUTOR_TRACE}" = "YES" ]
   then
      if [ -z "${MULLE_LOG_DEVICE}" ]
      then
         echo "==>" "$@" >&2
      else
         echo "==>" "$@" > "${MULLE_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_EXECUTOR_DRY_RUN}" != "YES" ]
   then
      eval "$@"
   fi
}


redirect_append_eval_exekutor()
{
   local output

   output="$1"
   shift

   if [ "${MULLE_EXECUTOR_DRY_RUN}" = "YES" -o "${MULLE_EXECUTOR_TRACE}" = "YES" ]
   then
      if [ -z "${MULLE_LOG_DEVICE}" ]
      then
         echo "==>" "$@" ">" "${output}" >&2
      else
         echo "==>" "$@" ">" "${output}" > "${MULLE_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_EXECUTOR_DRY_RUN}" != "YES" ]
   then
      eval "$@" >> "${output}"
   fi
}


logging_redirect_eval_exekutor()
{
   local output

   output="$1"
   shift

   echo "==>" "$@" > "${output}" # to stdout
   redirect_append_eval_exekutor "$1" "$@"
}


exekutor()
{
   if [ "${MULLE_EXECUTOR_DRY_RUN}" = "YES" -o "${MULLE_EXECUTOR_TRACE}" = "YES" ]
   then
      if [ -z "${MULLE_LOG_DEVICE}" ]
      then
         echo "==>" "$@" >&2
      else
         echo "==>" "$@" > "${MULLE_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_EXECUTOR_DRY_RUN}" != "YES" ]
   then
      "$@"
   fi
}


redirect_exekutor()
{
   local output

   output="$1"
   shift

   if [ "${MULLE_EXECUTOR_DRY_RUN}" = "YES" -o "${MULLE_EXECUTOR_TRACE}" = "YES" ]
   then
      if [ -z "${MULLE_LOG_DEVICE}" ]
      then
         echo "==>" "$@" ">" "${output}" >&2
      else
         echo "==>" "$@" ">" "${output}" > "${MULLE_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_EXECUTOR_DRY_RUN}" != "YES" ]
   then
      "$@" > "${output}"
   fi
}


redirect_append_exekutor()
{
   local output

   output="$1"
   shift

   if [ "${MULLE_EXECUTOR_DRY_RUN}" = "YES" -o "${MULLE_EXECUTOR_TRACE}" = "YES" ]
   then
      if [ -z "${MULLE_LOG_DEVICE}" ]
      then
         echo "==>" "$@" ">" "${output}" >&2
      else
         echo "==>" "$@" ">" "${output}" > "${MULLE_LOG_DEVICE}"
      fi
   fi

   if [ "${MULLE_EXECUTOR_DRY_RUN}" != "YES" ]
   then
      "$@" >> "${output}"
   fi
}


logging_redirekt_exekutor()
{
   local output

   output="$1"
   shift

   echo "==>" "$@" > "${output}"
   redirect_append_exekutor "${output}" "$@"
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


add_cmake_path()
{
   local line
   local path

   line="$1"
   path="$2"

   if [ -z "${line}" ]
   then
      echo "${path}"
   else
      echo "${line};${path}"
   fi
}


add_path()
{
   local line
   local path

   [ -z "${PATH_SEPARATOR}" ] && fail "PATH_SEPARATOR is undefined"

   line="$1"
   path="$2"

   case "${UNAME}" in
      mingw)
         path="`echo "${path}" | tr '/' '\\' 2> /dev/null`"
      ;;
   esac

   if [ -z "${line}" ]
   then
      echo "${path}"
   else
      echo "${line}${PATH_SEPARATOR}${path}"
   fi
}


add_line()
{
   local lines
   local line

   lines="$1"
   line="$2"

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
    local string

    string="$1"

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
       next="${prefix}${value}${suffix}"
       if [ "${next}" != "${string}" ]
       then
          expand_environment_variables "${prefix}${value}${suffix}"
          return
       fi
    fi
    echo "$1"
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
   local name
   local depth

   name="$1"
   depth=0

   if [ ! -z "${name}" ]
   then
      depth=1

      while [ "$name" != "." -a "${name}" != '/' ]
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

    dir="`dirname -- "$1"`"
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

#
# canonicalizes existing paths
# fails for files / directories that do not exist
#
realpath()
{
   [ -e "$1" ] && fail "only use realpath on existing files"

   canonicalize_path "`resolve_symlinks "$1"`"
}


# ----
# stolen from: https://stackoverflow.com/questions/2564634/convert-absolute-path-into-relative-path-given-a-current-directory-using-bash
# because the python dependency irked me
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

   if [ "${MULLE_BOOTSTRAP_PATHS_FLIP_X}" = "YES" ]
   then
      set +x
   fi

   # remove trailing '/' it upsets the code

   a="`echo "$1" | sed -e 's|/$||g'`"
   b="`echo "$2" | sed -e 's|/$||g'`"

   [ -z "${a}" ] && internal_fail "Empty path (\$1)"
   [ -z "${b}" ] && internal_fail "Empty path (\$2)"

   __relative_path_between "${b}" "${a}"   # flip args (historic)

   if [ "${MULLE_BOOTSTRAP_PATHS_FLIP_X}" = "YES" ]
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
# but is a bit faster than perfect_relative_path_between
# which uses simplify_path
#
relative_path_between()
{
   local  a
   local  b

   a="$1"
   b="$2"

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
   local depth
   local relative
   local name

   name="$1"

   depth=`path_depth "${name}"`
   if [ "${depth}" -gt 1 ]
   then
      relative=".."
      while [ "$depth" -gt 2 ]
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


absolutepath()
{
   local path

   path="$1"
   case "${path}" in
      /*)
         :
      ;;

      *)
         path="`pwd -P`/${path}"
      ;;
   esac

   simplify_path "${path}"
}


#
# this does relative_path_between perfectly
# but its much slower than relative_path_between
#
perfect_relative_path_between()
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
   local composedpath  # renamed this from path, fixes crazy bug on linux

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
# simplify path works on paths that may or may not exist
# it makes prettier relative or absolute paths
#
simplify_path()
{
   local path

   if [ "${MULLE_BOOTSTRAP_PATHS_FLIP_X}" = "YES" ]
   then
      set +x
   fi

   path="$1"

   local components
   local final_components
   local final_path

   if [ ! -z "${path}" ]
   then
      components="`echo "${path}" | tr '/' '\012' | sed -e 's|$|/|'`"
      final_components="`_simplify_components "${components}"`"
      final_path="`_path_from_components "${final_components}"`"
   fi

   if [ "${MULLE_BOOTSTRAP_PATHS_FLIP_X}" = "YES" ]
   then
      set -x
   fi

   echo "${final_path}"
}


#
# consider . .. ~ or absolute paths as unsafe
# anything starting with a $ is probably also bad
# this just catches some obvious problems, not all
#
assert_sane_subdir_path()
{
   local file

   file="`simplify_path "$1"`"

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

   file="`simplify_path "$1"`"

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


# ####################################################################
#                        Files and Directories
# ####################################################################
#
mkdir_if_missing()
{
   if [ ! -d "$1" ]
   then
      log_fluff "Creating \"$1\" (`pwd -P`)"
      exekutor mkdir -p "$1" || fail "failed to create directory \"$1\""
   fi
}


dir_is_empty()
{
   local empty

   if [ ! -d "$1" ]
   then
      return 2
   fi

   empty="`ls -A "$1" 2> /dev/null`"
   [ "$empty" = "" ]
}


rmdir_safer()
{
   if [ -d "$1" ]
   then
      assert_sane_path "$1"
      exekutor chmod -R u+w "$1" || fail "Failed to make $1 writable"
      exekutor rm -rf "$1" || fail "failed to remove $1"
   fi
}


rmdir_if_empty()
{
   if dir_is_empty "$1"
   then
      exekutor rmdir "$1" || fail "failed to remove $1"
   fi
}


create_file_if_missing()
{
   local dir

   if [ ! -f "$1" ]
   then
      dir="`dirname "$1"`"
      if [ ! -z "${dir}" ]
      then
         mkdir_if_missing "${dir}"
      fi

      log_fluff "Creating \"$1\" (`pwd -P`)"
      exekutor touch "$1" || fail "failed to create \"$1\""
   fi
}


remove_file_if_present()
{
   if [ -e "$1" ]
   then
      log_fluff "Removing \"$1\" (`pwd -P`)"
      exekutor chmod u+w "$1" || fail "Failed to make $1 writable"
      exekutor rm -f "$1" || fail "failed to remove \"$1\""
   fi
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
   local dirpath
   local flag

   dirpath="$1"
   shift

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
   [ "$empty" != "" ]
   result=$?

   if [ "$result" -eq 1 ]
   then
      log_fluff "Directory \"$dirpath\" has no files"
   else
      log_fluff "Directory \"$dirpath\" has files"
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


which_binary()
{
   local toolname

   toolname="$1"
   case "${UNAME}" in
      mingw)
         case "${toolname}" in
            *.exe)
            ;;

            *)
               toolname="${toolname}.exe"
            ;;
         esac
      ;;
   esac

   which "${toolname}" 2> /dev/null
}


has_usr_local_include()
{
   local name

   name="$1"
   if [ -d "/usr/local/include/${name}" ]
   then
      return 0
   fi

   local include_name

   include_name="`echo "${name}" | tr '-' '_'`"

   [ -d "/usr/local/include/${include_name}" ]
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

      log_info "Write-protecting ${C_RESET_BOLD}$1${C_INFO} to avoid spurious header edits"
      exekutor chmod -R a-w "$1"
   fi
}


# ####################################################################
#                               Init
# ####################################################################
functions_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh
   [ -z "${MULLE_BOOTSTRAP_ARRAY_SH}" ] && . mulle-bootstrap-array.sh

   log_fluff ":functions_initialize:"
}


functions_initialize
