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
   git commit -m "Mercyful Release" README.md
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

# one project depends on a another unknown
(
   cd b;
   mkdir .bootstrap
   cat <<EOF > .bootstrap/repositories
../h
EOF
   git add .bootstrap/repositories
   git commit -m "repository added"
)

# one project depends on a another known
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

##
## Now test
##
echo "--| 1 |--------------------------------"
mulle-bootstrap -a fetch

[ ! -d .repos/a ]   && echo "failed to fetch a" && exit 1
[ ! -d .repos/b ]   && echo "failed to fetch b" && exit 1
[ ! -d .repos/c ]   && echo "failed to fetch c" && exit 1
[ ! -d .repos/a/d ] && echo "failed to fetch a/d" && exit 1
[ ! -d e ]          && echo "failed to fetch d" && exit 1
[ ! -d f ]          && echo "failed to fetch e" && exit 1
[ ! -d g ]          && echo "failed to fetch f" && exit 1
[ ! -d .repos/h ]   && echo "failed to fetch h" && exit 1

echo "--| 2 |--------------------------------"
mulle-bootstrap refresh

[ ! -d .repos/a ]   && echo "wrongly removed a" && exit 1
[ ! -d .repos/b ]   && echo "wrongly removed b" && exit 1
[ ! -d .repos/c ]   && echo "wrongly removed c" && exit 1
[ ! -d .repos/a/d ] && echo "wrongly removed a/d" && exit 1
[ ! -d e ]          && echo "wrongly removed e" && exit 1
[ ! -d f ]          && echo "wrongly removed f" && exit 1
[ ! -d g ]          && echo "wrongly removed g" && exit 1
[ ! -d .repos/h ]   && echo "wrongly removed h" && exit 1


cat <<EOF > .bootstrap/embedded_repositories
../e
../g
EOF

echo "--| 3 |--------------------------------"
mulle-bootstrap refresh

[ ! -d .repos/a ]   && echo "wrongly removed a" && exit 1
[ ! -d .repos/b ]   && echo "wrongly removed b" && exit 1
[ ! -d .repos/c ]   && echo "wrongly removed c" && exit 1
[ ! -d .repos/a/d ] && echo "wrongly removed a/d" && exit 1
[ ! -d e ]          && echo "wrongly removed e" && exit 1
[   -d f ]          && echo "failed to remove f" && exit 1
[ ! -d g ]          && echo "wrongly removed g" && exit 1
[ ! -d .repos/h ]   && echo "wrongly removed h" && exit 1

cat <<EOF > .bootstrap/repositories
../a
../c
EOF

echo "--| 4 |--------------------------------"
mulle-bootstrap refresh

[ ! -d .repos/a ]   && echo "wrongly removed a" && exit 1
[   -d .repos/b ]   && echo "failed to remove b" && exit 1
[ ! -d .repos/c ]   && echo "wrongly removed c" && exit 1
[ ! -d .repos/a/d ] && echo "wrongly removed a/d" && exit 1
[ ! -d e ]          && echo "wrongly removed e" && exit 1
[   -d f ]          && echo "failed to remove f" && exit 1
[ ! -d g ]          && echo "wrongly removed g" && exit 1
[   -d .repos/h ]   && echo "mistakenly refetched h" && exit 1

# hack
rm .repos/a/.bootstrap/embedded_repositories

echo "--| 5 |--------------------------------"
mulle-bootstrap refresh

[ ! -d .repos/a ]   && echo "wrongly removed a" && exit 1
[   -d .repos/b ]   && echo "mistakenly refetched b" && exit 1
[ ! -d .repos/c ]   && echo "wrongly removed c" && exit 1
[   -d .repos/a/d ] && echo "failed to remove a/d" && exit 1
[ ! -d e ]          && echo "wrongly removed e" && exit 1
[   -d f ]          && echo "mistakenly refetched f" && exit 1
[ ! -d g ]          && echo "wrongly removed g" && exit 1
[   -d .repos/h ]   && echo "mistakenly refetched h" && exit 1

echo "--| PASS |-----------------------------"
