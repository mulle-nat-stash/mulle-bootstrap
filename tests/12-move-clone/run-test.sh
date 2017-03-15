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
   echo "failed:" "$@" >&2
   exit 1
}


run_mulle_bootstrap()
{
   echo "####################################" >&2
   echo mulle-bootstrap "$@"  >&2
   echo "####################################" >&2

   mulle-bootstrap "$@"  || fail "mulle-bootstrap failed"
}


#
#
#

setup_test_case()
{
   clear_test_dirs a b

   mkdir -p a/.bootstrap
   mkdir -p b

   (
      cd b ;
      git init ;
      echo "# VfL Bochum 1848" > README.md ;
      git add README.md ;
      git commit -m "bla bla"
   ) || exit 1

   echo "b" > a/.bootstrap/repositories
}



move_test_case()
{
   echo "b;b2" > a/.bootstrap/repositories
}


assert_a_1()
{
   result="`cat stashes/b/README.md`"
   [ "${result}" != "# VfL Bochum 1848" ] && fail "stashes not created ($result)"
   :
}


assert_a_2()
{
   result="`cat .bootstrap.auto/repositories`"
   [ "b;b2;master;git" != "${result}" ] &&  fail ".bootstrap.auto/repositories ($result)"

   [ ! -e "b2" ] && fail "stashes not created ($result)"

   result="`head -1 .bootstrap.repos/b`"
   [ "b;b2;master;git" != "${result}" ] && fail "($result)"

   result="`cat b2/README.md`"
   [ "${result}" != "# VfL Bochum 1848" ] && fail "stashes not created ($result)"
   :
}


_test_a_1()
{
   run_mulle_bootstrap "$@" -y fetch  --no-symlink-creation
   assert_a_1
}


_test_a_2()
{
   run_mulle_bootstrap "$@" -y fetch  --no-symlink-creation
   assert_a_2
}


test_a()
{
   (
      cd a ;
      _test_a_1 "$@"
   ) || exit 1

   #
   #  move b to b2
   #
   move_test_case

   (
      cd a ;
      _test_a_2 "$@"
   ) || exit 1
}


#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH

setup_test_case
test_a "$@"
clear_test_dirs a b

echo "succeeded" >&2

