#! /usr/bin/env bash

set -e
set -x

. mulle-bootstrap-dependency-resolve.sh
. mulle-bootstrap-functions.sh


fail()
{
   echo "failed:" "$@" "(got \"${result}\", expected \"${expect}\")" >&2
   exit 1
}


test_array()
{
    local array

    array="`array_insert "${array}" 0 "VfL"`"
    array="`array_insert "${array}" 1 "1848"`"
    array="`array_insert "${array}" 1 "Bochum"`"

    expect="VfL
Bochum
1848"
    [ "${array}" != "${expect}" ] && fail "test_array #1"

    array="`array_remove "${array}" "Bochum"`"

    expect="VfL
1848"
    [  "${array}" != "${expect}" ] && fail "test_array #2"

    :
}


test_assoc_array()
{
   local array

   array="`assoc_array_set "${array}" "1"  "Riemann"`"
   array="`assoc_array_set "${array}" "21" "Celozzi"`"
   array="`assoc_array_set "${array}" "2"  "Hoogland"`"
   array="`assoc_array_set "${array}" "5"  "Bastians"`"
   array="`assoc_array_set "${array}" "24" "Perthel"`"
   array="`assoc_array_set "${array}" "8"  "Losilla"`"
   array="`assoc_array_set "${array}" "39" "Steipermann"`"
   array="`assoc_array_set "${array}" "23" "Weilandt"`"
   array="`assoc_array_set "${array}" "10" "Eisfeld"`"
   array="`assoc_array_set "${array}" "22" "Stoeger"`"
   array="`assoc_array_set "${array}" "9"  "Wurtz"`"

   local result
   local expect

   result="`assoc_array_get "${array}" "10"`"
   expect="Eisfeld"
   [  "${result}" != "${expect}" ] && fail "test_assoc_array #1 "

   array="`assoc_array_set "${array}" "10"`"
   result="`assoc_array_get "${array}" "10"`"
   expect=""
   [  "${result}" != "${expect}" ] && fail "test_assoc_array #2"

   result="`assoc_array_get "${array}" "39"`"
   expect="Steipermann"
   [  "${result}" != "${expect}" ] && fail "test_assoc_array #3"

   array="`assoc_array_set "${array}" "39" "Stiepermann"`"
   result="`assoc_array_get "${array}" "39"`"
   expect="Stiepermann"
   [  "${result}" != "${expect}" ] && fail "test_assoc_array #4"

   :
}


test_dependencies()
{
   local map

   map="`dependency_add "${map}" "c" "d"`"
   map="`dependency_add "${map}" "a" "e"`"
   map="`dependency_add "${map}" "b" "c"`"
   map="`dependency_add "${map}" "a" "b"`"
   map="`dependency_add "${map}" "b" "d"`"
   map="`dependency_add "${map}" "d" "e"`"

   result="`dependency_resolve "${map}" "a"`"
   expect="e
d
c
b
a"
   [  "${result}" != "${expect}" ] && fail "test_dependencies #1"

   :
}


test_array
test_assoc_array
test_dependencies

echo "test finished" >&2
