#! /bin/sh
#
# (c) 2015, coded by Nat!, Mulle KybernetiK
#
# this script patches the xcodeproj so that the headers and
# lib files can be added in a sensible order
#

. mulle-bootstrap-local-environment.sh


usage()
{
   cat <<EOF
xcode <add|remove>

   add      : add settings to Xcode project (default)
   remove   : remove settings from Xcode project
EOF
}


check_and_usage_and_help()
{
case "$COMMAND" in
   add)
   ;;
   remove)
   ;;
   *)
   usage >&2
   exit 1
   ;;
esac
}


COMMAND="${1:-add}"
shift

check_and_usage_and_help


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
   sed 's/^[ \t]*\(.*\)/\1/' | \
   sed '/^$/d'
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
      executor brew install python  || exit 1
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
      executor brew install python || exit 1
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
         executor sudo pip install --upgrade pip setuptools
         executor sudo pip install mod_pbxproj
      fi
   fi
}


map_configuration()
{
   local xcode_configuration
   local configurations
   local mapped
   local i

   configurations="$1"
   xcode_configuration="$2"

   mapped=""

   local old

   old="${IFS:-" "}"
   IFS="
"
   for i in ${configurations}
   do
      if [ "$i" = "$xcode_configuration" ]
      then
         mapped="${xcode_configuration}"
      fi
   done
   IFS="${old}"

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
   echo "${mapped}"
}




patch_library_configurations()
{
   local xcode_configurations
   local configurations
   local i
   local mapped

   xcode_configurations="$1"
   configurations="$2"
   project="$3"
   flag="$4"

   local old

   old="${IFS:-" "}"
   IFS="
"
   for i in ${xcode_configurations}
   do
      mapped=`map_configuration "${configurations}" "${i}"`
      if [ "${i}" = "Debug" -o "${i}" = "Release" ]
      then
         exekutor python -m mod_pbxproj -b "${flag}" 'LIBRARY_CONFIGURATION='"${mapped}" "${project}" "${i}" || exit 1
      else
         echo "${C_RED}You need to edit ${C_CYAN}LIBRARY_CONFIGURATION=${C_RED} \
for ${C_CYAN}$i${C_RED} manually, sorry${C_RESET}" 2>&1
      fi
   done
   IFS="${old}"
}


