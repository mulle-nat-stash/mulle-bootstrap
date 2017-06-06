#! /usr/bin/env bash
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
MULLE_BOOTSTRAP_ARRAY_SH="included"

# declare "fail" outside
# array contents can contain any characters except newline
array_value_check()
{
   local value="$1"

   local n

   n=`echo "${value}" | wc -l  | awk '{ print $1}'`

   [ "$n" -eq 0 ] && internal_fail "empty value"
   [ "$n" -ne 1 ] && internal_fail "value \"${value}\" has linebreaks"

   echo "${value}"
}


array_index_check()
{
   local array="$1"
   local i="$2"

   [ -z "$i" ] && internal_fail "empty index"

   local n

   n=`array_count "${array}"`

   [ "$i" -ge "$n" ] && internal_fail "index ${i} out of bounds ${n}"

   echo "${i}"
}


array_add()
{
   local array="$1"
   local value="$2"

# DEBUG code
#   value="`array_value_check "${value}"`"

   if [ -z "${array}" ]
   then
       echo "${value}"
   else
       echo "${array}
${value}"
   fi
}


array_count()
{
   local array="$1"

   if [ -z "${array}" ]
   then
      echo 0
      return
   fi

   echo "${array}" | wc -l | awk '{ print $1 }'
}


array_get()
{
   local array="$1"
   local i="$2"

# DEBUG code
#   n="`array_count "${array}"`"
#   [ "$i" -ge "$n" ] && internal_fail "index ${i} out of bounds ${n}"

   ((i++))
   sed -n "${i}p" <<< "${array}"
}


array_get_last()
{
   local array="$1"

   tail -1 <<< "${array}"
}


array_insert()
{
   local array="$1"
   local i="$2"
   local value="$3"

   value="`array_value_check "${value}"`"

   local head_count
   local tail_count

# DEBUG code
#   [ -z "${i}" ] && internal_fail "empty index"
#
   local n
#
   n="`array_count "${array}"`"
#   [ "$i" -gt "$n" ] && internal_fail "index ${i} out of bounds ${n}"

   head_count="$i"
   tail_count="$((n-$i))"

   if [ "${head_count}" -ne 0 ]
   then
      head "-${head_count}" <<< "${array}"
   fi

   echo "${value}"

   if [ "${tail_count}" -ne 0 ]
   then
      tail "-${tail_count}" <<< "${array}"
   fi
}


array_remove()
{
   local array="$1"
   local value="$2"

# DEBUG code
#   value="`array_value_check "${value}"`"

   if [ ! -z "${array}" ]
   then
       fgrep -v -x "${value}" <<< "${array}"
   fi
}


array_remove_last()
{
   local array="$1"

   local n

   n=`array_count "${array}"`
   case $n in
      0)
         fail "remove from empty array"
      ;;

      1)
         return
      ;;

      *)
         n="$((n-1))"
      ;;
   esac

   echo "${array}" | head "-$n"
}


array_contains()
{
   local array
   local value

   array="$1"
   value="`array_value_check "$2"`"

   local found

   found="`echo "${array}" | fgrep -x "${value}"`"
   [ ! -z "${found}" ]
}


#
# declare "fail" outside
# assoc array contents can contain any characters except newline
# assoc array keys can contain any characters except newline
# but be careful, that > chars are translated to |, so
# get 'a|' and get 'a>' match
#
#
# currently escaping is provided for code "outside" of array, but it really
# should be done within the functions (slow though)
#
_assoc_array_key_check()
{
   local n

   n=`echo "$1" | wc -w`
   [ "$n" -eq 0 ] && internal_fail "empty value"
   [ "$n" -ne 1 ] && internal_fail "key \"$1\" has spaces"

   #
   # escape charactes
   # keys can't contain grep characters or '=''
   #
   echo "$1" | sed -e 's/[][\\.*^$=]/_/g'
}


_assoc_array_add()
{
   local array="$1"
   local key="$2"
   local value="$3"

# DEBUG code
#   key="`_assoc_array_key_check "$2"`"
#   value="`array_value_check "$3"`"

   local line

   line="${key}=${value}"
   if [ -z "${array}" ]
   then
       echo "${line}"
   else
       echo "${array}
${line}"
   fi
}


_assoc_array_remove()
{
   local array="$1"
   local key="$2"

   if [ ! -z "${array}" ]
   then
# DEBUG code
#       key="`_assoc_array_key_check "${key}"`"
      grep -v "^${key}=" <<< "${array}"
   fi
}


assoc_array_get()
{
   local array="$1"
   local key="$2"

# DEBUG code
#   key="`_assoc_array_key_check "${key}"`"

   grep "^${key}=" <<< "${array}" \
      | sed -n 's/^[^=]*=\(.*\)$/\1/p'
}


assoc_array_get_last()
{
   local array="$1"

   tail -1 <<< "${array}" \
      | sed -n 's/^[^=]*=\(.*\)$/\1/p'
}


assoc_array_all_keys()
{
   local array="$1"

   sed -n 's/^\([^=]*\)=.*$/\1/p' <<< "${array}"
}


assoc_array_all_values()
{
   local array="$1"

   sed -n 's/^[^=]*=\(.*\)$/\1/p' <<< "${array}"
}


assoc_array_set()
{
   local array="$1"
   local key="$2"
   local value="$3"

   if [ -z "${value}" ]
   then
      _assoc_array_remove "${array}" "${key}"
      return
   fi

   local old_value

   old_value="`assoc_array_get "${array}" "${key}"`"
   if [ ! -z "${old_value}" ]
   then
      array="`_assoc_array_remove "${array}" "${key}"`"
   fi

   _assoc_array_add "${array}" "${key}" "${value}"
}


#
# merge second array into first array
# meaning if key in second array exists it overwrites
# the value in the first array
#
assoc_array_merge_with_array()
{
   local array1="$1"
   local array2="$2"

   echo "${array2}" "${array1}" | sort -u -t'=' -k1,1
}


#
# add second array into first array
# meaning only keys in second array that don't exists in the
# first are added
#
assoc_array_augment_with_array()
{
   local array1="$1"
   local array2="$2"

   echo "${array1}" "${array2}" | sort -u -t'=' -k1,1
}

