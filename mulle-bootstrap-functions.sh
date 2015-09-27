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
# some common functions
#
fail()
{
   echo "\033[0;31m$*\033[0m" >&2
   exit 1
}


internal_fail()
{
   fail "**** mulle-bootstrap internal error ****
" "$@"
}


is_yes()
{
   local s

   s="`echo \"${1}\" | tr '[:lower:]' '[:upper:]'`"
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
   echo $depth
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


user_say_yes()
{
  local  x

  x="nix"
  while [ "$x" != "y" -a "$x" != "n" -a "$x" != "" ]
  do
     echo "$@" "(y/N)" >&2
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

   binary="`which brew`"
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
         ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 1
      else
         ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" || exit 1
      fi

      mkdir -p "`dirname \"${last_update}\"`" 2> /dev/null
      touch "${last_update}"
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


warn_user_setting()
{
   local name

   name="$1"
   if [ "${DONT_WARN_RECURSION}" = "" -a "`DONT_WARN_RECURSION=YES read_local_setting \"dont_warn_user_setting\"`" = "" ]
   then
      echo "Using ~/.mulle-bootstrap/${name}" >& 2
   fi
}


#
# this knows intentionally no default, you cant have an empty
# local setting
#
_read_local_setting()
{
   local name
   local value
   local envname

   name="$1"

   [ "$name" = "" ] && internal_fail "missing parameters in _read_local_setting"

   envname=`echo "${name}" | tr '[:lower:]' '[:upper:]'`
   value=`printenv "MULLE_BOOTSTRAP_${envname}"`

   if [ "${value}" != "" ]
   then
      echo "${value}"
      return 1
   else
      value=`egrep -v '^#|^[ ]*$' "${BOOTSTRAP_SUBDIR}.local/${name}" 2> /dev/null`
      if [ $? -gt 1 ]
      then
         value=`egrep -v '^#|^[ ]*$' "${HOME}/.mulle-bootstrap/${name}" 2> /dev/null`
         if [ "$value" != "" ]
         then
             warn_user_setting "${name}"
         fi
      else
         warn_local_setting "${name}"
      fi
   fi

   echo "${value}"
}


read_local_setting()
{
   local name
   local value
   local default

   name="$1"
   default="$2"

   value=`_read_local_setting "$name"`
   if [ "${value}" = "" ]
   then
      value="${default}"
   fi

   echo "$value"

   [ "${value}" = "${default}" ]
   return $?
}


read_sane_local_path_setting()
{
   local name
   local value
   local default

   name="$1"
   default="$2"

   value=`_read_local_setting "${name}"`
   if [ "$?" -ne 0 ]
   then
      case "${value}"  in
         \$*|~/.|..|./|../|/*)
            echo "refuse unsafe path ${value} for ${name}" >&2
            exit 1
         ;;
      esac
   else
      if [ "$value" = "" ]
      then
         value="${default}"
      fi
   fi

   echo "$value"

   [ "${value}" = "${default}" ]
   return $?
}


warn_local_setting()
{
   local name

   name="$1"
   if [ "${DONT_WARN_RECURSION}" = "" -a "`DONT_WARN_RECURSION=YES read_local_setting \"dont_warn_local_setting\"`" = "" ]
   then
      echo "Using ${BOOTSTRAP_SUBDIR}.local/${name}" >& 2
   fi
}


# "auto" after base
read_repo_setting()
{
   local name
   local value
   local default

   package="$1"
   name="$2"
   default="$3"

   [ "$name" = "" -o "$package" = "" ] && internal_fail "missing parameters in read_repo_setting"

   value=`egrep -v '^#|^[ ]*$' "${BOOTSTRAP_SUBDIR}.local/settings/${package}/${name}" 2> /dev/null`
   if [ $? -gt 1 ]
   then
      value=`egrep -v '^#|^[ ]*$' "${BOOTSTRAP_SUBDIR}/settings/${package}/${name}" 2> /dev/null`
      if [ $? -gt 1 ]
      then
         value=`egrep -v '^#|^[ ]*$' "${BOOTSTRAP_SUBDIR}.auto/settings/${package}/${name}" 2> /dev/null`
         if [ $? -gt 1 ]
         then
            if [ $# -eq 2 ]
            then
               return 2
            fi

            value="${default}"
         fi
      fi
   else
      warn_local_setting "${name}"
   fi
   echo "$value"

   [ "${value}" = "${default}" ]
   return $?
}


#
# this has to be flexible, because fetch and build settings read differently
#
_read_bootstrap_setting()
{
   local name
   local value
   local default
   local suffix1
   local suffix2
   local suffix3

   name="$1"
   suffix1="$2"
   suffix2="$3"
   suffix3="$4"
   default="$5"

   [ "$name" = "" ] && internal_fail "missing parameters in _read_bootstrap_setting"

   value=`egrep -v '^#|^[ ]*$' "${BOOTSTRAP_SUBDIR}${suffix1}/${name}" 2> /dev/null`
   if [ $? -gt 1 ]
   then
      value=`egrep -v '^#|^[ ]*$' "${BOOTSTRAP_SUBDIR}${suffix2}/${name}" 2> /dev/null`
      if [ $? -gt 1 ]
      then
         value=`egrep -v '^#|^[ ]*$' "${BOOTSTRAP_SUBDIR}${suffix3}/${name}" 2> /dev/null`
         if [ $? -gt 1 ]
         then
            if [ $# -eq 1 ]
            then
               return 2
            fi
            value="${default}"
         else
            [ "$suffix1" = ".local" ] && warn_local_setting "${name}"
         fi
      else
         [ "$suffix1" = ".local" ] && warn_local_setting "${name}"
      fi
   else
      [ "$suffix1" = ".local" ] && warn_local_setting "${name}"
   fi

   echo "$value"

   [ "${value}" = "${default}" ]
   return $?
}

#
# the default
#
_read_build_setting()
{
   _read_bootstrap_setting "$1" ".local" "" ".auto" "$2"
}



read_build_setting()
{
   local name
   local value
   local default

   package="$1"
   name="$2"
   default="$3"

   [ "$name" = "" -o "$package" = "" ] && internal_fail "missing parameters in read_build_setting"

   value=`read_repo_setting "${package}" "${name}"`
   if [ $? -gt 1 ]
   then
      if [ $# -eq 2 ]
      then
          value=`_read_build_setting "${name}"`
      else
          value=`_read_build_setting "${name}" "${default}"`
      fi

      if [ $? -gt 1 ]
      then
         return 2
      fi
   fi
   echo "$value"

   [ "${value}" = "${default}" ]
   return $?
}


read_build_root_setting()
{
   _read_bootstrap_setting "$1" ".local" "" ".auto" "$2"
}


read_fetch_setting()
{
   _read_bootstrap_setting "$1" ".auto" ".local" "" "$2"
}


read_yes_no_build_setting()
{
   local value

   value="`read_build_setting \"$1\" \"$2\" \"$3\"`"
   is_yes "$value" "$1/$2"
}


all_build_flag_keys()
{
   local keys1
   local keys2
   local keys3
   local keys4
   local keys5
   local keys6
   local package

   package="$1"

   [ "$package" = "" ] && fail "script error"

   keys1=`(cd "${BOOTSTRAP_SUBDIR}.local/settings/${package}" 2> /dev/null || exit 1; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys2=`(cd "${BOOTSTRAP_SUBDIR}/settings/${package}" 2> /dev/null || exit 1 ; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys3=`(cd "${BOOTSTRAP_SUBDIR}.auto/settings/${package}" 2> /dev/null || exit 1 ; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys4=`(cd "${BOOTSTRAP_SUBDIR}.local" 2> /dev/null || exit 1 ; \
           ls -1 | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys5=`(cd "${BOOTSTRAP_SUBDIR}"  2> /dev/null || exit 1 ; \
           ls -1  | egrep '\b[A-Z][A-Z_0-9]+\b')`
   keys6=`(cd "${BOOTSTRAP_SUBDIR}.auto"  2> /dev/null || exit 1 ; \
           ls -1  | egrep '\b[A-Z][A-Z_0-9]+\b')`

   echo "${keys1}
${keys2}
${keys3}
${keys4}
${keys5}
${keys6}" | sort | sort -u | egrep -v '^[ ]*$'
   return 0
}


