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


#
#
#
create_demo_repo()
{
   local name

   name="$1"

   set -e
   mkdir "${name}"
   cd "${name}"
   echo "# ${name}" > README.md
   git init
   git add README.md
   git commit -m "Merciful Release" README.md
   cd ..
   set +e
}


##
## Setup test environment
##
MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH

rm -rf a b c d e f g h main 2> /dev/null

create_demo_repo a
create_demo_repo b
create_demo_repo c

create_demo_repo d

create_demo_repo e
create_demo_repo f
create_demo_repo g
create_demo_repo h

set -e

# one subdirectory has an embedded dir
(
   cd a;
   mkdir .bootstrap
   cat <<EOF > .bootstrap/embedded_repositories
d
EOF
   git add .bootstrap/embedded_repositories
   git commit -m "embedded added"
) || fail "a setup"

# one project depends on "a": another unknown
(
   cd b;
   mkdir .bootstrap
   cat <<EOF > .bootstrap/repositories
h
EOF
   git add .bootstrap/repositories
   git commit -m "repository added"
) || fail "b setup"

# one project depends on "a": another known
(
   cd c;
   mkdir .bootstrap
   cat <<EOF > .bootstrap/repositories
a
EOF
   git add .bootstrap/repositories
   git commit -m "repository added"
) || fail "c setup"


mkdir "main" || fail "mkdir"
cd "main"

mkdir .bootstrap
cat <<EOF > .bootstrap/repositories
b
c
EOF
cat <<EOF > .bootstrap/embedded_repositories
e
f
g
EOF

echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

##
## Now test
##
echo "--| 1 |--------------------------------"
run_mulle_bootstrap "$@" -y fetch --no-symlink-creation

[ ! -d stashes/a ]   && echo "failed to fetch stashes/a ($PWD)" && exit 1
[ ! -d stashes/b ]   && echo "failed to fetch stashes/b ($PWD)" && exit 1
[ ! -d stashes/c ]   && echo "failed to fetch stashes/c ($PWD)" && exit 1
[ ! -d stashes/a/d ] && echo "failed to fetch stashes/a/d ($PWD)" && exit 1
[ ! -d e ]           && echo "failed to fetch d ($PWD)" && exit 1
[ ! -d f ]           && echo "failed to fetch e ($PWD)" && exit 1
[ ! -d g ]           && echo "failed to fetch f ($PWD)" && exit 1
[ ! -d stashes/h ]   && echo "failed to fetch stashes/h ($PWD)" && exit 1

echo "--| 2 |--------------------------------"
run_mulle_bootstrap "$@" -y fetch --no-symlink-creation

[ ! -d stashes/a ]   && echo "wrongly removed stashes/a ($PWD)" && exit 1
[ ! -d stashes/b ]   && echo "wrongly removed stashes/b ($PWD)" && exit 1
[ ! -d stashes/c ]   && echo "wrongly removed stashes/c ($PWD)" && exit 1
[ ! -d stashes/a/d ] && echo "wrongly removed stashes/a/d ($PWD)" && exit 1
[ ! -d e ]           && echo "wrongly removed e ($PWD)" && exit 1
[ ! -d f ]           && echo "wrongly removed f ($PWD)" && exit 1
[ ! -d g ]           && echo "wrongly removed g ($PWD)" && exit 1
[ ! -d stashes/h ]   && echo "wrongly removed stashes/h ($PWD)" && exit 1


cat <<EOF > .bootstrap/embedded_repositories
e
g
EOF

echo "--| 3 |--------------------------------"
run_mulle_bootstrap "$@" -y fetch --no-symlink-creation

[ ! -d stashes/a ]   && echo "wrongly removed stashes/a ($PWD)" && exit 1
[ ! -d stashes/b ]   && echo "wrongly removed stashes/b ($PWD)" && exit 1
[ ! -d stashes/c ]   && echo "wrongly removed stashes/c ($PWD)" && exit 1
[ ! -d stashes/a/d ] && echo "wrongly removed stashes/a/d ($PWD)" && exit 1
[ ! -d e ]           && echo "wrongly removed e ($PWD)" && exit 1
[   -d f ]           && echo "failed to remove f ($PWD)" && exit 1
[ ! -d g ]           && echo "wrongly removed g ($PWD)" && exit 1
[ ! -d stashes/h ]   && echo "wrongly removed stashes/h ($PWD)" && exit 1

cat <<EOF > .bootstrap/repositories
a
c
EOF

echo "--| 4 |--------------------------------"
run_mulle_bootstrap "$@" -y fetch --no-symlink-creation

[ ! -d stashes/a ]   && echo "wrongly removed stashes/a ($PWD)" && exit 1
[   -d stashes/b ]   && echo "failed to remove stashes/b ($PWD)" && exit 1
[ ! -d stashes/c ]   && echo "wrongly removed stashes/c ($PWD)" && exit 1
[ ! -d stashes/a/d ] && echo "wrongly removed stashes/a/d ($PWD)" && exit 1
[ ! -d e ]           && echo "wrongly removed e ($PWD)" && exit 1
[   -d f ]           && echo "failed to remove f ($PWD)" && exit 1
[ ! -d g ]           && echo "wrongly removed g ($PWD)" && exit 1
[   -d stashes/h ]   && echo "mistakenly refetched stashes/h ($PWD)" && exit 1

# hack
rm stashes/a/.bootstrap/embedded_repositories

# ls -a1RF >&2

echo "--| 5 |--------------------------------"
run_mulle_bootstrap "$@" -y fetch --no-symlink-creation

[ ! -d stashes/a ]   && echo "wrongly removed stashes/a ($PWD)" && exit 1
[   -d stashes/b ]   && echo "mistakenly refetched stashes/b ($PWD)" && exit 1
[ ! -d stashes/c ]   && echo "wrongly removed stashes/c ($PWD)" && exit 1
[   -d stashes/a/d ] && echo "failed to remove stashes/a/d ($PWD)" && exit 1
[ ! -d e ]           && echo "wrongly removed e ($PWD)" && exit 1
[   -d f ]           && echo "mistakenly refetched f ($PWD)" && exit 1
[ ! -d g ]           && echo "wrongly removed g ($PWD)" && exit 1
[   -d stashes/h ]   && echo "mistakenly refetched stashes/h ($PWD)" && exit 1

echo "--| PASS |-----------------------------"
