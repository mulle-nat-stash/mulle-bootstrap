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

   mulle-bootstrap "$@"
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

   echo "b" >  a/.bootstrap/repositories
   echo "c" >> a/.bootstrap/repositories
}


test_a()
{
   (
      cd a ;
      if run_mulle_bootstrap "$@" fetch
      then
         fail "mulle-bootstrap did not fail, though c is required"
      fi
   ) || exit 1

   echo "b" > a/.bootstrap/required

   (
      cd a ;
      if ! run_mulle_bootstrap -f "$@" fetch
      then
         fail "mulle-bootstrap failed, although c is not required"
      fi
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

