#! /bin/sh

# test doesn't work on MINGW
case "`uname`" in
   MINGW*)
      exit 0
   ;;
esac


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


rm -rf a b c  2> /dev/null

create_demo_repo a
create_demo_repo b
create_demo_repo c

# b embeds a
(
   cd b;
   mkdir .bootstrap ;
   echo "../a;src/a" > .bootstrap/embedded_repositories ;
   git add .bootstrap/embedded_repositories ;
   git commit -m "embedded added"
)

# c depends on b
(
   cd c ;
   mkdir .bootstrap ;
   echo "../b" > .bootstrap/repositories ;
   git add .bootstrap/repositories ;
   git commit -m "repository added"
)


##
## Now test
##
echo "--| 1 |--------------------------------"
(
   cd c ;
   mulle-bootstrap -y fetch  ;  # use symlink

   [ ! -L .repos/b ]     && fail "failed to symlink b" ;
   [ -d .repos/b/src/a ] && fail "superzealously embedded a" ;
   :
) || exit 1

#
# Make embedded repository appear
#
echo "--| 2 |--------------------------------"
(
   cd b ;
   mulle-bootstrap -y fetch  ;  # can't use symlink here

   [ ! -d src/a ] && fail "failed to embed a" ;
   [ -L src/a ]   && fail "mistakenly embedded a as a symlink" ;
   :
) || exit 1


#
# now move embedded repository (c should not touch it)
#
echo "--| 3 |--------------------------------"
(
   cd b ;
   echo "../a;a" > .bootstrap/embedded_repositories
)

(
   cd c ;
   mulle-bootstrap -y fetch  ;  # use symlink

   [ ! -L .repos/b ]     && fail "failed to symlink b" ;
   [ ! -d .repos/b/src/a ] && fail "superzealously removed a" ;
   [ -d .repos/b/a ]     && fail "superzealously added a" ;
   :
) || exit 1

echo "--| PASS |-----------------------------"
