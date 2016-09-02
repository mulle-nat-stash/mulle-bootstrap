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
MULLE_BOOTSTRAP_ARRAY_SH="included"

# declare "fail" outside
# array contents can contain any characters except newline

array_value_check()
{
   local n

   n=`echo "$1" | wc -l`
   [ $n -eq 0 ] && fail "empty value"
   [ $n -ne 1 ] && fail "value \"$1\" has linebreaks"

   echo "$1"
}


array_index_check()
{
   local array
   local i

   array="$1"
   i="$2"

   [ -z "${i}" ] && fail "empty index"

   local n
   n="`array_count "${array}"`"

   [ ${i} -ge ${n} ] && fail "index ${i} out of bounds ${n}"

   echo "${i}"
}


array_index_check()
{
   local array
   local i

   array="$1"
   i="$2"

   [ -z "${i}" ] && fail "empty index"

   local n
   n="`array_count "${array}"`"

   [ ${i} -ge ${n} ] && fail "index ${i} out of bounds ${n}"

   echo "${i}"
}



array_add()
{
   local array
   local value

   array="$1"
   value="`array_value_check "$2"`"

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
   local array

   array="$1"

   if [ -z "${array}" ]
   then
      echo 0
      return
   fi

   local n

   n=`echo "${array}" | wc -l`
   echo ${n}
}


array_get()
{
   local array
   local i

   array="$1"
   i="`array_index_check "${array}" "$2"`"
   i=`expr $i + 1`

   echo "${array}" | head -${i} | tail -1
}


array_insert()
{
   local array
   local value
   local i

   array="$1"
   i="$2"
   value="`array_value_check "$3"`"

   local head_count
   local tail_count
   local n

   [ "${i}" = "" ] && fail "empty index"

   n=`array_count "${array}"`
   [ ${i} -gt ${n} ] && fail "index ${i} out of bounds ${n}"

   head_count=$i
   tail_count=`expr $n - $i`

   if [ ${head_count} -ne 0 ]
   then
      echo "${array}" | head -${head_count}
   fi

   echo "${value}"

   if [ ${tail_count} -ne 0 ]
   then
      echo "${array}" | tail -${tail_count}
   fi
}


array_get_last()
{
   local array

   array="$1"

   echo "${array}" | tail -1
}


array_remove()
{
   local array
   local value

   array="$1"
   value="`array_value_check "$2"`"

   if [ ! -z "${array}" ]
   then
       echo "${array}" | fgrep -v -x "${value}"
   fi
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
   [ $n -eq 0 ] && fail "empty value"
   [ $n -ne 1 ] && fail "key \"$1\" has spaces"

   #
   # escape charactes
   # keys can't contain grep characters or '=''
   #
   echo "$1" | sed -e 's/[][\\.*^$=]/_/g'
}


_assoc_array_add()
{
   local array
   local key
   local value

   array="$1"
   key="`_assoc_array_key_check "$2"`"
   value="`array_value_check "$3"`"

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
   local array
   local key

   array="$1"

   if [ ! -z "${array}" ]
   then
       key="`_assoc_array_key_check "$2"`"
       echo "${array}" | grep -v "^${key}="
   fi
}


assoc_array_get()
{
   local array
   local key

   array="$1"
   key="`_assoc_array_key_check "$2"`"

   echo "${array}" | grep "^${key}=" | sed -n 's/^[^=]*=\(.*\)$/\1/p'
}


assoc_array_get_last()
{
   local array

   array="$1"

   echo "${array}" | tail -1 | sed -n 's/^[^=]*=\(.*\)$/\1/p'
}


assoc_array_set()
{
   local array
   local key
   local value
   local old_value

   array="$1"
   key="${2}"
   value="${3}"

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
assoc_array_merge_array()
{
   local array1
   local array2

   array="$1"
   array="$2"

   echo "${array2}" "${array1}" | sort -u -t'=' -k1,1
}

#
# add second array into first array
# meaning only keys in second array that don't exists in the
# first are added
#
assoc_array_add_array()
{
   local array1
   local array2

   array="$1"
   array="$2"

   echo "${array1}" "${array2}" | sort -u -t'=' -k1,1
}





