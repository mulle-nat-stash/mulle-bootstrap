#! /bin/sh


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


clear_test_dir()
{
   if [ -d "$1" ]
   then
      rm -rf "$1"
   fi
}


clear_test_dirs()
{
   local i

   for i in "$@"
   do
      clear_test_dir "$i"
   done
}


test()
{
   cd a || exit 1
   mulle-bootstrap ${BOOTSTRAP_FLAGS} -y -f fetch || exit 1

   mulle-bootstrap ${BOOTSTRAP_FLAGS} refresh || exit 1

   result="`cat .bootstrap.auto/repositories`"
   expect=
   if [ "$1" != "${result}" ]
   then
      echo "failed: ($result)" >&2
   else
      echo "succeeded" >&2
   fi
}


BOOTSTRAP_FLAGS="$@"

#
# not that much of a test
#
clear_test_dirs a b c d e
setup_test_dirs
( setup_test_case1 ; test "e
d
c
b"
)

( setup_test_case2 ; test "d
c
b"
)

