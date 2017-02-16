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


produce_file()
{
   filename="$1"

   local where

   where=`basename -- "${PWD}"`

   mkdir -p "`dirname -- "${filename}"`"
   echo "# ${where} : ${filename}" > "${filename}"
}


#
#
#
create_settings()
{
   local name

   name="$1"

   #  stuff that should not be copied
   produce_file ".bootstrap/settings/${name}.build/${name}"
   produce_file ".bootstrap/settings/${name}.d/${name}"
   produce_file ".bootstrap/settings/${name}"
   produce_file ".bootstrap/config/${name}.build/${name}"
   produce_file ".bootstrap/config/${name}.d/${name}"
   produce_file ".bootstrap/config/${name}"
   produce_file ".bootstrap/${name}.d/${name}"

   # stuff that should be copied
   produce_file ".bootstrap/${name}"
   produce_file ".bootstrap/bin/${name}.sh"
   produce_file ".bootstrap/${name}.build/${name}"
   produce_file ".bootstrap/${name}.build/bin/${name}.sh"
}


setup()
{
   [ -d a ] && rm -rf a
   [ -d b ] && rm -rf b
   [ -d c ] && rm -rf c

   mkdir a
   mkdir b
   mkdir c

   (
      cd a
      mkdir -p .bootstrap
      echo "b" > .bootstrap/repositories
   )

   (
      cd b
      mkdir -p .bootstrap
      echo "c" > .bootstrap/repositories

      create_settings "b"
      produce_file ".bootstrap/c.build/override"
   )

   (
      cd c
      create_settings "c"
      produce_file ".bootstrap/c.build/inherit"
      produce_file ".bootstrap/c.build/override"
   )
}


fail()
{
   echo "$@" >&2
   exit 1
}

BOOTSTRAP_FLAGS="$@"

setup

(
   cd a ;
   mulle-bootstrap -y ${BOOTSTRAP_FLAGS} fetch
) || exit 1

[ -d "b/.bootstrap.auto" ] && fail "only a has a .auto folder"
[ -d "c/.bootstrap.auto" ] && fail "only a has a .auto folder"

[ "`cat a/.bootstrap.auto/c.build/inherit`" = "# c : .bootstrap/c.build/inherit" ] || fail "inheritance failed"
[ "`cat a/.bootstrap.auto/c.build/override`" = "# b : .bootstrap/c.build/override" ] || fail "override failed"


expect="`mktemp -t foo.xxxx`"
result="`mktemp -t foo.xxxx`"
ls -R1a a | sed '/^$/d' | sed '/^[.]*$/d' > "${result}"
cat <<EOF > "${expect}"
.bootstrap
.bootstrap.auto
.bootstrap.repos
stashes
a/.bootstrap:
repositories
a/.bootstrap.auto:
b.build
build_order
c.build
repositories
a/.bootstrap.auto/b.build:
b
bin
a/.bootstrap.auto/b.build/bin:
b.sh
a/.bootstrap.auto/c.build:
bin
c
inherit
override
a/.bootstrap.auto/c.build/bin:
c.sh
a/.bootstrap.repos:
.bootstrap_fetch_done
b
c
a/stashes:
b
c
EOF

diff "${expect}" "${result}"
[ $? -ne 0 ] && fail "unexpected result"

rm -rf a b c

echo "" >&2
echo "" >&2
echo "=== test done ===" >&2
echo "" >&2
echo "" >&2

