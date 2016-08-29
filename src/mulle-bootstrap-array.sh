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

# declare "fail" outside
# array contents can contain any characters except newline

array_key_check()
{
    local n

    n=`echo "$1" | wc -l`
    [ $n -eq 0 ] && fail "empty key"
    [ $n -ne 1 ] && fail "key has linebreaks"

    echo "$1" | tr '>' '|'
}


array_value_check()
{
    local n

    n=`echo "$1" | wc -l`
    [ $n -eq 0 ] && fail "empty value"
    [ $n -ne 1 ] && fail "value has linebreaks"

    echo "$1"
}


array_add()
{
    local array
    local value

    array="${1}"
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

    local n

    n=`echo "${array}" | wc -l`
    echo ${n}
}


array_get()
{
    local array
    local i

    array="${1}"
    i="$2"

    local n

    n="`array_count "${array}"`"

    if [ ${i} -lt ${n} ]
    then
        fail "index ${i} out of bounds ${n}"
    fi

    echo "${array}" | head -${n} | tail -1
}


array_get_last()
{
    local array

    array="${1}"

    echo "${array}" | tail -1
}



array_remove()
{
    local array
    local value

    array="${1}"
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

    array="${1}"
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


_assoc_array_add()
{
    local array
    local key
    local value

    array="${1}"
    key="`array_key_check "$2"`"
    value="`array_value_check "$3"`"

    local value

    value="<${key}>${value}"
    if [ -z "${array}" ]
    then
        echo "${value}"
    else
        echo "${array}
${value}"
    fi
}


_assoc_array_remove()
{
    local array
    local key

    array="${1}"
    key="`array_key_check "$2"`"

    local line

    if [ ! -z "${array}" ]
    then
        echo "${array}" | fgrep -v "<${key}>"
    fi
}


assoc_array_get()
{
    local array
    local key

    array="${1}"
    key="`array_key_check "$2"`"

    echo "${array}" | fgrep "<${key}>" | sed -n 's/^<.*>\(.*\)$/\1/p'
}


assoc_array_get_last()
{
    local array

    array="${1}"

    echo "${array}" | tail -1 | sed -n 's/^<.*>\(.*\)$/\1/p'
}



assoc_array_set()
{
    local array
    local key
    local value
    local old_value

    array="${1}"
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
