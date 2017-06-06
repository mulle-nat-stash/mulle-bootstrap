#! /bin/sh -e

. mulle-bootstrap-repositories.sh


run_test_1()
{
   local name
   local url
   local branch
   local scm
   local tag
   local stashdir

   local clone

   clone="url/name;stashdir;branch;scm;tag"
   parse_clone "${clone}"

   [ "${url}"      = "url/name" ]  || fail "wrong name \"${url}\""
   [ "${name}"     = "name" ]      || fail "wrong name \"${name}\""
   [ "${stashdir}" = "stashdir" ]  || fail "wrong stashdir \"${stashdir}\""
   [ "${branch}"   = "branch" ]    || fail "wrong branch \"${branch}\""
   [ "${tag}"      = "tag" ]       || fail "wrong tag \"${tag}\""
   [ "${scm}"      = "scm" ]       || fail "wrong scm \"${scm}\""

   remember_stash_of_repository "${clone}" \
                                ".bootstrap.repos" \
                                "${name}"  \
                                "${stashdir}"

   local foodir

   foodir="`stash_of_repository ".bootstrap.repos" "${name}"`"

   [ "${foodir}" = "${stashdir}" ] || fail "failed to remember stashdir"

   local fclone

   fclone="`clone_of_repository ".bootstrap.repos" "${name}"`"

   [ "${fclone}" = "${clone}" ] || fail "failed to remember clone"
}


run_test_2()
{
   local name
   local url
   local branch
   local scm
   local tag
   local stashdir

   local clone

   clone="a/b/c/name;d/e/f/g;branch;scm;tag"
   parse_clone "${clone}"

   [ "${url}"      = "a/b/c/name" ]  || fail "wrong name \"${url}\""
   [ "${name}"     = "name" ]      || fail "wrong name \"${name}\""
   [ "${stashdir}" = "d/e/f/g" ]   || fail "wrong stashdir \"${stashdir}\""
   [ "${branch}"   = "branch" ]    || fail "wrong branch \"${branch}\""
   [ "${tag}"      = "tag" ]       || fail "wrong tag \"${tag}\""
   [ "${scm}"      = "scm" ]       || fail "wrong scm \"${scm}\""

   remember_stash_of_repository "${clone}" \
                                ".bootstrap.repos/.embedded" \
                                "${name}"  \
                                "${stashdir}"

   local foodir

   foodir="`stash_of_repository ".bootstrap.repos/.embedded" "${name}"`"

   [ "${foodir}" = "${stashdir}" ] || fail "failed to remember stashdir"

   local fclone

   fclone="`clone_of_repository ".bootstrap.repos/.embedded" "${name}"`"

   [ "${fclone}" = "${clone}" ] || fail "failed to remember clone"
}

ROOT_DIR="`pwd`"

rm -rf .bootstrap.repos
run_test_1
run_test_2
rm -rf .bootstrap.repos

echo "test finished" >&2

