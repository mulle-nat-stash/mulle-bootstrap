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
   mkdir -p a/x
   mkdir -p b/.bootstrap
   mkdir -p b/y
   mkdir -p c/z
}


setup_test_case()
{
   echo "b" > a/.bootstrap/repositories
   echo "c" > b/.bootstrap/repositories
}



test()
{
   cd a || exit 1

   run_mulle_bootstrap "$@" -y -f fetch || exit 1

   local result
   local expect

   result="`cat .bootstrap.auto/repositories`"
   expect="c;stashes/c;master;git
b;stashes/b;master;git"
   if [ "${expect}" != "${result}" ]
   then
      fail ": ($result)"
   else
      echo "succeeded" >&2
   fi

   [ -d stashes/b/y ] || fail "stashes/b/y missing"
   [ -d stashes/c/z ] || fail "stashes/c/z missing"

   :
}


BOOTSTRAP_FLAGS="$@"

#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH

clear_test_dirs a b c
setup_test_dirs
(
   setup_test_case ;
   test "$@"
) || exit 1
clear_test_dirs a b c

echo "succeeded" >&2

