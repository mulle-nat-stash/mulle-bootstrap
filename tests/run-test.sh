#! /bin/sh


TEST_DIR="`dirname "$0"`"
PROJECT_DIR="`( cd "${TEST_DIR}/.." ; pwd -P)`"

PATH="${PROJECT_DIR}:$PATH"
export PATH

main()
{
   local i

   for i in "${TEST_DIR}"/*
   do
      if [ -x "$i/run-test.sh" ]
      then
         echo "------------------------------------------" >&2
         echo "$i:" >&2
         echo "------------------------------------------" >&2
         "$i/run-test.sh" "$@" || exit 1
      fi
   done
}

echo "mulle-bootstrap: `mulle-bootstrap version`(`mulle-bootstrap library-path`)" >&2

main "$@"
