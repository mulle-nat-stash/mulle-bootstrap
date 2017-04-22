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

   mkdir -p Master/Minion/.bootstrap
   mkdir -p Foobie
   mkdir -p Boobie

   (
      cd Master/Minion/.bootstrap ;
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
      cd Master/Minion

      run_mulle_bootstrap "$@" defer || exit 1
   ) || fail "defer"

   expect_file "Master/.bootstrap.local/is_master"
   expect_contents "Master/.bootstrap.local/minions" "Minion"
   expect_file "Master/Minion/.bootstrap.local/is_minion"

   (
      cd Master/Minion

      run_mulle_bootstrap "$@" emancipate || exit 1

   )

   expect_missing_file "Master/.bootstrap.local/is_master"
   expect_missing_file "Master/.bootstrap.local/minions"
   expect_missing_file "Master/Minion/.bootstrap.local/is_minion"

   (
      cd Master/Minion

      run_mulle_bootstrap "$@" defer || exit 1

   ) || fail "defer"
}


test_fetch()
{
   local owd

   owd="`pwd -P`"

   (
      cd Master/Minion

      run_mulle_bootstrap config search_path "${owd}" || exit 1
      run_mulle_bootstrap -y "$@" fetch  || exit 1

   ) || fail "defer"

   expect_contents "Master/.bootstrap.auto/build_order" "Foobie"
   expect_contents "Master/.bootstrap.auto/minions" "Minion"
   expect_contents "Master/.bootstrap.auto/repositories" "Foobie;stashes/Foobie;master;git"

   # abuse space cutting feature of bash here
   expect_contents "Master/.bootstrap.repos/.deep/Minion.d/Boobie" "Boobie;Minion/Boobie;master;git"
   expect_contents "Master/.bootstrap.repos/Foobie" "Foobie;stashes/Foobie;master;symlink"

   expect_contents "Master/stashes/Foobie/i_am_foobie.txt" "Foobie"
   expect_contents "Master/Minion/Boobie/i_am_boobie.txt" "Boobie"


   (
      cd Master
      run_mulle_bootstrap clean --minion Minion
   )

   expect_missing_file "Master/Minion/Boobie/i_am_boobie.txt"
}


#
# not that much of a test
#
echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

setup_test_case
test_defer "$@"
test_fetch "$@"

echo "succeeded" >&2

