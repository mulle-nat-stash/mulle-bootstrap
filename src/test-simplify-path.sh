#! /bin/sh -e

. mulle-bootstrap-functions.sh


run_test()
{
  expect="$1"
  shift

  result="`eval "$@"`"

  [ "${result}" != "${expect}" ] && fail "test:" "$@" "failed with \"${result}\", expected \"${expect}\""

  :
}


test_simplified_path()
{
#  run_test "" simplified_path ""

  run_test "/" simplified_path "/"
  run_test "/" simplified_path "/."
  run_test "/" simplified_path "/./"
  run_test "/" simplified_path "/.."     # return /
  run_test "/" simplified_path "/../"
  run_test "/" simplified_path "/foo/.."
  run_test "/" simplified_path "/foo/../"
  run_test "/" simplified_path "/foo/./.."
  run_test "/" simplified_path "/foo/../."
  run_test "/" simplified_path "/foo/../.."
  run_test "/"  simplified_path "/foo/../."
  run_test "/"  simplified_path "/foo/.././"
  run_test "/"  simplified_path "/foo/../.."
  run_test "/"  simplified_path "/foo/../../"

  run_test "/foo" simplified_path "/foo"
  run_test "/foo" simplified_path "/foo/"
  run_test "/foo" simplified_path "/foo/."
  run_test "/foo" simplified_path "/foo/./"

  run_test "/foo/bar" simplified_path "/foo/bar"
  run_test "/foo/bar" simplified_path "/foo/bar/"
  run_test "/foo/bar" simplified_path "/foo/./bar"
  run_test "/bar"     simplified_path "/foo/../bar"
  run_test "/bar"     simplified_path "/foo/../../bar"

  run_test "foo/bar" simplified_path "foo/bar"
  run_test "foo/bar" simplified_path "foo/bar/"
  run_test "foo/bar" simplified_path "foo/./bar"
  run_test "bar"     simplified_path "foo/../bar"
  run_test "."       simplified_path "foo/.."
}

fail()
{
   echo "failed:" "$@" >&2
   exit 1
}


test2()
{
   result="`simplified_path "$1"`"

   [ "${result}" = "${2}" ] || fail "$1: ${result} != ${2}"
   echo "$1 passed"
}


#set -x

#test2 "../.."   "../.."
#exit 0

test_simplified_path2()
{
  test2 "."   "."
  test2 "./"  "."
  test2 "/."  "/"
  test2 "/./" "/"

  test2 ".."   ".."
  test2 "../"  ".."
  test2 "/.."  "/"
  test2 "/../" "/"

  test2 "../.."   "../.."
  test2 "../../"  "../.."
  test2 "/../.."  "/"
  test2 "/../../" "/"

  test2 "../."     ".."
  test2 ".././"    ".."
  test2 ".././.."  "../.."
  test2 ".././../" "../.."
  test2 "/../."      "/"
  test2 "/.././"     "/"
  test2 "/.././.."   "/"
  test2 "/.././../"  "/"

  test2 "a/.."  "."
  test2 "a/../" "."
  test2 "a/..//" "."

  test2 "../a/../"  ".."
  test2 "../a/../b" "../b"
  test2 "/../a/.."  "/"
  test2 "/../a/../" "/"
  test2 "/../a/../" "/"
  test2 "/../a/../b" "/b"
  test2 "/../a/../b" "/b"

  test2 "//"  "/"
  test2 "./"  "."
  test2 "/"   "/"
  test2 "/./" "/"
  test2 "/.." "/"

  test2 "./x/../y" "y"

  test2 ".a"   ".a"
  test2 "/.a"  "/.a"
  test2 "/.a/" "/.a"

  test2 "..a"    "..a"
  test2 "../.a/" "../.a"
  test2 "/..a"  "/..a"

  test2 "..a/.."   "."
  test2 "../..a/"  "../..a"
  test2 "/..a/.."  "/"
  test2 "/../..a/" "/..a"
}


# set -x
# test2 "../a/.." ".."
# exit 1

test_simplified_path
test_simplified_path2

echo "test finished" >&2

