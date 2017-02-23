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
   kill 0
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
   clear_test_dirs a

   mkdir -p a/.bootstrap

   url=https://github.com/mulle-nat/Noobie/archive/tar-test.tar.gz
   checksum="a8c0251d1cd8c0a08fde83724bff57cfcd3e49fcab262369dc117c788f751c9a"
   echo "${url};;;tar?shasum256=${checksum}" > a/.bootstrap/repositories

   url="https://github.com/mulle-nat/Foobie/archive/tar-test.zip"
   checksum="f49106180b1fb5f4061a3528f6903f99e680ad169557bb876052eadbdb7a64a2"
   echo "${url};;;zip?shasum256=${checksum}" >> a/.bootstrap/repositories
}



test_a()
{
   (
      cd a
      MULLE_BOOTSTRAP_CACHES_PATH=/tmp run_mulle_bootstrap "$@" fetch
   )
}


#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

setup_test_case
test_a "$@"
clear_test_dirs a

echo "succeeded" >&2

