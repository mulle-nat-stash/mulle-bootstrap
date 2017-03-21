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
setup()
{
   [ -d a ] && rm -rf a
   [ -d b ] && rm -rf b
   [ -d c ] && rm -rf c

   mkdir a
   mkdir b
   mkdir c

   (
      cd a

      mkdir -p .bootstrap
      echo "b" > .bootstrap/repositories

      mkdir -p .bootstrap/b.build/bin
      echo "echo a/.bootstrap/b.build/bin/pre-build.sh >&2" > .bootstrap/b.build/bin/pre-build.sh
      chmod 755 .bootstrap/b.build/bin/pre-build.sh
      # echo "echo a/.bootstrap/b.build/bin/post-build.sh >&2" > .bootstrap/b.build/bin/post-build.sh
      # chmod 755 .bootstrap/b.build/bin/post-build.sh

      mkdir -p .bootstrap/bin
      echo "echo a/.bootstrap/bin/pre-build.sh >&2" > .bootstrap/bin/pre-build.sh
      chmod 755 .bootstrap/bin/pre-build.sh
      echo "echo a/.bootstrap/bin/post-build.sh >&2" > .bootstrap/bin/post-build.sh
      chmod 755 .bootstrap/bin/post-build.sh
      echo "echo a/.bootstrap/bin/build.sh >&2" > .bootstrap/bin/build.sh
      chmod 755 .bootstrap/bin/build.sh
   )

   (
      cd b

      mkdir -p .bootstrap
      echo "c" > .bootstrap/repositories

      mkdir -p .bootstrap/c.build/bin
      echo "echo b/.bootstrap/c.build/bin/pre-build.sh >&2" > .bootstrap/c.build/bin/pre-build.sh
      chmod 755 .bootstrap/c.build/bin/pre-build.sh
      echo "echo b/.bootstrap/c.build/bin/post-build.sh >&2" > .bootstrap/c.build/bin/post-build.sh
      chmod 755 .bootstrap/c.build/bin/post-build.sh

      mkdir -p .bootstrap/bin
      echo "echo b/.bootstrap/bin/pre-build.sh >&2" > .bootstrap/bin/pre-build.sh
      chmod 755 .bootstrap/bin/pre-build.sh
      echo "echo b/.bootstrap/bin/post-build.sh >&2" > .bootstrap/bin/post-build.sh
      chmod 755 .bootstrap/bin/post-build.sh
      echo "echo b/.bootstrap/bin/build.sh >&2" > .bootstrap/bin/build.sh
      chmod 755 .bootstrap/bin/build.sh
   )

   (
      cd c

      mkdir -p .bootstrap/bin
      echo "echo c/.bootstrap/bin/pre-build.sh >&2" > .bootstrap/bin/pre-build.sh
      chmod 755 .bootstrap/bin/pre-build.sh

      echo "echo c/.bootstrap/bin/post-build.sh >&2" > .bootstrap/bin/post-build.sh
      chmod 755 .bootstrap/bin/post-build.sh
      echo "echo c/.bootstrap/bin/build.sh >&2" > .bootstrap/bin/build.sh
      chmod 755 .bootstrap/bin/build.sh
   )
}


fail()
{
   echo "$@" >&2
   exit 1
}

BOOTSTRAP_FLAGS="$@"

MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH

setup

(
   cd a ;

   results="`mulle-bootstrap -y -s ${BOOTSTRAP_FLAGS} 2>&1`" || fail "mulle-bootstrap failed"
   expected="a/.bootstrap/bin/pre-build.sh
c/.bootstrap/bin/pre-build.sh
c/.bootstrap/bin/build.sh
c/.bootstrap/bin/post-build.sh
a/.bootstrap/b.build/bin/pre-build.sh
b/.bootstrap/bin/build.sh
b/.bootstrap/bin/post-build.sh
a/.bootstrap/bin/post-build.sh"

   [ "${results}" != "${expected}" ] && fail "${results} != ${expected}"
   :
)


echo "succeeded" >&2

