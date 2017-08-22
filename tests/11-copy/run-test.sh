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

   value="`cat "$1" 2> /dev/null`"
   [ "${value}" != "${2}" ] && fail "${2} expected, ${value} found"
}


UNAME="`mulle-bootstrap uname`"
LIBPATH="`mulle-bootstrap library-path`"
PATH="${LIBPATH}:$PATH"

. mulle-bootstrap-copy.sh


test_override()
{
   rm -rf a b c d e 2> /dev/null

   create_demo_dir a
   create_demo_dir b  "a.${UNAME}"
   create_demo_dir c  "a.unknown"
   create_demo_dir d  "a"
   create_demo_dir e  "a" "a.${UNAME}"


   expect_file "a/a" ""

   override_files a b

   expect_file "a/a" "b/a.${UNAME}"

   override_files a c

   expect_file "a/a" "b/a.${UNAME}"

   override_files a d

   expect_file "a/a" "d/a"

   override_files a e

   expect_file "a/a" "e/a.${UNAME}"

   rm -rf a b c d e 2> /dev/null
}


test_inherit()
{
   rm -rf a b c  2> /dev/null

   create_demo_dir a
   create_demo_dir b  "a"
   create_demo_dir c  "a"


   expect_file "a/a" ""

   inherit_files a b

   expect_file "a/a" "b/a"

   inherit_files a c

   expect_file "a/a" "b/a"

   rm -rf a b c  2> /dev/null
}

MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH


test_override

test_inherit

echo "Test passed" >&2
