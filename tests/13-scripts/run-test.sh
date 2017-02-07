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

   mulle-bootstrap "$@" || fail "mulle-bootstrap failed"
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
      echo "VfL Bochum 1848" > README.md ;
      git add README.md ;
      git commit -m "bla bla"
   ) || exit 1

   echo "b" > a/.bootstrap/repositories
}


update_test_case()
{
   (
      cd b ;
      echo "# VfL Bochum 1848" > README.md ;
      git add README.md ;
      mkdir -p ".bootstrap/b.build/bin/pos"
      git commit -m "bla bla bla"
   ) || exit 1
}




_test_a()
{
   run_mulle_bootstrap "$@" -y fetch --no-symlink-creation
   assert_a_1

   run_mulle_bootstrap "$@" -y upgrade --no-symlink-creation
   assert_a_2
}


test_a()
{
   (
      cd a ;
      _test_a "$@"
   ) || fail "setup"
}


#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

setup_test_case
test_a "$@"
clear_test_dirs a b

echo "succeeded" >&2

