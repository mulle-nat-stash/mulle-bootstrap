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


# embedded repositories are
setup()
{
   [ -d a ] && rm -rf a
   [ -d b ] && rm -rf b
   [ -d c ] && rm -rf c
   [ -d d ] && rm -rf d

   mkdir a
   mkdir b
   mkdir c
   mkdir d

   cd a
      echo "# a" > README.md
      git init
      git add README.md
      git commit -m "Merciful Release"
      cd ..

   cd b
      run_mulle_bootstrap init -n
      echo "a;src/a_1" > .bootstrap/embedded_repositories
      echo "# b" > README.md
      git init
      git add README.md .bootstrap/embedded_repositories
      git commit -m "Merciful Release"
      cd ..

   cd c
      run_mulle_bootstrap init -n
      echo "b;src/b_1" > .bootstrap/repositories
      echo "# c" > README.md
      git init
      git add README.md .bootstrap/repositories
      git commit -m "Merciful Release"
      cd ..

   cd d
      run_mulle_bootstrap init -n
      echo "c" > .bootstrap/repositories
      echo "# d" > README.md
      git init
      git add README.md .bootstrap/repositories
      git commit -m "Merciful Release"
      cd ..
}


fail()
{
   echo "$@" >&2
   exit 1
}


BOOTSTRAP_FLAGS="$@"


echo "" >&2
echo "" >&2
echo "=== setup ===" >&2
echo "" >&2
echo "" >&2

setup

echo "" >&2
echo "" >&2
echo "=== test 1 ===" >&2
echo "" >&2
echo "" >&2

(
   cd c ;
   run_mulle_bootstrap ${BOOTSTRAP_FLAGS} -y fetch --no-symlink-creation

   [ -d src/b_1 ]         || fail "b as src/b_1 failed to be added"
   [ -d src/b_1/src/a_1 ] || fail "src/b_1/src/a_1 failed to be embedded"
   :
) || exit 1


echo "" >&2
echo "" >&2
echo "=== test 2 ===" >&2
echo "" >&2
echo "" >&2


(
   # overwrite

   mkdir c/.bootstrap.local
   echo "b;src/b_2" > c/.bootstrap.local/repositories

   (
      cd b
      echo "a;src/a_2" > .bootstrap/embedded_repositories
      git commit -m "change" .bootstrap/embedded_repositories
   )

   cd c ;

   run_mulle_bootstrap ${BOOTSTRAP_FLAGS} -y upgrade --no-symlink-creation
   [ -d src/b_1 ] && fail "b as src/b_1 failed to be removed"
   [ -d src/b_2 ] || fail "b as src/b_2 failed to be added"
   [ -d src/b_2/src/a_2 ] || fail "src/b_2/src/a_2 failed to be embedded"
   [ -d src/b_2/src/a_1 ] && fail "src/b_2/src/a_1 failed to be removed"
   :
) || exit 1


echo "" >&2
echo "" >&2
echo "=== test 3 ===" >&2
echo "" >&2
echo "" >&2


(
   cd d ;

   run_mulle_bootstrap -a ${BOOTSTRAP_FLAGS} -y fetch --no-symlink-creation

   [ -d stashes/b/src/a_2 ] || fail "b as stashes/b_1/src/a_2 failed to be fetched"
   :
) || exit 1


echo "succeeded" >&2