patch_xcode_project()
{
   local name
   local project
   local mapped
   local configurations
   local xcode_configurations

   name=`basename "${PWD}"`
   project=`find_xcodeproj "${name}"`
   if [ "${project}" = "" ]
   then
      fail "no xcodeproj found"
   fi

   projectname="`basename "${project}"`"

   # mod_pbxproj can only do Debug/Release/All...

   check_for_mod_pbxproj

   configurations=`read_build_root_setting "configurations" "Debug
Release"`

   default=`echo "${configurations}" | tail -1 | sed 's/^[ \t]*//;s/[ \t]*$//'`

   #
   # Add LIBRARY_CONFIGURATION mapping
   #
   xcode_configurations=`list_configurations "${project}"`
   if [ "$xcode_configurations" = "" ]
   then
      xcode_configurations="Debug
Release"
   fi

   local flag

   if [ "$COMMAND" = "add" ]
   then
      flag="-af"
      #     012345678901234567890123456789012345678901234567890123456789
      echo "${C_WHITE}Settings will be added to ${C_MAGENTA}${projectname}${C_WHITE} and each contained target." >&2
      echo "In the long term it may be more useful to copy/paste the following" >&2
      echo "xcconfig lines into local .xcconfig files.${C_RESET}" >&2
   else
      flag="-rf"
      #     012345678901234567890123456789012345678901234567890123456789
      echo "${C_WHITE}Settings will be removed from ${projectname} and each contained target." >&2
      echo "You may want to check afterwards, that this has worked out OK :).${C_RESET}" >&2
   fi

   local dependencies_dir
   local header_search_paths
   local library_search_paths
   local framework_search_paths

   #  figure out a way to make this nicer
   local absolute
   local absolute2
   local relative_subdir

   absolute="`realpath "${project}"`"
   absolute="`dirname "${absolute}"`"
   absolute2="`pwd -P`/${DEPENDENCY_SUBDIR}"
   relative_subdir="`relative_path_between "${absolute2}" "${absolute}" `"

   dependencies_dir='$(PROJECT_DIR)/'"${relative_subdir}"

   header_search_paths="\$(DEPENDENCIES_DIR)/${HEADER_DIR_NAME}"
   header_search_paths="${header_search_paths} /usr/local/include"
   header_search_paths="${header_search_paths} \$(inherited)"

   library_search_paths="\$(DEPENDENCIES_DIR)/${LIBRARY_DIR_NAME}/\$(LIBRARY_CONFIGURATION)\$(EFFECTIVE_PLATFORM_NAME)"
   library_search_paths="${library_search_paths} \$(DEPENDENCIES_DIR)/${LIBRARY_DIR_NAME}/\$(LIBRARY_CONFIGURATION)"
   library_search_paths="${library_search_paths} \$(DEPENDENCIES_DIR)/${LIBRARY_DIR_NAME}/${default}\$(EFFECTIVE_PLATFORM_NAME)"
   library_search_paths="${library_search_paths} \$(DEPENDENCIES_DIR)/${LIBRARY_DIR_NAME}/${default}"
   library_search_paths="${library_search_paths} \$(DEPENDENCIES_DIR)/${LIBRARY_DIR_NAME}"
   library_search_paths="${library_search_paths} /usr/local/lib"
   library_search_paths="${library_search_paths} \$(inherited)"


   framework_search_paths="\$(DEPENDENCIES_DIR)/${FRAMEWORK_DIR_NAME}/\$(LIBRARY_CONFIGURATION)\$(EFFECTIVE_PLATFORM_NAME)"
   framework_search_paths="${framework_search_paths} \$(DEPENDENCIES_DIR)/${FRAMEWORK_DIR_NAME}/\$(LIBRARY_CONFIGURATION)"
   framework_search_paths="${framework_search_paths} \$(DEPENDENCIES_DIR)/${FRAMEWORK_DIR_NAME}/${default}\$(EFFECTIVE_PLATFORM_NAME)"
   framework_search_paths="${framework_search_paths} \$(DEPENDENCIES_DIR)/${FRAMEWORK_DIR_NAME}/${default}"
   framework_search_paths="${framework_search_paths} \$(DEPENDENCIES_DIR)/${FRAMEWORK_DIR_NAME}"
   framework_search_paths="${framework_search_paths} \$(inherited)"

   local query

   if [ "$COMMAND" = "add" ]
   then

      local mapped
      local i

      echo  "${C_WHITE}-----------------------------------------------------------"  >&2

      #  make these echos easily grabable by stdout
      #     012345678901234567890123456789012345678901234567890123456789
      echo "// Common.xcconfig:"
      echo "DEPENDENCIES_DIR=${dependencies_dir}"
      echo "HEADER_SEARCH_PATHS=${header_search_paths}"
      echo "LIBRARY_SEARCH_PATHS=${library_search_paths}"
      echo "FRAMEWORK_SEARCH_PATHS=${framework_search_paths}"

   local old

   old="${IFS:-" "}"
   IFS="
"
      for i in ${xcode_configurations}
      do
         echo ""
         echo ""
         mapped=`map_configuration "${configurations}" "${i}"`
         #     012345678901234567890123456789012345678901234567890123456789
         echo "// ${i}.xcconfig:"
         echo "#include \"Common.xcconfig\""
         echo "LIBRARY_CONFIGURATION=${mapped}"
      done
      IFS="${old}"
      echo  "-----------------------------------------------------------${C_RESET}"  >&2

      query="Add ${C_CYAN}\"${DEPENDENCY_SUBDIR}/${LIBRARY_DIR_NAME}\"${C_YELLOW}  and friends to search paths of ${C_MAGENTA}${projectname}${C_YELLOW} ?"
   else
      query="Remove ${C_CYAN}\"${DEPENDENCY_SUBDIR}/${LIBRARY_DIR_NAME}\"${C_YELLOW}  and friends from search paths of ${C_MAGENTA}${projectname}${C_YELLOW} ?"
   fi

   user_say_yes "$query"
   [ $? -eq 0 ] || exit 1


   patch_library_configurations "${xcode_configurations}" "${configurations}" "${project}" "${flag}"

   exekutor python -m mod_pbxproj -b "${flag}" "DEPENDENCIES_DIR=${dependencies_dir}" "${project}" "All" || exit 1
   exekutor python -m mod_pbxproj -b "${flag}" "HEADER_SEARCH_PATHS=${header_search_paths}" "${project}" "All" || exit 1
   exekutor python -m mod_pbxproj -b "${flag}" "LIBRARY_SEARCH_PATHS=${library_search_paths}" "${project}" "All" || exit 1
   exekutor python -m mod_pbxproj -b "${flag}" "FRAMEWORK_SEARCH_PATHS=${framework_search_paths}" "${project}" "All" || exit 1


   if [ "$COMMAND" = "add" ]
   then
      #     012345678901234567890123456789012345678901234567890123456789
      echo "${C_WHITE}"
      echo "Hint:"
      echo "You may want to delete the target settings, which have been" >&2
      echo "(redundantly) added by mod_pbxproj. The project settings suffice." >&2
      echo "" >&2
      echo "If you add a configuration to your project, remember to edit" >&2
      echo "the LIBRARY_CONFIGURATION setting for that configuration." >&2
      echo "" >&2
      echo "You can rerun setup-xcode at later times and it should not" >&2
      echo "unduly duplicate setting contents." >&2
      echo "${C_RESET}" >&2
   fi
}

main()
{
   log_fluff "::: xcode :::"

   patch_xcode_project "$@"
}


main "$@"

