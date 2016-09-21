#! /bin/sh

. mulle-bootstrap-functions.sh

run_test()
{
  expect="$1"
  shift

  result="`eval "$@"`"

  [ "${result}" != "${expect}" ] && fail "test:" "$@" "failed with \"${result}\", expected \"${expect}\""
}


test_simplify_path()
{
  run_test "" simplify_path ""

  run_test "/" simplify_path "/"
  run_test "/" simplify_path "/."
  run_test "/" simplify_path "/./"
  run_test "/" simplify_path "/.."     # return /
  run_test "/" simplify_path "/../"
  run_test "/" simplify_path "/foo/.."
  run_test "/" simplify_path "/foo/../"
  run_test "/" simplify_path "/foo/./.."
  run_test "/" simplify_path "/foo/../."
  run_test "/" simplify_path "/foo/../.."
  run_test "/"  simplify_path "/foo/../."
  run_test "/"  simplify_path "/foo/.././"
  run_test "/"  simplify_path "/foo/../.."
  run_test "/"  simplify_path "/foo/../../"

  run_test "/foo" simplify_path "/foo"
  run_test "/foo" simplify_path "/foo/"
  run_test "/foo" simplify_path "/foo/."
  run_test "/foo" simplify_path "/foo/./"

  run_test "/foo/bar" simplify_path "/foo/bar"
  run_test "/foo/bar" simplify_path "/foo/bar/"
  run_test "/foo/bar" simplify_path "/foo/./bar"
  run_test "/bar"     simplify_path "/foo/../bar"
  run_test "/bar"     simplify_path "/foo/../../bar"

  run_test "foo/bar" simplify_path "foo/bar"
  run_test "foo/bar" simplify_path "foo/bar/"
  run_test "foo/bar" simplify_path "foo/./bar"
  run_test "bar"     simplify_path "foo/../bar"
  run_test "."       simplify_path "foo/.."
}


test_simplify_path
