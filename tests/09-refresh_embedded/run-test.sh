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
      echo "../a;src/a_1" > .bootstrap/embedded_repositories
      echo "# b" > README.md
      git init
      git add README.md .bootstrap/embedded_repositories
      git commit -m "Merciful Release"
      cd ..


   cd c
      run_mulle_bootstrap init -n
      echo "../b;src/b_1" > .bootstrap/embedded_repositories
      echo "# c" > README.md
      git init
      git add README.md .bootstrap/embedded_repositories
      git commit -m "Merciful Release"
      cd ..

   cd d
      run_mulle_bootstrap init -n
      echo "../c" > .bootstrap/repositories
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

setup

echo ""
echo ""
echo "=== setup done ==="
echo ""
echo ""

(
   cd c ;
   run_mulle_bootstrap ${BOOTSTRAP_FLAGS} fetch

   [ -d src/b_1 ] || fail "b as src/b_1 failed to be embedded"
   [ -d src/b_1/src/a_1 ] && fail "a was wrongly embedded"
   :
) || exit 1

echo ""
echo ""
echo "=== test 1 done ==="
echo ""
echo ""

(
   cd c ;
   sleep 1 ;
   echo "../b;src/b_2" > .bootstrap/embedded_repositories ;
   run_mulle_bootstrap ${BOOTSTRAP_FLAGS} fetch
   [ -d src/b_1 ] && fail "b as src/b_1 failed to be removed"
   [ -d src/b_2 ] || fail "b as src/b_2 failed to be added"
   :
) || exit 1

echo ""
echo ""
echo "=== test 2 done ==="
echo ""
echo ""


(
   cd d ;
   run_mulle_bootstrap -a ${BOOTSTRAP_FLAGS} fetch
   [ -d .repos/c/src/b_1 ] || fail "b as .repos/c/src/b_1 failed to be fetched"
   :
) || exit 1

echo ""
echo ""
echo "=== test 3 done ==="
echo ""
echo ""


(
   cd d ;
   sleep 1 ;
   echo "../b;src/b_2" > .repos/c/.bootstrap/embedded_repositories ;
   run_mulle_bootstrap ${BOOTSTRAP_FLAGS} fetch
   [ -d .repos/c/src/b_1 ] && fail "b as .repos/c/src/b_1 failed to be removed"
   [ -d .repos/c/src/b_2 ] || fail "b as .repos/c/src/b_2 failed to be added"
   :
) || exit 1

echo ""
echo ""
echo "=== test 4 done ==="
echo ""
echo ""

echo "succeeded" >&2
