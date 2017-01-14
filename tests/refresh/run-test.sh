#! /bin/sh

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
../d
EOF
   git add .bootstrap/embedded_repositories
   git commit -m "embedded added"
)

# one project depends on "a": another unknown
(
   cd b;
   mkdir .bootstrap
   cat <<EOF > .bootstrap/repositories
../h
EOF
   git add .bootstrap/repositories
   git commit -m "repository added"
)

# one project depends on "a": another known
(
   cd c;
   mkdir .bootstrap
   cat <<EOF > .bootstrap/repositories
../a
EOF
   git add .bootstrap/repositories
   git commit -m "repository added"
)


mkdir "main"
cd "main"

mkdir .bootstrap
cat <<EOF > .bootstrap/repositories
../b
../c
EOF
cat <<EOF > .bootstrap/embedded_repositories
../e
../f
../g
EOF

echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

##
## Now test
##
echo "--| 1 |--------------------------------"
mulle-bootstrap "$@" -a fetch

[ ! -d .repos/a ]   && echo "failed to fetch .repos/a ($PWD)" && exit 1
[ ! -d .repos/b ]   && echo "failed to fetch .repos/b ($PWD)" && exit 1
[ ! -d .repos/c ]   && echo "failed to fetch .repos/c ($PWD)" && exit 1
[ ! -d .repos/a/d ] && echo "failed to fetch .repos/a/d ($PWD)" && exit 1
[ ! -d e ]          && echo "failed to fetch d ($PWD)" && exit 1
[ ! -d f ]          && echo "failed to fetch e ($PWD)" && exit 1
[ ! -d g ]          && echo "failed to fetch f ($PWD)" && exit 1
[ ! -d .repos/h ]   && echo "failed to fetch .repos/h ($PWD)" && exit 1

echo "--| 2 |--------------------------------"
mulle-bootstrap "$@" refresh

[ ! -d .repos/a ]   && echo "wrongly removed .repos/a ($PWD)" && exit 1
[ ! -d .repos/b ]   && echo "wrongly removed .repos/b ($PWD)" && exit 1
[ ! -d .repos/c ]   && echo "wrongly removed .repos/c ($PWD)" && exit 1
[ ! -d .repos/a/d ] && echo "wrongly removed .repos/a/d ($PWD)" && exit 1
[ ! -d e ]          && echo "wrongly removed e ($PWD)" && exit 1
[ ! -d f ]          && echo "wrongly removed f ($PWD)" && exit 1
[ ! -d g ]          && echo "wrongly removed g ($PWD)" && exit 1
[ ! -d .repos/h ]   && echo "wrongly removed .repos/h ($PWD)" && exit 1


cat <<EOF > .bootstrap/embedded_repositories
../e
../g
EOF

echo "--| 3 |--------------------------------"
mulle-bootstrap "$@" refresh

[ ! -d .repos/a ]   && echo "wrongly removed .repos/a ($PWD)" && exit 1
[ ! -d .repos/b ]   && echo "wrongly removed .repos/b ($PWD)" && exit 1
[ ! -d .repos/c ]   && echo "wrongly removed .repos/c ($PWD)" && exit 1
[ ! -d .repos/a/d ] && echo "wrongly removed .repos/a/d ($PWD)" && exit 1
[ ! -d e ]          && echo "wrongly removed e ($PWD)" && exit 1
[   -d f ]          && echo "failed to remove f ($PWD)" && exit 1
[ ! -d g ]          && echo "wrongly removed g ($PWD)" && exit 1
[ ! -d .repos/h ]   && echo "wrongly removed .repos/h ($PWD)" && exit 1

cat <<EOF > .bootstrap/repositories
../a
../c
EOF

echo "--| 4 |--------------------------------"
mulle-bootstrap "$@" refresh

[ ! -d .repos/a ]   && echo "wrongly removed .repos/a ($PWD)" && exit 1
[   -d .repos/b ]   && echo "failed to remove .repos/b ($PWD)" && exit 1
[ ! -d .repos/c ]   && echo "wrongly removed .repos/c ($PWD)" && exit 1
[ ! -d .repos/a/d ] && echo "wrongly removed .repos/a/d ($PWD)" && exit 1
[ ! -d e ]          && echo "wrongly removed e ($PWD)" && exit 1
[   -d f ]          && echo "failed to remove f ($PWD)" && exit 1
[ ! -d g ]          && echo "wrongly removed g ($PWD)" && exit 1
[   -d .repos/h ]   && echo "mistakenly refetched .repos/h ($PWD)" && exit 1

# hack
rm .repos/a/.bootstrap/embedded_repositories

echo "--| 5 |--------------------------------"
mulle-bootstrap "$@" refresh

[ ! -d .repos/a ]   && echo "wrongly removed .repos/a ($PWD)" && exit 1
[   -d .repos/b ]   && echo "mistakenly refetched .repos/b ($PWD)" && exit 1
[ ! -d .repos/c ]   && echo "wrongly removed .repos/c ($PWD)" && exit 1
[   -d .repos/a/d ] && echo "failed to remove .repos/a/d ($PWD)" && exit 1
[ ! -d e ]          && echo "wrongly removed e ($PWD)" && exit 1
[   -d f ]          && echo "mistakenly refetched f ($PWD)" && exit 1
[ ! -d g ]          && echo "wrongly removed g ($PWD)" && exit 1
[   -d .repos/h ]   && echo "mistakenly refetched .repos/h ($PWD)" && exit 1

echo "--| PASS |-----------------------------"
