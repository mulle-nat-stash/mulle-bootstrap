#! /bin/sh
#
# (c) 2015, coded by Nat!, Mulle KybernetiK
#
COMMAND=${1:-"objs"}

. mulle-bootstrap-local-environment.sh

case "$COMMAND" in
   build)
   ;;
   dist)
   ;;
   objects|objs)
   ;;
   *)
   echo "usage: mulle-bootstrap-clean.sh <build|dist|objs>" 2>&1
   exit 1
   ;;
esac

#
# cleanability is checked, because in some cases its convenient
# to have other tools provide stuff besides /include and /lib
# and sometimes  projects install other stuff into /share
#
clean()
{
   if [ ! -z "$OBJECTS_CLEANABLE_SUBDIRS" ]
   then
      if [ "${COMMAND}" = "objects" -o "${COMMAND}" = "dist" -o "${COMMAND}" = "build"  ]
      then
         for dir in ${OBJECTS_CLEANABLE_SUBDIRS}
         do
            clean_asserted_folder "${dir}"
         done
      fi
   fi


   if [ ! -z "$BUILD_CLEANABLE_SUBDIRS" ]
   then
      if [ "${COMMAND}" = "dist" -o "${COMMAND}" = "build"  ]
      then
         for dir in ${BUILD_CLEANABLE_SUBDIRS}
         do
            clean_asserted_folder "${dir}"
         done
      fi
   fi


   if [ ! -z "$DIST_CLEANABLE_SUBDIRS" ]
   then
      if [ "${COMMAND}" = "dist" ]
      then
         for dir in ${DIST_CLEANABLE_SUBDIRS}
         do
            clean_asserted_folder "${dir}"
         done
      fi
   fi
}


main()
{
   clean
}


main
