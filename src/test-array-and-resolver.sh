#! /bin/sh

. mulle-bootstrap-dependency-resolve.sh
. mulle-bootstrap-functions.sh



test_array()
{
    local array

    array="`array_insert "${array}" 0 "VfL"`"
    array="`array_insert "${array}" 1 "1848"`"
    array="`array_insert "${array}" 1 "Bochum"`"
    echo "${array}"

    array="`array_remove "${array}" "Bochum"`"
    echo "${array}"
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

    echo "pre remove: " `assoc_array_get "${array}" "10"`
    array="`assoc_array_set "${array}" "10"`"
    echo "post remove: " `assoc_array_get "${array}" "10"`

    echo "pre set: " `assoc_array_get "${array}" "39"`
    array="`assoc_array_set "${array}" "39" "Stiepermann"`"
    echo "post remove: " `assoc_array_get "${array}" "39"`
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

   dependency_resolve "${map}" "a"
}

test_array
test_assoc_array
test_dependencies
