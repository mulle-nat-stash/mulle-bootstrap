#! /bin/sh


setup_test_dirs()
{
   mkdir -p a/.bootstrap
   mkdir -p a/x
   mkdir -p b/.bootstrap
   mkdir -p b/y
   mkdir -p c/z
}


setup_test_case()
{
   echo "b" > a/.bootstrap/repositories
   echo "c" > b/.bootstrap/repositories
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

fail()
{
   echo "failed" "$@" >&2
   exit 1
}


test()
{
   cd a || exit 1
   mulle-bootstrap ${BOOTSTRAP_FLAGS} -y -f fetch --update-symlinks || exit 1

   mulle-bootstrap ${BOOTSTRAP_FLAGS} refresh --update-symlinks || exit 1

   result="`cat .bootstrap.auto/repositories`"
   if [ "$1" != "${result}" ]
   then
      fail ": ($result)"
   else
      echo "succeeded" >&2
   fi

   [ -d .repos/b/y ] || fail ".repos/b/y missing"
   [ -d .repos/c/z ] || fail ".repos/c/z missing"
}


BOOTSTRAP_FLAGS="$@"

#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

clear_test_dirs a b c
setup_test_dirs
(
   setup_test_case ;
   test "c
b"
)

