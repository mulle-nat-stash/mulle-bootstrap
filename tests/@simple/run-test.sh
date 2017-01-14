#! /bin/sh


setup_test_dirs()
{
   mkdir -p a/.bootstrap
   mkdir -p b
}


setup_test_case()
{
   echo "b" > a/.bootstrap/repositories
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
      exit 1
   else
      echo "succeeded" >&2
   fi
}


BOOTSTRAP_FLAGS="$@"

#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

clear_test_dirs a b
setup_test_dirs
(
   setup_test_case ;
   test "b"
)

