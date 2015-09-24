#! /bin/sh
#
# (c) 2015, coded by Nat!, Mulle KybernetiK
#
COMMAND=${1:-"build"}

. mulle-bootstrap-local-environment.sh

case "$COMMAND" in
   build)
   ;;
   dist)
   ;;
   *)
   echo "usage: mulle-bootstrap-clean.sh <build|dist>" 2>&1
   exit 1
   ;;
esac

#
# cleanability is checked, because in some cases its convenient
# to have other tools provide stuff besides /include and /lib
# and sometimes  projects install other stuff into /share
#
if [ "${CLONES_SUBDIR_IS_CLEANABLE}" = "YES" ]
then
   if [ "${COMMAND}" = "objects" -o "${COMMAND}" = "dist" -o "${COMMAND}" = "build"  ]
   then
      rm -rf "${CLONESBUILD_SUBDIR}" 2> /dev/null
   fi
fi

if [ "${DEPENDENCY_SUBDIR_IS_DIST_CLEANABLE}" = "YES" ]
then
   if [ "${COMMAND}" = "dist" -o "${COMMAND}" = "build"  ]
   then
      rm -rf "${DEPENDENCY_SUBDIR}" 2> /dev/null
   fi
fi


if [ "${COMMAND}" = "dist" ]
then
   rm -rf "${BOOTSTRAP_SUBDIR}.auto" 2> /dev/null

   if [ "${CLONES_SUBDIR_IS_CLEANABLE}" = "YES" ]
   then
      rm -rf "${CLONES_SUBDIR}"  2> /dev/null
   fi
fi
