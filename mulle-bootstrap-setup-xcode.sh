#! /bin/sh
#
# (c) 2015, coded by Nat!, Mulle KybernetiK
#
# this script patches the xcodeproj so that the headers and
# lib files can be added in a sensible order
#

. mulle-bootstrap-local-environment.sh

HEADER_PATH=`read_local_setting "header_path" "/include"`
LIBRARY_PATH=`read_local_setting "library_path" "/lib"`
FRAMEWORK_PATH=`read_local_setting "framework_path" "/Frameworks"`


list_configurations()
{
  #
  # Figure out all configuration
  #
   xcodebuild -list -project "$1" 2> /dev/null | \
   grep -A100 'Build Configurations' | \
   grep -B100 'Schemes' | \
   egrep -v 'Configurations:|Schemes:' | \
   grep -v 'If no build' | \
   awk '{ print $1 }' | \
   sed /^$/d
}


#
# Figure out default configuration
#
list_default_configuration()
{
   xcodebuild -list 2> /dev/null | grep 'If no build configuration' | sed 's/^.*\"\(.*\)\".*$/\1/g'
}


check_for_python()
{
   local python

   python="`which python`"
   if [ "$python" = "" ]
   then
      echo "Need to install python with pip to install mod_pbxproj." >&2
      echo "The author suggests you install phyton with brew (http://brew.sh)" >&2
      user_say_yes "Install brew now ?"
      [ $? -eq 0 ] || exit 1

      fetch_brew_if_needed
      brew install python  || exit 1
   fi
}



check_for_pip()
{
   local pip

   pip="`which pip`"
   if [ "$pip" = "" ]
   then
      echo "Need to install python with pip to install mod_pbxproj. You have only python." >&2
      echo "The author suggests you install phyton with brew (http://brew.sh)" >&2
      user_say_yes "Install python now ?"
      [ $? -eq 0 ] || exit 1

      fetch_brew_if_needed
      brew install python || exit 1
   fi
}



check_for_mod_pbxproj()
{
   local installed

   check_for_python

   #
   # OK
   #
   installed=`python -m mod_pbxproj 2>&1 | grep usage`
   if [ "$installed" = "" ]
   then
      user_say_yes "Need to install mod_pbxproj (as sudo)
   Install mod_pbxproj now ?"
      [ $? -eq 0 ] || exit 1

      check_for_pip

      echo "pip needs to run as sudo, and may ask you for your password." >&2
      sudo pip install mod_pbxproj
      if [ $? -ne 0 ]
      then
         echo "Pip didn't work. )Pip is part of python)" >&2
         echo "Maybe it's too old." >&2

         user_say_yes "Try to upgrade pip ?"
         [ $? -eq 0 ] || exit 1

         echo "pip needs to run as sudo, and may ask you for your password." >&2
         sudo pip install --upgrade pip setuptools
         sudo pip install mod_pbxproj
      fi
   fi
}


