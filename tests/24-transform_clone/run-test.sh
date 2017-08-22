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



transform_test_case_1()
{
   mv a/.bootstrap/repositories a/.bootstrap/embedded_repositories
}


transform_test_case_2()
{
   mv a/.bootstrap/embedded_repositories a/.bootstrap/repositories
}


assert_a_1()
{
   [ -e ".bootstrap.auto/embedded_repositories" ] && fail "auto embedded_repositories not deleted"

   [ -e ".bootstrap.repos/.embedded/b" ] && fail ".bootstrap.repos/.embedded/b not deleted"

   result="`cat .bootstrap.auto/repositories`"
   [ "b;stashes/b;master;git" != "${result}" ] &&  fail ".bootstrap.auto/repositories ($result)"

   [ ! -e "stashes/b" ] && fail "stashes not created"

   result="`head -1 .bootstrap.repos/b`"
   [ "b;stashes/b;master;git" != "${result}" ] && fail "($result)"

   result="`cat stashes/b/README.md`"
   [ "${result}" != "# VfL Bochum 1848" ] && fail "stashes/b/README.md not created ($result)"
   :
}


assert_a_2()
{
   [ -e "stashes/b" ] && fail "stashes not deleted"

   [ -e ".bootstrap.auto/repositories" ] && fail "auto repositories not deleted"

   result="`cat .bootstrap.auto/embedded_repositories`"
   [ "b;b;master;git" != "${result}" ] &&  fail ".bootstrap.auto/embedded_repositories ($result)"

   [ ! -e "b" ] && fail "b not created ($result)"

   result="`head -1 .bootstrap.repos/.embedded/b`"
   [ "b;b;master;git" != "${result}" ] && fail "($result)"

   result="`cat b/README.md`"
   [ "${result}" != "# VfL Bochum 1848" ] && fail "stashes not created ($result)"
   :
}


assert_a_3()
{
   assert_a_1
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


_test_a_3()
{
   run_mulle_bootstrap "$@" -y fetch  --no-symlink-creation
   assert_a_3
}



test_a()
{
   (
      cd a ;
      _test_a_1 "$@"
   ) || exit 1

   #
   #  move b to embedded
   #
   transform_test_case_1

   (
      cd a ;
      _test_a_2 "$@"
   ) || exit 1

   #
   #  move b back
   #
   transform_test_case_2

   (
      cd a ;
      _test_a_3 "$@"
   ) || exit 1
}


#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH

setup_test_case &&
test_a "$@" &&
echo "succeeded" >&2 &&
clear_test_dirs a b


