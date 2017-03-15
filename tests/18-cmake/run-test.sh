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
setup()
{
   clear_test_dirs main

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

find_library( B_LIBRARY NAMES b)

add_executable( a
a.c
)

target_link_libraries( a
${B_LIBRARY}
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

install( TARGETS b DESTINATION "lib")
install( FILES b.h DESTINATION "include/b")
EOF
   )
}


fail()
{
   echo "$@" >&2
   exit 1
}



BOOTSTRAP_FLAGS="$@"

MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH


cmake > /dev/null 2>&1
if [ $? -eq 127 ]
then
   echo "cmake not installed, skipping test"
   exit 0
fi

setup || exit 1

(
   ( cd main/a; run_mulle_bootstrap defer ) || exit 1
   ( cd main/b; run_mulle_bootstrap defer ) || exit 1
   ( cd main;   run_mulle_bootstrap ${BOOTSTRAP_FLAGS} ) || exit 1
)

echo "succeeded" >&2
