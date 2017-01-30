#! /bin/sh

TAG="${1:-`./mulle-bootstrap version`}"


. src/mulle-bootstrap-logging.sh


git_must_be_clean()
{
   local name
   local clean

   name="${1:-${PWD}}"

   if [ ! -d .git ]
   then
      fail "\"${name}\" is not a git repository"
   fi

   clean=`git status -s --untracked-files=no`
   if [ "${clean}" != "" ]
   then
      fail "repository \"${name}\" is tainted"
   fi
}


git_must_be_clean

branch="`git rev-parse --abbrev-ref HEAD`"

git checkout release
git rebase "${branch}"
git push public release

# seperate step, as it's tedious to remove tag when
# previous push fails

git tag "${TAG}"
git push public release --tags
git push github release --tags

./bin/generate-brew-formula.sh  > ../homebrew-software/mulle-bootstrap.rb
(
	cd ../homebrew-software ; \
 	git commit -m "${TAG} release of mulle-bootstrap" mulle-bootstrap.rb ; \
 	git push origin master
)

git checkout "${branch}"