patch_xcode_project()
{
   local name
   local project
   local prefix
   local mapped
   local configurations
   local xcode_configurations

   name=`basename "${PWD}"`
   project=`find_xcodeproj "${name}"`
   if [ "${project}" = "" ]
   then
      fail "no xcodeproj found"
   fi

   projectname="`basename \"${project}\"`"

   #     012345678901234567890123456789012345678901234567890123456789
   echo "This operation will not destroy any existing settings." >&2
   echo "The nearest Xcode project found is:" >&2
   echo "${project}" >&2

   user_say_yes "Add \"${DEPENDENCY_SUBDIR}\" to search paths of ${projectname} ?"
   [ $? -eq 0 ] || exit 1

   check_for_mod_pbxproj

   configurations=`read_local_setting "configurations"`
   if [ "$configurations" = "" ]
   then
      configurations=`read_fetch_setting "configurations" "Debug
Release"`
   fi

   default=`echo "${configurations}" |  tail -1 | sed 's/^[ \t]*//;s/[ \t]*$//'`

   #
   # Add LIBRARY_CONFIGURATION mapping
   #
   xcode_configurations=`list_configurations "${project}"`
   if [ "$xcode_configurations" = "" ]
   then
      xcode_configurations="Debug
Release"
   fi

   #     012345678901234567890123456789012345678901234567890123456789
   echo "Settings added to ${projectname} and each contained target." >&2
   echo "You may want to delete the target settings, which have been" >&2
   echo "(redundantly) added by mod_pbxproj." >&2
   echo  "-----------------------------------------" >&2

   for i in ${xcode_configurations}
   do
      mapped=""

      for j in ${configurations}
      do
         if [ "$j" = "$i" ]
         then
            mapped="${i}"
         fi
      done

      if [ "$mapped" = "" ]
      then
      case i in
         *ebug*)
            mapped="Debug"
            ;;
         *rofile*)
            mapped="Release"
            ;;
         *eleas*)
            mapped="Release"
            ;;
         *)
            mapped="${default}"
            ;;
      esac
      fi

      python -m mod_pbxproj -b -af 'LIBRARY_CONFIGURATION='"${mapped}" "${project}" "${i}" || exit 1
      echo "${i}: LIBRARY_CONFIGURATION=${mapped}"
   done


   local dependencies_dir
   local header_search_paths
   local library_search_paths
   local framework_search_paths

   dependencies_dir='$(PROJECT_DIR)'"/${DEPENDENCY_SUBDIR}"

   header_search_paths="\$(DEPENDENCIES_DIR)${HEADER_PATH}"
   header_search_paths="${header_search_paths} /usr/local/include"

   library_search_paths="\$(DEPENDENCIES_DIR)${LIBRARY_PATH}/\$(LIBRARY_CONFIGURATION)\$(EFFECTIVE_PLATFORM_NAME)"
   library_search_paths="${library_search_paths} \$(DEPENDENCIES_DIR)${LIBRARY_PATH}/\$(LIBRARY_CONFIGURATION)"
   library_search_paths="${library_search_paths} \$(DEPENDENCIES_DIR)${LIBRARY_PATH}/${default}\$(EFFECTIVE_PLATFORM_NAME)"
   library_search_paths="${library_search_paths} \$(DEPENDENCIES_DIR)${LIBRARY_PATH}/${default}"
   library_search_paths="${library_search_paths} \$(DEPENDENCIES_DIR)${LIBRARY_PATH}"
   library_search_paths="${library_search_paths} /usr/local/lib"


   framework_search_paths="\$(DEPENDENCIES_DIR)${FRAMEWORK_PATH}/\$(LIBRARY_CONFIGURATION)\$(EFFECTIVE_PLATFORM_NAME)"
   framework_search_paths="${framework_search_paths} \$(DEPENDENCIES_DIR)${FRAMEWORK_PATH}/\$(LIBRARY_CONFIGURATION)"
   framework_search_paths="${framework_search_paths} \$(DEPENDENCIES_DIR)${FRAMEWORK_PATH}/${default}\$(EFFECTIVE_PLATFORM_NAME)"
   framework_search_paths="${framework_search_paths} \$(DEPENDENCIES_DIR)${FRAMEWORK_PATH}/${default}"
   framework_search_paths="${framework_search_paths} \$(DEPENDENCIES_DIR)${FRAMEWORK_PATH}"

   # in paths to the dependency folder into xcodeproj
   # add /usr/local/lib and /usr/local/include for brew stuff
   #
   python -m mod_pbxproj -b -af "DEPENDENCIES_DIR=${dependencies_dir}" "${project}" "All" || exit 1
   python -m mod_pbxproj -b -af "HEADER_SEARCH_PATHS=${header_search_paths}" "${project}" "All" || exit 1
   python -m mod_pbxproj -b -af "LIBRARY_SEARCH_PATHS=${library_search_paths}" "${project}" "All" || exit 1
   python -m mod_pbxproj -b -af "FRAMEWORK_SEARCH_PATHS=${framework_search_paths}" "${project}" "All" || exit 1

   prefix=`echo "${xcode_configurations}" | tr '\n' ',' `
   #     012345678901234567890123456789012345678901234567890123456789
   echo "${prefix}: DEPENDENCIES_DIR=${dependencies_dir}"
   echo "${prefix}: HEADER_SEARCH_PATHS=${header_search_paths}"
   echo "${prefix}: LIBRARY_SEARCH_PATHS=${library_search_paths}"
   echo "${prefix}: FRAMEWORK_SEARCH_PATHS=${framework_search_paths}"
   echo  "-----------------------------------------" >&2
   #     012345678901234567890123456789012345678901234567890123456789
   echo "" >&2
   echo "If you add a configuration to your project, rememeber to edit" >&2
   echo "the LIBRARY_CONFIGURATION setting for that configuration." >&2
   echo "" >&2
   echo "You can rerun setup-xcode at later times and it should not" >&2
   echo "unduly duplicate setting contents." >&2
   echo "" >&2
}

main()
{
   patch_xcode_project
}


main
