#! /usr/bin/env bash

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
create_demo_dir()
{
   local directory

   directory="$1"
   shift

   mkdir "${directory}"

   local name

   while [ $# -ne 0 ]
   do
      name="$1"
      shift

      echo "${directory}/${name}" > "${directory}/${name}"
   done
}

expect_file()
{
   local  value

   [ -f "$1" ] || fail "expected file $1 is missing"

   value="`cat "$1" 2> /dev/null`"
   [ "${value}" != "${2}" ] && fail "${2} expected, ${value} found"
}


test_copy()
{
   clear_test_dirs a

   run_mulle_bootstrap -s init -n a

   mkdir "a/.bootstrap/b.build/"

   echo "-DX=a -DY=B" > a/.bootstrap/b.build/CMAKEFLAGS


   ( cd a ; run_mulle_bootstrap fetch )

   expect_file "a/.bootstrap.auto/b.build/CMAKEFLAGS" "-DX=a -DY=B"

   clear_test_dirs a
}


test_copy

echo "Test passed" >&2
