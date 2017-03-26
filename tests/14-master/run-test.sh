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
   clear_test_dirs repos master

   mkdir -p repos/a/.bootstrap
   mkdir -p repos/b


   (
      cd repos/a ;
      git init ;
      echo "VfL Bochum 1848" > README.md ;
      echo "#empty" > .bootstrap/repositories
      git add README.md .bootstrap/repositories
      git commit -m "bla bla"
   ) || exit 1

   echo "b" > repos/a/.bootstrap/repositories
}


test_a()
{
   mkdir master
   (
      cd master
      git clone ../repos/a
   )

   (
      cd master/a ;
      run_mulle_bootstrap "$@" -y defer
   )

   local content

   content="`cat master/.bootstrap.local/minions`"
   [ "${content}" = "a" ] ||  fail "wrong minions"

   content="`cat master/a/.bootstrap.local/is_minion`"
   [ "${content}" = ".." ] ||  fail "wrong is_minion"

   [ -f  "master/.bootstrap.local/is_master" ] || fail "missing is_master"

   (
      cd master/a ;
      run_mulle_bootstrap "$@" paths -m
   )

   (
      cd master/a ;
      run_mulle_bootstrap "$@" -y fetch --no-symlinks
   )


   (
      cd master/a ;
      run_mulle_bootstrap "$@" emancipate
   )
}


#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH

setup_test_case
test_a "$@"
clear_test_dirs master repos

echo "succeeded" >&2

