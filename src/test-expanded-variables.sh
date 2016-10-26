#! /bin/sh

. mulle-bootstrap-functions.sh
. mulle-bootstrap-local-environment.sh


run_test()
{
  expect="$1"
  shift

  result="`eval "$@"`"

  [ "${result}" != "${expect}" ] && fail "test:" "$@" "failed with \"${result}\", expected \"${expect}\""
}


test_expand()
{
  FOO="foo"

  run_test "foo" expanded_variables '${FOO}'
  run_test "foo" expanded_variables '${FOO:-bar}'

  run_test "foofoo" expanded_variables '${FOO}${FOO}'

  run_test "" expanded_variables '${BAR}'
  run_test "foo" expanded_variables '${BAR:-foo}'

  # obscure but OK
  run_test "-bar" expanded_variables '${FOO+-bar}'
}


test_expand
