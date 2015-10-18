#! /bin/sh

TAG="${1:-`./mulle-bootstrap version`}"

. mulle-bootstrap-functions.sh


git_must_be_clean()
{
   local name
   local clean

   name="${1:-${PWD}}"

   if [ ! -d .git ]
   then
      fail "\"${name}${C_ERROR} is not a git repository"
   fi

   clean=`git status -s`
   if [ "${clean}" != "" ]
   then
      fail "repository \"${name}${C_ERROR} is tainted"
   fi
}


set -e

git_must_be_clean

git tag "${TAG}"
git push public master --tags
./generate-brew-formula.sh  > ../homebrew-software/mulle-bootstrap.rb
(
	cd ../homebrew-software ; \
 	git commit -m "${TAG} release of mulle-bootstrap" mulle-bootstrap.rb ; \
 	git push origin master
)

