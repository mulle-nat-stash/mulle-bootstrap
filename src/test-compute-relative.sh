#! /bin/sh

. mulle-bootstrap-functions.sh

run_test()
{
  expect="$1"
  shift

  result="`eval "$@"`"

  [ "${result}" != "${expect}" ] && fail "test:" "$@" "failed with \"${result}\", expected \"${expect}\""
}


test_compute_relative()
{
  run_test ""            compute_relative ""

  run_test ""            compute_relative "/"
  run_test ".."          compute_relative "/."
  run_test ".."          compute_relative "/./"
  run_test "../.."       compute_relative "/foo/.."
  run_test "../.."       compute_relative "/foo/../"
  run_test "../../.."    compute_relative "/foo/../../"

  run_test "../.."       compute_relative "/foo/bar"
  run_test "../../../.." compute_relative "foo/../../bar"

  run_test ".."          compute_relative "foo"
  run_test "../.."       compute_relative "foo/bar"
}


test_relative_path_between()
{
  run_test "."      relative_path_between /a /a
  run_test "."      relative_path_between /a /a/
  run_test "."      relative_path_between /a/ /a
  run_test "."      relative_path_between /a/ /a
  run_test "b"      relative_path_between /a/b /a
  run_test "b/c"    relative_path_between /a/b/c /a
  run_test "../b"   relative_path_between /b /a
  run_test "../b/c" relative_path_between /b/c /a

  run_test ".."     relative_path_between /a /a/b
  run_test "."      relative_path_between /a/b /a/b
  run_test "c"      relative_path_between /a/b/c /a/b

  run_test "../../b/c" relative_path_between /b/c /a/b
  run_test "../../c"   relative_path_between /c /a/b

  run_test "../.."  relative_path_between /a /a/b/c

  run_test "."      relative_path_between a a
  run_test "b/c"    relative_path_between a/b/c a

  run_test ".."     relative_path_between a a/b
  run_test "c"      relative_path_between a/b/c a/b

  run_test "../.."  relative_path_between a a/b/c
  run_test ".."     relative_path_between a/b a/b/c
  run_test "../../a/b"     relative_path_between a/b c/d

  run_test "../../.repos/.embedded" relative_path_between .repos/c/.repos/.embedded .repos/c/src/b_1

}

test_compute_relative
test_relative_path_between
