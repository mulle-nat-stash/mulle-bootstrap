#! /bin/sh

TAP="${1:-software}"
[ $# -ne 0 ] && shift
BRANCH="${1:-release}"
[ $# -ne 0 ] && shift
TAG="${1:-`./mulle-bootstrap version`}"
[ $# -ne 0 ] && shift

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
   if [ ! -z "${clean}" ]
   then
      fail "repository \"${name}\" is tainted"
   fi
}


[ -d "../homebrew-$TAP" ] || fail "tap $TAP is invalid"

git_must_be_clean

devbranch="`git rev-parse --abbrev-ref HEAD`"

(
   git checkout "${BRANCH}"    &&
   git rebase "${devbranch}"   &&
   git push public "${BRANCH}"
) || exit 1


# seperate step, as it's tedious to remove tag when
# previous push fails

(
   git tag "${TAG}"                    &&
   git push public "${BRANCH}" --tags  &&
   git push github "${BRANCH}" --tags
) || exit 1


./bin/generate-brew-formula.sh  > ../homebrew-$TAP/mulle-bootstrap.rb
(
	cd ../homebrew-$TAP ; \
 	git commit -m "${TAG} release of mulle-bootstrap" mulle-bootstrap.rb ; \
 	git push origin master
)

git checkout "${devbranch}"
