#! /bin/sh

# test doesn't work on MINGW
case "`uname`" in
   MINGW*)
      exit 0
   ;;
esac


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


fail()
{
   echo "$@" >&2
   exit 1
}


##
## Setup test environment
##

MULLE_BOOTSTRAP_CACHES_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_CACHES_PATH


rm -rf a b c  2> /dev/null

create_demo_repo a
create_demo_repo b
create_demo_repo c

# b embeds a
(
   cd b;
   mkdir .bootstrap ;
   echo "a;src/a" > .bootstrap/embedded_repositories ;
   git add .bootstrap/embedded_repositories ;
   git commit -m "embedded added"
) 2> /dev/null

# c depends on b
(
   cd c ;
   mkdir .bootstrap ;
   echo "b" > .bootstrap/repositories ;
   git add .bootstrap/repositories ;
   git commit -m "repository added"
) 2> /dev/null


##
## Now test
##
echo "--| 1 |--------------------------------"
(
   cd c ;
   run_mulle_bootstrap "$@" -y fetch  ;  # use symlink

   [ ! -L stashes/b ]     && fail "failed to symlink b" ;
   [ -d stashes/b/src/a ] && fail "superzealously embedded a" ;
   :
) || exit 1

#
# Make embedded repository appear
#
echo "--| 2 |--------------------------------"
(
   cd b ;
   run_mulle_bootstrap "$@" -y fetch  ;  # can't use symlink here

   [ ! -d src/a ] && fail "failed to embed a" ;
   [ -L src/a ]   && fail "mistakenly embedded a as a symlink" ;
   :
) || exit 1


#
# now move embedded repository (c should not touch it, because we
# don't allow following symlinks at first)
#
echo "--| 3 |--------------------------------"
(
   cd b ;
   echo "a;a" > .bootstrap/embedded_repositories
)

(
   cd c ;
   run_mulle_bootstrap "$@" -y fetch

   [ ! -L stashes/b ]       && fail "failed to symlink b" ;
   [ ! -d stashes/b/src/a ] && fail "superzealously removed symlinked src/a" ;
   [ -d stashes/b/a ]       && fail "superzealously embedded a" ;
   :
) || exit 1


echo "--| 4 |--------------------------------"

(
   cd c ;
   run_mulle_bootstrap "$@" -y fetch --follow-symlinks

   [ ! -L stashes/b ]     && fail "failed to symlink b" ;
   [ ! -d stashes/b/src/a ] && fail "removed src/a, though it shouldn't know about it" ;
   [ ! -d stashes/b/a ]   && fail "failed to embed a" ;
   :
) || exit 1


echo "--| PASS |-----------------------------"
