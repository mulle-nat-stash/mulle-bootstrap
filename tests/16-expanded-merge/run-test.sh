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
   clear_test_dirs main

   mkdir -p main/a/.bootstrap
   mkdir -p main/b/.bootstrap
   mkdir -p main/c
   mkdir -p main/d

   echo "a" > main/a/identity
   echo "b" > main/b/identity
   echo "c" > main/c/identity
   echo "d" > main/d/identity

   echo "\${B}" > main/a/.bootstrap/repositories
   echo "b"     > main/a/.bootstrap/B
   echo "c"     > main/a/.bootstrap/C

   echo "\${C}" >  main/b/.bootstrap/repositories
   echo "\${D}" >> main/b/.bootstrap/repositories
   echo "x"     >  main/b/.bootstrap/C
   echo "d"     >  main/b/.bootstrap/D
}


setup_test_case_a()
{
   setup_test_case "$@"
}


assert_a()
{
   result="`cat stashes/b/identity`"
   [ "${result}" != "b" ] && fail "stashes/b not properly created ($result)"

   result="`cat stashes/c/identity`"
   [ "${result}" != "c" ] && fail "stashes/c not properly created ($result)"

   result="`cat stashes/d/identity`"
   [ "${result}" != "d" ] && fail "stashes/d not properly created ($result)"
   :
}


test_a()
{
   (
      cd main/a ;
      run_mulle_bootstrap "$@" -y fetch
      assert_a
   ) || fail "setup"
}


setup_test_case_b()
{
   setup_test_case "$@"

   mkdir -p "main/.bootstrap.local"
   echo "c" > main/.bootstrap.local/C
}


assert_b()
{
   run_mulle_bootstrap "$@" -y fetch

   result="`cat a/identity`"
   [ "${result}" != "a" ] && fail "stashes/a not properly created ($result)"

   result="`cat b/identity`"
   [ "${result}" != "b" ] && fail "stashes/b not properly created ($result)"

   result="`cat c/identity`"
   [ "${result}" != "c" ] && fail "stashes/c not properly created ($result)"

   result="`cat d/identity`"
   [ "${result}" != "d" ] && fail "stashes/d not properly created ($result)"

   :
}


test_b()
{
   ( cd main/a ; run_mulle_bootstrap "$@" defer )
   ( cd main/b ; run_mulle_bootstrap "$@" defer )
   ( cd main/c ; run_mulle_bootstrap "$@" defer )
   ( cd main/d ; run_mulle_bootstrap "$@" defer )

   (
      cd main ;
      run_mulle_bootstrap "$@" -y -vv -lm fetch
      assert_b
   ) || fail "setup"
}


echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

setup_test_case_a
test_a "$@"

setup_test_case_b
test_b "$@"
clear_test_dirs main

echo "succeeded" >&2

