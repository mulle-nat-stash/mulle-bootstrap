#! /bin/sh
#
# (c) 2015, coded by Nat!, Mulle KybernetiK
#
. mulle-bootstrap-local-environment.sh


BUILD_CLEANABLE_SUBDIRS=`read_sane_config_path_setting "clean_folders" "${CLONESBUILD_SUBDIR}
${DEPENDENCY_SUBDIR}/tmp"`
OUTPUT_CLEANABLE_SUBDIRS=`read_sane_config_path_setting "output_clean_folders" "${DEPENDENCY_SUBDIR}"`
DIST_CLEANABLE_SUBDIRS=`read_sane_config_path_setting "dist_clean_folders" "${CLONES_SUBDIR}
.bootstrap.auto"`


check_and_usage_and_help()
{
   case "$COMMAND" in
      output)
      ;;
      dist)
      ;;
      build)
      COMMAND="build"
      ;;
      *)
      echo "usage: mulle-bootstrap-clean.sh [build|output|dist]" >&2
      echo "" >&2
      echo "   build   : is the default, it cleans
${BUILD_CLEANABLE_SUBDIRS}" >&2
      echo "" >&2
      echo "   output  : cleans additionaly
${OUTPUT_CLEANABLE_SUBDIRS}" >&2
      echo "" >&2
      echo "   dist    : cleans additionaly
${DIST_CLEANABLE_SUBDIRS}" >&2
      exit 1
      ;;
   esac
}


if [ "$1" = "-h" -o "$1" = "--help" ]
then
   check_and_usage_and_help
fi


COMMAND=${1:-"build"}
shift

check_and_usage_and_help


clean_asserted_folder()
{
   if [ -d "$1" ]
   then
      assert_sane_subdir_path "$1"
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
   local old

   old="${IFS:-" "}"
   IFS="
"

   flag="NO"
   if [ ! -z "$BUILD_CLEANABLE_SUBDIRS" ]
   then
      if [ "${COMMAND}" = "build" -o "${COMMAND}" = "dist" -o "${COMMAND}" = "output"  ]
      then
         for dir in ${BUILD_CLEANABLE_SUBDIRS}
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

   IFS="${old}"
}


main()
{
   #
   # don't rename these settings anymore, the consequences can be catastrophic
   # for users of previous versions.
   # Also don't change the search paths for read_sane_config_path_setting
   #

   clean
}

main
