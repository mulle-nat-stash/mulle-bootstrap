#! /bin/sh -e

. ./mulle-bootstrap-functions.sh
. ./mulle-bootstrap-local-environment.sh
. ./mulle-bootstrap-settings.sh


run_test()
{
  expect="$1"
  shift

  result="`expanded_variables "$2" "" ""`"

  [ "${result}" != "${expect}" ] && fail "test:" "$@" "failed with \"${result}\", expected \"${expect}\""
  :
}


test_expand()
{
  FOO="foo"

  run_test "foo" '${FOO}'
  run_test "foo" '${FOO:-bar}'

  run_test "foofoo" '${FOO}${FOO}'

  run_test "" '${BAR}'
  run_test "foo" '${BAR:-foo}'

  # obscure but OK
  run_test "-bar" '${FOO+-bar}'
}


test_git_remote_expand()
{
   set -x
   run_test "nat@mulle-kybernetik.com:/scm/public_git/repositories/mulle-tests" expanded_variables '${GIT_REMOTE_PUBLIC}/mulle-tests'
   exit 0
}

test_git_remote_expand
test_expand

echo "test finished" >&2
