#! /bin/sh
#
# (c) 2015, coded by Nat!, Mulle KybernetiK
#
COMMAND=${1:-"objs"}

. mulle-bootstrap-local-environment.sh

case "$COMMAND" in
   output)
   ;;
   dist)
   ;;
   intermediate|objs|build)
   COMMAND="objs"
   ;;
   *)
   echo "usage: mulle-bootstrap-clean.sh [output|dist]" 2>&1
   exit 1
   ;;
esac


clean_asserted_folder()
{

   if [ -d "$1" ]
   then
      assert_sane_path "$1"
      log_info "Deleting \"$1\""
      exekutor rm -rf "$1"
   else
      log_fluff "\"$1\" doesn't exist"
   fi
}


#
# cleanability is checked, because in some cases its convenient
# to have other tools provide stuff besides /include and /lib
# and sometimes  projects install other stuff into /share
#
clean()
{
   local flag

   flag="NO"
   if [ ! -z "$OBJS_CLEANABLE_SUBDIRS" ]
   then
      if [ "${COMMAND}" = "objs" -o "${COMMAND}" = "dist" -o "${COMMAND}" = "output"  ]
      then
         for dir in ${OBJS_CLEANABLE_SUBDIRS}
         do
            clean_asserted_folder "${dir}"
            flag="YES"
         done
      fi
   fi


   if [ ! -z "$OUTPUT_CLEANABLE_SUBDIRS" ]
   then
      if [ "${COMMAND}" = "dist" -o "${COMMAND}" = "output"  ]
      then
         for dir in ${OUTPUT_CLEANABLE_SUBDIRS}
         do
            clean_asserted_folder "${dir}"
            flag="YES"
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
            flag="YES"
         done
      fi
   fi

   if [ "$flag" = "NO" ]
   then
      log_info "Nothing configured to clean"
   fi
}


main()
{
   #
   # don't rename these settings anymore, the consequences can be catastrophic
   # for users of previous versions.
   # Also don't change the search paths for read_sane_config_path_setting
   #
   OBJS_CLEANABLE_SUBDIRS=`read_sane_config_path_setting "clean_folders" "${CLONESBUILD_SUBDIR}"`
   OUTPUT_CLEANABLE_SUBDIRS=`read_sane_config_path_setting "output_clean_folders" "${DEPENDENCY_SUBDIR}"`
   DIST_CLEANABLE_SUBDIRS=`read_sane_config_path_setting "dist_clean_folders" "${CLONES_SUBDIR}
.bootstrap.auto"`

   clean
}


main
