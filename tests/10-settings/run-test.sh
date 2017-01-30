#! /bin/sh -x

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


create_settings()
{
   local name

   name="$1"

   mkdir -p ".bootstrap/settings/${name}"
   mkdir -p ".bootstrap/config/${name}"
   mkdir -p ".bootstrap/public_settings/${name}"
   mkdir -p ".bootstrap/${name}.build"
   mkdir -p ".bootstrap/${name}"

   echo ".bootstrap/settings/${name}.txt"        > ".bootstrap/settings/${name}.txt"
   echo ".bootstrap/config/${name}.txt"          > ".bootstrap/config/${name}.txt"
   echo ".bootstrap/public_settings/${name}.txt" > ".bootstrap/public_settings/${name}.txt"

   echo ".bootstrap/settings/${name}/${name}.txt"        > ".bootstrap/settings/${name}/${name}.txt"
   echo ".bootstrap/config/${name}/${name}.txt"          > ".bootstrap/config/${name}/${name}.txt"
   echo ".bootstrap/public_settings/${name}/${name}.txt" > ".bootstrap/public_settings/${name}/${name}.txt"

   echo ".bootstrap/${name}.build/${name}.txt" > ".bootstrap/${name}.build/${name}.txt"
   echo ".bootstrap/${name}/${name}.txt"      > ".bootstrap/${name}/${name}.txt"
   echo ".bootstrap/${name}.txt"              > ".bootstrap/${name}.txt"
}


setup()
{
   [ -d a ] && rm -rf a
   [ -d b ] && rm -rf b
   [ -d c ] && rm -rf c

   mkdir a
   mkdir b
   mkdir c

   cd c
      create_settings "c"
      cd ..

   cd b
      mkdir -p .bootstrap
      echo "c" > .bootstrap/repositories
      create_settings "b"
      mkdir -p ".bootstrap/c"
      echo ".bootstrap/c/b.txt" > ".bootstrap/c/b.txt"
      cd ..

   cd a
      mkdir -p .bootstrap
      echo "b" > .bootstrap/repositories
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
   cd a ;
   mulle-bootstrap -y ${BOOTSTRAP_FLAGS} fetch
) || exit 1

expect="`mktemp -t foo.xxxx`"
result="`mktemp -t foo.xxxx`"
ls -R1a a | sed '/^[.]*$/d' > "${result}"
cat <<EOF > "${expect}"
.bootstrap
.bootstrap.auto
.bootstrap.repos
a/.bootstrap:
repositories
a/.bootstrap.auto:
b.build
c.build
repositories
a/.bootstrap.auto/b.build:
b.txt
a/.bootstrap.auto/c.build:
c.txt
a/.bootstrap.repos:
.bootstrap_fetch_done
.bootstrap_refresh_done
b
c
EOF

diff "${expect}" "${result}"
[ $? -ne 0 ] && fail "unexpected result"

rm -rf a b c

echo ""
echo ""
echo "=== test done ==="
echo ""
echo ""

