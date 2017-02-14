#! /bin/sh

. mulle-bootstrap-logging.sh
. mulle-bootstrap-repositories.sh
. mulle-bootstrap-fetch.sh


test_symlink_relpath()
{
   result="`symlink_relpath "$1"  "$2"`"
   if [ "${result}" != "$3" ]
   then
      fail "failed: $1 $2: \"${result}\" != \"$3\""
   fi
}


run_test_0()
{
   echo "-------------" >&2
   echo "test #0" >&2
   echo "-------------" >&2

   test_symlink_relpath "/a"     "/a"    "."
   test_symlink_relpath "/a"     "/a/"   "."
   test_symlink_relpath "/a/"    "/a"    "."
   test_symlink_relpath "/a/"    "/a/"   "."

   test_symlink_relpath "a" "a"          "."
   test_symlink_relpath "a" "b"          "../a"
   test_symlink_relpath "b" "a"          "../b"
   test_symlink_relpath "b" "b"          "."

   test_symlink_relpath "a/c"   "a"      "c"
   test_symlink_relpath "a/c"   "b"      "../a/c"
   test_symlink_relpath "b/c"   "a"      "../b/c"
   test_symlink_relpath "a/b/c" "c"      "../a/b/c"
}


run_test_1()
{
   echo "-------------" >&2
   echo "test #1" >&2
   echo "-------------" >&2

   test_symlink_relpath "/a"     "/a"     "."
   test_symlink_relpath "/a"     "/a/b"   ".."
   test_symlink_relpath "/a"     "/a/b/c" "../.."

   test_symlink_relpath "/a/b"   "/a"     "b"
   test_symlink_relpath "/a/b"   "/a/b"   "."
   test_symlink_relpath "/a/b"   "/a/b/c" ".."

   test_symlink_relpath "/a/b/c" "/a"     "b/c"
   test_symlink_relpath "/a/b/c" "/a/b"   "c"
   test_symlink_relpath "/a/b/c" "/a/b/c" "."
}


run_test_2()
{
   echo "-------------" >&2
   echo "test #2" >&2
   echo "-------------" >&2

   test_symlink_relpath "/x/y/z" "/a/b/c"  "../../../x/y/z"

   test_symlink_relpath "${PWD}/z" "z"    "."
}




run_test_3()
{
   echo "-------------" >&2
   echo "test #3" >&2
   echo "-------------" >&2

   test_symlink_relpath "./a"     "a"      "."
   test_symlink_relpath "./a"     "a/b"    ".."
   test_symlink_relpath "./a"     "a/b/c"  "../.."

   test_symlink_relpath "./a/b"   "a"      "b"
   test_symlink_relpath "./a/b"   "a/b"    "."
   test_symlink_relpath "./a/b"   "a/b/c"  ".."

   test_symlink_relpath "./a/b/c" "a"      "b/c"
   test_symlink_relpath "./a/b/c" "a/b"    "c"
   test_symlink_relpath "./a/b/c" "a/b/c"  "."
}


run_test_4()
{
   echo "-------------" >&2
   echo "test #4" >&2
   echo "-------------" >&2

   test_symlink_relpath "./a"     "./a"      "."
   test_symlink_relpath "./a"     "./a/b"    ".."
   test_symlink_relpath "./a"     "./a/b/c"  "../.."

   test_symlink_relpath "./a/b"   "./a"      "b"
   test_symlink_relpath "./a/b"   "./a/b"    "."
   test_symlink_relpath "./a/b"   "./a/b/c"  ".."

   test_symlink_relpath "./a/b/c" "./a"      "b/c"
   test_symlink_relpath "./a/b/c" "./a/b"    "c"
   test_symlink_relpath "./a/b/c" "./a/b/c"  "."
}


run_test_5()
{
   echo "-------------" >&2
   echo "test #5" >&2
   echo "-------------" >&2

   test_symlink_relpath "../a"     "./a"       "../../a"
   test_symlink_relpath "../a"     "./a/b"     "../../../a"
   test_symlink_relpath "../a"     "./a/b/c"   "../../../../a"

   test_symlink_relpath "../a/b"   "./a"       "../../a/b"
   test_symlink_relpath "../a/b"   "./a/b"     "../../../a/b"
   test_symlink_relpath "../a/b"   "./a/b/c"   "../../../../a/b"

   test_symlink_relpath "../a/b/c" "./a"       "../../a/b/c"
   test_symlink_relpath "../a/b/c" "./a/b"     "../../../a/b/c"
   test_symlink_relpath "../a/b/c" "./a/b/c"   "../../../../a/b/c"
}


run_test_6()
{
   echo "-------------" >&2
   echo "test #6" >&2
   echo "-------------" >&2

   test_symlink_relpath "../a"     "../a"       "."
   test_symlink_relpath "../a"     "../a/b"     ".."
   test_symlink_relpath "../a"     "../a/b/c"   "../.."

   test_symlink_relpath "../a/b"   "../a"       "b"
   test_symlink_relpath "../a/b"   "../a/b"     "."
   test_symlink_relpath "../a/b"   "../a/b/c"   ".."

   test_symlink_relpath "../a/b/c" "../a"       "b/c"
   test_symlink_relpath "../a/b/c" "../a/b"     "c"
   test_symlink_relpath "../a/b/c" "../a/b/c"   "."
}


run_test_7()
{
   echo "-------------" >&2
   echo "test #7" >&2
   echo "-------------" >&2

   test_symlink_relpath "a/b"      "a/b"          "."
   test_symlink_relpath "a/b"      "a/./b"        "."
   test_symlink_relpath "a/b"      "a/../b"       "../a/b"

   test_symlink_relpath "a/./b"     "a/b"         "."
   test_symlink_relpath "a/./b"     "a/./b"       "."
   test_symlink_relpath "a/./b"     "a/../b"      "../a/b"

   test_symlink_relpath "a/../b"     "a/b"        "../../b"
   test_symlink_relpath "a/../b"     "a/./b"      "../../b"
   test_symlink_relpath "a/../b"     "a/../b"     "."
}


MULLE_FLAG_LOG_FLUFF="YES"
MULLE_FLAG_LOG_VERBOSE="YES"
MULLE_TRACE_PATHS_FLIP_X="NO"

rm -rf deep 2> /dev/null

set -e

#_relative_path_between "/Volumes/Source/srcM/mulle-bootstrap/a" "/Volumes/Source/srcM/mulle-bootstrap/src/a"


run_test_0
run_test_1
run_test_2
run_test_3
run_test_4
run_test_5
run_test_6
run_test_7

rm -rf deep 2> /dev/null

echo "test finished" >&2

