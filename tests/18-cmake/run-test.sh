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
setup()
{
   mkdir -p main/a
   mkdir -p main/b

   (
      cd main/a

      mkdir -p .bootstrap
      echo "b" > .bootstrap/repositories
      cat <<EOF > a.c
#include <b/b.h>

int main()
{
   return( b());
}
EOF

      cat <<EOF > CMakeLists.txt
project( a)

add_executable( a
a.c
)
EOF
   )

   (
      cd main/b

      mkdir -p .bootstrap
      cat <<EOF > b.c
int   b()
{
   return( 0);
}
EOF
      cat <<EOF > b.h
int   b()
{
   return( 0);
}
EOF
      cat <<EOF > CMakeLists.txt
project( b)

add_library( b
b.c
b.h
)
EOF
   )
}


fail()
{
   echo "$@" >&2
   exit 1
}

BOOTSTRAP_FLAGS="$@"

cmake > /dev/null 2>&1
if [ $? -eq 127 ]
then
   echo "cmake not installed, skipping test"
   exit 0
fi

setup || exit 1

(
   ( cd main/a; run_mulle_bootstrap ${BOOTSTRAP_FLAGS} defer ) || exit 1
   ( cd main/b; run_mulle_bootstrap ${BOOTSTRAP_FLAGS} defer ) || exit 1
   ( cd main; run_mulle_bootstrap ${BOOTSTRAP_FLAGS} ) || exit 1
)


echo "succeeded" >&2

