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


expect_missing_file()
{
   local filename="$1"

   if [ -f "${filename}" ]
   then
      fail "File \"${filename}\" exists, but shouldn't"
   fi
}


expect_file()
{
   local filename="$1"

   if [ ! -f "${filename}" ]
   then
      fail "File \"${filename}\" is missing"
   fi
}


expect_contents()
{
   local filename="$1"
   local expected="$2"

   expect_file "${filename}"

   local contents

   contents="`cat "${filename}"`"
   if [ "${contents}" != "${expected}" ]
   then
      fail "File \"${filename}\" contains
---
${contents}
---
but this was expected
---
${expected}
---"
   fi
}


#
#
#
setup_test_case()
{
   clear_test_dirs Master Boobie Foobie

   mkdir -p Master/Minion1/.bootstrap
   mkdir -p Master/Minion2/.bootstrap
   mkdir -p Foobie
   mkdir -p Boobie

   (
      cd Master/Minion1/.bootstrap ;
      echo "Boobie"  > embedded_repositories
      echo "Minion2" > repositories
   ) || exit 1

   (
      cd Master/Minion2/.bootstrap ;
      echo "Boobie" > embedded_repositories
      echo "Foobie" > repositories
   ) || exit 1


   (
      cd Foobie ;
      git init ;
      echo "Foobie" > i_am_foobie.txt ;
      git add i_am_foobie.txt ;
      git commit -m "bla bla"
   ) || exit 1

   (
      cd Boobie ;
      git init ;
      echo "Boobie" > i_am_boobie.txt ;
      git add i_am_boobie.txt ;
      git commit -m "bla bla"
   ) || exit 1
}



test_defer()
{
   (
      cd Master/Minion1

      run_mulle_bootstrap "$@" defer      || exit 1
      run_mulle_bootstrap "$@" emancipate || exit 1
      run_mulle_bootstrap "$@" defer      || exit 1
   ) || fail "defer"

   (
      cd Master/Minion2

      run_mulle_bootstrap "$@" defer      || exit 1
      run_mulle_bootstrap "$@" emancipate || exit 1
      run_mulle_bootstrap "$@" defer      || exit 1
   ) || fail "defer"

   expect_file "Master/.bootstrap.local/is_master"
   expect_contents "Master/.bootstrap.local/minions" "Minion1
Minion2"
   expect_file "Master/Minion1/.bootstrap.local/is_minion"
   expect_file "Master/Minion2/.bootstrap.local/is_minion"
}


test_fetch()
{
   local owd

   owd="`pwd -P`"

   (
      cd Master

      run_mulle_bootstrap config caches_path "${owd}" || exit 1
      run_mulle_bootstrap -y "$@" fetch  || exit 1

   ) || fail "defer"

   expect_contents "Master/.bootstrap.auto/build_order" "Foobie
Minion2"
   expect_contents "Master/.bootstrap.auto/minions" "Minion1
Minion2"
   expect_contents "Master/.bootstrap.auto/repositories" "Foobie;stashes/Foobie;master;git
Minion2;Minion2;master;git"

   # abuse space cutting feature of bash here
   expect_contents "Master/.bootstrap.repos/.deep/Minion1.d/Boobie" "Boobie;Minion1/Boobie;master;git"
   expect_contents "Master/.bootstrap.repos/.deep/Minion2.d/Boobie" "Boobie;Minion2/Boobie;master;git"
   expect_contents "Master/.bootstrap.repos/Foobie" "Foobie;stashes/Foobie;master;symlink"

   expect_contents "Master/stashes/Foobie/i_am_foobie.txt" "Foobie"
   expect_contents "Master/Minion1/Boobie/i_am_boobie.txt" "Boobie"
   expect_contents "Master/Minion2/Boobie/i_am_boobie.txt" "Boobie"
}


test_move()
{
   ( cd Master/Minion1 && run_mulle_bootstrap "$@" emancipate ) || fail "emancipate"

   expect_missing_file "Master/Minion1/Boobie/i_am_boobie.txt"

   ( cd Master && mv Minion1 Minion ) || fail "mv"

   ( cd Master/Minion && run_mulle_bootstrap "$@" defer ) || fail "defer"

   ( cd Master && run_mulle_bootstrap "$@" -y fetch ) || fail "fetch"

   expect_contents "Master/.bootstrap.auto/build_order" "Foobie
Minion2"
   expect_contents "Master/.bootstrap.auto/minions" "Minion2
Minion"
   expect_contents "Master/.bootstrap.auto/repositories" "Foobie;stashes/Foobie;master;git
Minion2;Minion2;master;git"

   # abuse space cutting feature of bash here
   expect_contents "Master/.bootstrap.repos/.deep/Minion.d/Boobie"  "Boobie;Minion/Boobie;master;git"
   expect_contents "Master/.bootstrap.repos/.deep/Minion2.d/Boobie" "Boobie;Minion2/Boobie;master;git"
   expect_contents "Master/.bootstrap.repos/Foobie" "Foobie;stashes/Foobie;master;symlink"

   expect_contents "Master/stashes/Foobie/i_am_foobie.txt" "Foobie"
   expect_contents "Master/Minion/Boobie/i_am_boobie.txt" "Boobie"
   expect_contents "Master/Minion2/Boobie/i_am_boobie.txt" "Boobie"

   expect_missing_file "Master/.bootstrap.repos/.deep/Minion1.d/Boobie"
}


#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

setup_test_case

echo "-----------------------------------" >&2
echo test_defer  >&2
echo "-----------------------------------" >&2

test_defer "$@"

echo "-----------------------------------" >&2
echo test_fetch  >&2
echo "-----------------------------------" >&2


test_fetch "$@"

echo "-----------------------------------" >&2
echo test_move  >&2
echo "-----------------------------------" >&2

test_move "$@"

echo "succeeded" >&2

