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
setup_test_case()
{
   mkdir -p a/.bootstrap
   mkdir -p b
   echo "b" > a/.bootstrap/repositories
}


assert_a()
{
   result="`cat .bootstrap.auto/repositories`"
   expected="b;stashes/b;master;git"

   [ "${expected}" = "${result}" ] || fail ".bootstrap.auto/repositories: ${result} != ${expected}"
   [ ! -e "stashes/b" ] && fail "stashes not created ($result)"

   result="`cat .bootstrap.repos/b`"
   expected="b;stashes/b;master;symlink"
   [ "${expected}" = "${result}" ] || fail ".bootstrap.repos/b: ${result} != ${expected}"
   :

   [ -L "stashes/b" ] || fail "not a symlink"
}


test_a()
{
   cd a || exit 1

   run_mulle_bootstrap "$@" -y -f fetch
   assert_a

   #
   # lets do it  again, should not change anything
   #
   run_mulle_bootstrap "$@" -y -f fetch
   assert_a

   #
   # lets update, should not change anything
   #
   run_mulle_bootstrap "$@" update
   assert_a

   #
   # lets upgrade, should not change anything
   #

   run_mulle_bootstrap "$@" upgrade
   assert_a
}


#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH

clear_test_dirs a b
setup_test_case
test_a "$@"
clear_test_dirs a b

echo "succeeded" >&2
