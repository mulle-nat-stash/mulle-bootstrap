#! /bin/sh

clear_test_dirs()
{
   local i

   for i in "$@"
   do
      if [ -d "$i" ]
      then
         rm -rf "$i"
      fi
   done
}


fail()
{
   echo "failed" "$@" >&2
   exit 1
}


run_mulle_bootstrap()
{
   echo "####################################" >&2
   echo mulle-bootstrap "$@"  >&2
   echo "####################################" >&2

   mulle-bootstrap "$@" || fail "mulle-bootstrap failed"
}


#
#
#
setup_test_dirs()
{
   mkdir -p a/.bootstrap
   mkdir -p b/.bootstrap
   mkdir -p c/.bootstrap
   mkdir -p d/.bootstrap
   mkdir -p e
}


setup_test_case1()
{
   echo "b
e" > a/.bootstrap/repositories

   echo "d
c" > b/.bootstrap/repositories

   echo "d" > c/.bootstrap/repositories
   echo "e" > d/.bootstrap/repositories
}


setup_test_case2()
{
   echo "b
e" > a/.bootstrap/repositories

   echo "d
c" > b/.bootstrap/repositories

   rm c/.bootstrap/repositories 2> /dev/null
   rm d/.bootstrap/repositories 2> /dev/null
}


clear_test_dirs()
{
   local i

   for i in "$@"
   do
      if [ -d "$i" ]
      then
         rm -rf "$i"
      fi
   done
}


test()
{
   local expect="$1"

   run_mulle_bootstrap ${BOOTSTRAP_FLAGS} -y -f fetch || exit 1

   local result

   result="`cat .bootstrap.auto/repositories`"
   if [ "${expect}" != "${result}" ]
   then
      fail "got \"${result}\", expected \"${expect}\"" >&2
   fi
}


BOOTSTRAP_FLAGS="$@"

MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH

#
# not that much of a test
#
clear_test_dirs a b c d e
setup_test_dirs
(
   setup_test_case1 &&
   cd a &&
   test "e;stashes/e;master;git
d;stashes/d;master;git
c;stashes/c;master;git
b;stashes/b;master;git"
) || exit 1

(
   setup_test_case2 &&
   cd a &&
   test "d;stashes/d;master;git
c;stashes/c;master;git
b;stashes/b;master;git
e;stashes/e;master;git"
) || exit 1
clear_test_dirs a b c d e

echo "succeeded" >&2
