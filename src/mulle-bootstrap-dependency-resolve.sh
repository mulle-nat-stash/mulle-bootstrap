#! /bin/sh
#
#   Copyright (c) 2016 Nat! - Mulle kybernetiK
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
#

. mulle-bootstrap-array.sh


escape_array()
{
   local text

   text="`echo "$@" | sed -e 's/|/\\|/g'`"
   /bin/echo -n "${text}" | tr '\012' '|'
}


unescape_array()
{
   echo "$@" | tr '|' '\012' | sed -e 's/\\$/|/g' -e '/^$/d'
}


_dependency_resolve()
{
   local map
   local name

   map="${1}"
   name="${2}"

   local escaped_dependencies
   local dependencies

   escaped_dependencies="`assoc_array_get "${map}" "${name}"`"
   dependencies="`unescape_array "${escaped_dependencies}"`"

   UNRESOLVED_DEPENDENCIES="`array_add "${UNRESOLVED_DEPENDENCIES}" "${name}"`"

   local sub_name
   local old

   old="${IFS}"
   IFS="
"
   for sub_name in ${dependencies}
   do
      IFS="${old}"

      if array_contains "${RESOLVED_DEPENDENCIES}" "${sub_name}"
      then
         continue
      fi

      if array_contains "${UNRESOLVED_DEPENDENCIES}" "${sub_name}"
      then
         fail "circular dependency ${sub_name} and ${name}"
      fi

      _dependency_resolve "${map}" "${sub_name}"
   done
   IFS="${old}"

   UNRESOLVED_DEPENDENCIES="`array_remove "${UNRESOLVED_DEPENDENCIES}" "${name}"`"
   RESOLVED_DEPENDENCIES="`array_add "${RESOLVED_DEPENDENCIES}" "${name}"`"
}


dependency_add()
{
   local map

   map="$1"

   local name
   local sub_name

   name="$2"
   sub_name="$3"

   local escaped_dependencies
   local dependencies

   escaped_dependencies="`assoc_array_get "${map}" "${name}"`"
   dependencies="`unescape_array "${escaped_dependencies}"`"

   if array_contains "${dependencies}" "${sub_name}"
   then
      if [ ! -z "${map}" ]
      then
         echo "${map}"
      fi
      return
   fi

   dependencies="`array_add "${dependencies}" "${sub_name}"`"
   escaped_dependencies="`escape_array "${dependencies}"`"

   assoc_array_set "${map}" "${name}" "${escaped_dependencies}"
}


dependency_resolve()
{
   local map
   local name

   map="$1"
   name="$2"

   RESOLVED_DEPENDENCIES=
   UNRESOLVED_DEPENDENCIES=

   _dependency_resolve "${map}" "${name}"

   local rval

   rval=1
   if [ -z "${UNRESOLVED_DEPENDENCIES}" ]
   then
      echo "${RESOLVED_DEPENDENCIES}"
      rval=0
   fi

   RESOLVED_DEPENDENCIES=
   UNRESOLVED_DEPENDENCIES=

   return $rval
}


