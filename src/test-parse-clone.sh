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

   parse_clone "url/name;stashdir;branch;scm;tag"

   [ "${url}"      = "url/name" ]  || fail "wrong name \"${url}\""
   [ "${name}"     = "name" ]      || fail "wrong name \"${name}\""
   [ "${stashdir}" = "stashdir" ]  || fail "wrong stashdir \"${stashdir}\""
   [ "${branch}"   = "branch" ]    || fail "wrong branch \"${branch}\""
   [ "${tag}"      = "tag" ]       || fail "wrong tag \"${tag}\""
   [ "${scm}"      = "scm" ]       || fail "wrong scm \"${scm}\""
}

run_test_2()
{
   local name
   local url
   local branch
   local scm
   local tag
   local stashdir

   parse_clone "url/name;;;;"

   [ "${url}"      = "url/name" ]  || fail "wrong name \"${url}\""
   [ "${name}"     = "name" ]      || fail "wrong name \"${name}\""
   [ "${stashdir}" = "stashes/name" ]  || fail "wrong stashdir \"${stashdir}\""
   [ "${branch}"   = "" ]       || fail "wrong branch \"${branch}\""
   [ "${tag}"      = "" ]       || fail "wrong tag \"${tag}\""
   [ "${scm}"      = "" ]       || fail "wrong scm \"${scm}\""
}

run_test_3()
{
   local name
   local url
   local branch
   local scm
   local tag
   local stashdir

   echo "The next test should fail" >&2
   parse_clone "url/name;../foo;;;" || exit 1
   echo "If you see this the test is broken" >&2
}

run_test_1
run_test_2
run_test_3

echo "test finished" >&2

