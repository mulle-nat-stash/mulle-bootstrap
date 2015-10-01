#! /bin/sh
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.

.  mulle-bootstrap-local-environment.sh
.  mulle-bootstrap-gcc.sh


check_and_usage_and_help()
{
   cat <<EOF
usage: build [repos]*
   You can specify the names of the repositories to build.
   Currently available names are:
EOF
   (cd "${CLONES_SUBDIR}" ; ls -1d ) 2> /dev/null
}


if [ "$1" = "-h" -o "$1" = "--help" ]
then
   check_and_usage_and_help >&2
   exit 1
fi


CLEAN_BEFORE_BUILD=`read_config_setting "clean_before_build"`
HEADER_PATH=`read_config_setting "header_path" "/include"`
LIBRARY_PATH=`read_config_setting "library_path" "/lib"`
FRAMEWORK_PATH=`read_config_setting "framework_path" "/Frameworks"`

#
# move stuff produced my cmake and configure to places
# where we expect them. Expect  others to build to
# <prefix>/include  and <prefix>/lib or <prefix>/Frameworks
#
dispense_headers()
{
   local  src

   src="$1"

   local dst
   local usrlocal

   log_fluff "Considering copying ${src}"

   if [ -d "${src}" ]
   then
      if dir_has_files "${src}"
      then
         usrlocal="`read_build_setting "headers_c_and_d_prefix" "/usr/local"`"

         dst="${REFERENCE_DEPENDENCY_SUBDIR}${usrlocal}${HEADER_PATH}"
         mkdir_if_missing "${REFERENCE_DEPENDENCY_SUBDIR}${usrlocal}${HEADER_PATH}"

         log_fluff "Copying ${src} to ${dst}"
         exekutor find -x "${src}" ! -path "${src}" -depth 1 -type d -print0 | \
            exekutor xargs -0 -J % mv -v -n % "${dst}"
         [ $? -eq 0 ]  || exit 1
         exekutor find -x "${src}" ! -path "${src}" -depth 1 -type f -print0 | \
            exekutor xargs -0 -J % mv -v -n % "${dst}"
         [ $? -eq 0 ]  || exit 1
         rmdir_safer "${src}"
      fi
   fi
}


dispense_binaries()
{
   local src

   src="$1"
   findtype="$2"
   subpath="$3"

   local dst
   local usrlocal

   log_fluff "Considering copying ${src}"

   if [ -d "${src}" ]
   then
      if dir_has_files "${src}"
      then
         dst="${REFERENCE_DEPENDENCY_SUBDIR}${subpath}${subdir}"

         log_fluff "Copying ${src} to ${dst}"
         mkdir_if_missing "${dst}"
         exekutor find -x "${src}" ! -path "${src}" -type "${findtype}" -depth 1 -print0 | \
            exekutor xargs -0 -J % mv -v -n % "${dst}"
         [ $? -eq 0 ]  || exit 1
      fi
      rmdir_safer "${src}"
   fi
}


collect_and_dispense_product()
{
   local  subdir
   local  dst
   local  src

   subdir="$1"
   wasxcode="$2"

   log_fluff "Start collecting and dispensing product"
   #
   # probably should use install_name_tool to hack all dylib paths that contain .ref
   # (will this work with signing stuff ?)
   #
   if [ "${wasxcode}" = "YES" ]
   then
      log_fluff "Choosing xcode dispense path"

      src="${BUILD_DEPENDENCY_SUBDIR}/usr/local/include"
      dispense_headers "${src}"

      src="${BUILD_DEPENDENCY_SUBDIR}/usr/include"
      dispense_headers "${src}"

      src="${BUILD_DEPENDENCY_SUBDIR}/include"
      dispense_headers "${src}"

      src="${BUILD_DEPENDENCY_SUBDIR}/lib${subdir}"
      dispense_binaries "${src}" "f" "${LIBRARY_PATH}"

      src="${BUILD_DEPENDENCY_SUBDIR}/Frameworks${subdir}"
      dispense_binaries "${src}" "d" "${FRAMEWORK_PATH}"
   else
      log_fluff "Choosing cmake/configure dispense path"

      src="${BUILD_DEPENDENCY_SUBDIR}/usr/local/include"
      dispense_headers "${src}"

      src="${BUILD_DEPENDENCY_SUBDIR}/usr/local/lib"
      dispense_binaries "${src}" "f" "${LIBRARY_PATH}"

      # coming from Cmake and configure
      src="${BUILD_DEPENDENCY_SUBDIR}/usr/local/Frameworks"
      dispense_binaries "${src}" "d" "${FRAMEWORK_PATH}"
   fi

   #
   # Delete empty dirs if so
   #
   src="${BUILD_DEPENDENCY_SUBDIR}/usr/local"
   dir_has_files "${src}"
   if [ $? -ne 0 ]
   then
      rmdir_safer "${src}"
   fi

   src="${BUILD_DEPENDENCY_SUBDIR}/usr"
   dir_has_files "${src}"
   if [ $? -ne 0 ]
   then
      rmdir_safer "${src}"
   fi

   #
   # probably should hack all executables with install_name_tool that contain .ref
   #
   # now copy over the rest of the output
   usrlocal="`read_build_setting "others_c_and_d_prefix" "/usr/local"`"

   log_fluff "Considering copying ${BUILD_DEPENDENCY_SUBDIR}/*"

   src="${BUILD_DEPENDENCY_SUBDIR}"
   if [ "${wasxcode}" = "YES" ]
   then
      src="${src}${subdir}"
   fi

   if dir_has_files "${src}"
   then
      dst="${REFERENCE_DEPENDENCY_SUBDIR}${usrlocal}"

      log_fluff "Copying ${src}/* to ${dst}"
      exekutor find -x "${src}" ! -path "${src}" -depth 1 -exec mv -v -n '{}' "${dst}" | \
            exekutor xargs -0 -J % mv -v -n % "${dst}"
      [ $? -eq 0 ]  || exit 1
   fi

   if [ "$MULLE_BOOTSTRAP_VERBOSE" = "YES"  ]
   then
      if dir_has_files "${BUILD_DEPENDENCY_SUBDIR}"
      then
         log_fluff "${BUILD_DEPENDENCY_SUBDIR} contained files after collect and dispense"
         log_fluff "--------------------"
         ( cd "${BUILD_DEPENDENCY_SUBDIR}" ; ls -R >&2 )
         log_fluff "--------------------"
      fi
   fi

   rmdir_safer "${BUILD_DEPENDENCY_SUBDIR}"

   log_fluff "Done collecting and dispensing product"
   log_fluff
}


enforce_build_sanity()
{
   local builddir

   builddir="$1"

   # these must not exist
   if [ -d "${BUILD_DEPENDENCY_SUBDIR}" ]
   then
      fail "A previous build left ${BUILD_DEPENDENCY_SUBDIR} can't continue"
   fi

   if [ -d "${builddir}" -a "${CLEAN_BEFORE_BUILD}" != "" ]
   then
      rmdir_safer "${builddir}"
   fi
}


determine_suffix()
{
   local configuration
   local sdk
   local suffix
   local hackish

   configuration="$1"
   sdk="$2"

   [ ! -z "$configuration" ] || fail "configuration must not be empty"
   [ ! -z "$sdk" ] || fail "sdk must not be empty"

   suffix="/${configuration}"
   if [ "${sdk}" != "Default" ]
   then
      hackish=`echo "${sdk}" | sed 's/^\([a-zA-Z]*\).*$/\1/g'`
      suffix="${suffix}-${hackish}"
   fi
   echo "${suffix}"
}


cmake_sdk_parameter()
{
   local sdkpath

   sdkpath=`gcc_sdk_parameter "$1"`
   if [ "${sdkpath}" != "" ]
   then
      echo '-DCMAKE_OSX_SYSROOT='"${sdkpath}"
   fi
}

#
# remove old builddir, create a new one
# depending on configuration cmake with flags
# build stuff into dependencies
#
#
build_cmake()
{
   local configuration
   local srcdir
   local builddir
   local relative
   local name
   local sdk
   local mapped

   configuration="$1"
   srcdir="$2"
   builddir="$3"
   relative="$4"
   name="$5"
   sdk="$6"

   enforce_build_sanity "${builddir}"

   log_info "Do a cmake ${C_MAGENTA}${configuration}${C_INFO} build of \
${C_MAGENTA}${name}${C_INFO} for SDK ${C_MAGENTA}${sdk}${C_INFO} ..."

   mapped=`read_build_setting "$name" "cmake-${configuration}.map" "${configuration}"`
   suffix=`determine_suffix "${configuration}" "${sdk}"`
   sdk=`cmake_sdk_parameter "${sdk}"`

   local other_cflags
   local other_cppflags
   local other_ldflags

   other_cflags=`gcc_cflags_value "${name}"`
   other_cppflags=`gcc_cppflags_value "${name}"`
   other_ldflags=`gcc_ldflags_value "${name}"`

   owd="${PWD}"
   # to avoid warning make sure directories are all there
   # TODO: I DONT LIKE THIS
   [ ! -e "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}" ]  &&  \
      mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}"
   [ ! -e "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}" ]  &&  \
      mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}"
   [ ! -e "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}" ]  &&  \
      mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}"

   mkdir_if_missing "${builddir}"
   exekutor cd "${builddir}" || exit 1

      # check that relative ise right
      exekutor [ -d "${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}" ] || exit 1
      exekutor [ -d "${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}" ] || exit 1
      exekutor [ -d "${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" ] || exit 1

      #
      # cmake doesn't seem to "get" CMAKE_CXX_FLAGS or -INCLUDE
      #
      set -f

      exekutor cmake "-DCMAKE_BUILD_TYPE=${mapped}" \
"-DCMAKE_INSTALL_PREFIX:PATH=${owd}/${BUILD_DEPENDENCY_SUBDIR}/usr/local"  \
"-DCMAKE_C_FLAGS=\
-I${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${other_cflags} \
${sdk}" \
"-DCMAKE_CXX_FLAGS=\
-I${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${other_cppflags} \
${sdk}" \
"-DCMAKE_LD_FLAGS=\
-L${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${LIBRARY_PATH}${suffix} \
-L${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${configuration} \
-L${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${LIBRARY_PATH} \
-F${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${other_ldflags} \
${sdk}" \
"${relative}/${srcdir}" 1>&2  || exit 1

      exekutor make all install 1>&2 || exit 1

      set +f

   exekutor cd "${owd}"

   collect_and_dispense_product "${suffix}" || exit 1
}


#
# remove old builddir, create a new one
# depending on configuration cmake with flags
# build stuff into dependencies
#
#
build_configure()
{
   local configuration
   local srcdir
   local builddir
   local relative
   local name
   local sdk
   local mapped

   configuration="$1"
   srcdir="$2"
   builddir="$3"
   relative="$4"
   name="$5"
   sdk="$6"

   enforce_build_sanity "${builddir}"

   log_info "Do a configure ${C_MAGENTA}${configuration}${C_INFO} build of \
${C_MAGENTA}${name}${C_INFO} for SDK ${C_MAGENTA}${sdk}${C_INFO} ..."


   mapped=`read_build_setting "$name" "configure-${configuration}.map" "${configuration}"`
   suffix=`determine_suffix "${configuration}" "${sdk}"`
   sdk=`gcc_sdk_parameter "${sdk}"`

   local other_cflags
   local other_cppflags
   local other_ldflags

   other_cflags=`gcc_cflags_value "${name}"`
   other_cppflags=`gcc_cppflags_value "${name}"`
   other_ldflags=`gcc_ldflags_value "${name}"`

   owd="${PWD}"
   # to avoid warnings make sure directories are all there
   [ ! -e "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}" ]  &&  \
      mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}"
   [ ! -e "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}" ]  &&  \
      mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}"
   [ ! -e "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}" ]  &&  \
      mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}"

   mkdir_if_missing "${builddir}" 2> /dev/null
   exekutor cd "${builddir}" || exit 1

      # check that relative is right
      exekutor [ -d "${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}" ] || exit 1
      exekutor [ -d "${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}" ] || exit 1
      exekutor [ -d "${relative}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" ] || exit 1

      set -f

      # use absolute paths for configure, safer (and easier to read IMO)
      CFLAGS="\
-I${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${other_cflags} \
${sdk}" \
      CPPFLAGS="\
-I${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${other_cppflags} \
${sdk}" \
      LDFLAGS="\
-F${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
-L${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${LIBRARY_PATH}${suffix} \
-L${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${configuration} \
-L${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${LIBRARY_PATH} \
${other_ldflags} \
${sdk}" \
      exekutor "${owd}/${srcdir}/configure" --prefix "${owd}/${BUILD_DEPENDENCY_SUBDIR}/usr/local" 1>&2  || exit 1

      exekutor make all install 1>&2 || exit 1

      set +f

   exekutor cd "${owd}"

   collect_and_dispense_product "${suffix}" || exit 1
}


xcode_get_setting()
{
   local key

   key="$1"
   shift

   eval "xcodebuild -showBuildSettings $*" | \
   egrep "^[ ]*${key}" | \
   sed 's/^[^=]*=[ ]*\(.*\)/\1/' || \
   exit 1
}


#
# Code I didn't want to throw away really
# In general just uss "public_headers" or
# "private_headers" and set them to a /usr/local/include/whatever
#
create_mangled_header_path()
{
   local name
   local key
   local default

   key="$1"
   name="$2"
   default="$3"

   local headers
   local prefix

   headers=`xcode_get_setting "${key}" $*`
   log_fluff "${key} read as \"${headers}\""

   case "${headers}" in
      /*)
      ;;

      ./*|../*)
         log_warning "relative path \"${headers}\" as header path ???"
      ;;

      "")
         headers="${default}"
      ;;

      *)
         headers="/${headers}"
      ;;
   esac

   prefix=""
   read_yes_no_build_setting "${name}" "xcode_mangle_include_prefix"
   if [ $? -ne 0 ]
   then
      headers="`remove_absolute_path_prefix_up_to "${headers}" "include"`"
      prefix="${HEADER_PATH}"
   fi

   if read_yes_no_build_setting "${name}" "xcode_mangle_header_dash"
   then
      headers="`echo "${headers}" | tr '-' '_'`"
   fi

   echo "${headers}"
}


fixup_header_path()
{
   local key
   local setting_key
   local default
   local name
   local prefix

   key="$1"
   shift
   setting_key="$1"
   shift
   name="$1"
   shift
   default="$1"
   shift

   headers="`read_repo_setting "${name}" "${setting_key}"`"
   if [ "$headers" = "" ]
   then
      read_yes_no_build_setting "${name}" "xcode_mangle_header_settings"
      if [ $? -ne 0 ]
      then
         return 1
      fi

      headers="`create_mangled_header_path "${key}" "${name}" "${default}"`"
   fi

   log_fluff "${key} set to \"${headers}\""

   echo "${headers}"
}


escaped_spaces()
{
   echo "$1" | sed 's/ /\\ /g'
}


combined_escaped_search_path()
{
   for i in "$@"
   do
      if [ ! -z "$i" ]
      then
         i="`escaped_spaces "$i"`"
         if [ -z "$path" ]
         then
            path="$i"
         else
            path="$path $i"
         fi
      fi
   done

   echo "${path}"
}


build_xcodebuild()
{
   local configuration
   local srcdir
   local builddir
   local relative
   local name
   local sdk
   local project
   local schemename
   local targetname

   configuration="$1"
   srcdir="$2"
   builddir="$3"
   relative="$4"
   name="$5"
   sdk="$6"
   project="$7"
   schemename="$8"
   targetname="$9"

   [ -z "${configuration}" ] && internal_fail "configuration is empty"
   [ -z "${srcdir}" ]      && internal_fail "srcdir is empty"
   [ -z "${builddir}" ]    && internal_fail "builddir is empty"
   [ -z "${relative}" ]    && internal_fail "relative is empty"
   [ -z "${name}" ]        && internal_fail "name is empty"
   [ -z "${sdk}" ]         && internal_fail "sdk is empty"
   [ -z "${project}" ]     && internal_fail "project is empty"

   enforce_build_sanity "${builddir}"

   local info

   info=""
   if [ ! -z "${targetname}" ]
   then
      info="Target ${C_MAGENTA}${targetname}${C_FLUFF}"
   fi

   if [ ! -z "${schemename}" ]
   then
      info="Scheme ${C_MAGENTA}${schemename}${C_FLUFF}"
   fi

   log_info "Do a xcodebuild ${C_MAGENTA}${configuration}${C_FLUFF} of \
${C_MAGENTA}${name}${C_FLUFF} for SDK ${C_MAGENTA}${sdk}${C_FLUFF} \
${info} ..."

   local projectname

    # always pass project directly
   projectname=`read_repo_setting "${name}" "project" "${project}"`

   local mapped

   mapped=`read_build_setting "${name}" "${configuration}.map" "${configuration}"`
   [ -z "${mapped}" ] && internal_fail "mapped configuration is empty"

   local hackish
   local targetname
   local suffix

   suffix="/${configuration}"
   if [ "${sdk}" != "Default" ]
   then
      hackish=`echo "${sdk}" | sed 's/^\([a-zA-Z]*\).*$/\1/g'`
      suffix="${suffix}-${hackish}"
   else
      sdk=
   fi

   local proper_skip_install
   local skip_install

   skip_install=
   proper_skip_install=`read_build_setting "${name}" "proper_skip_install" "NO"`
   if [ "$proper_skip_install" != "YES" ]
   then
      skip_install="SKIP_INSTALL=NO"
   fi

   local xcodebuild
   local binary

   xcodebuild=`read_config_setting "xcodebuild" "xcodebuild"`
   binary=`which "${xcodebuild}"`
   if [ "${binary}"  = "" ]
   then
      echo "${xcodebuild} is an unknown build tool" >& 2
      exit 1
   fi


   #
   # xctool needs schemes, these are often autocreated, which xctool cant do
   # xcodebuild can just use a target
   # xctool is by and large useless fluff IMO
   #
   if [ "$xcodebuild" = "xctool"  -a "${schemename}" = ""  ]
   then
      if [ "$targetname" != "" ]
      then
         schemename="${targetname}"
         targetname=
      else
         echo "Please specify a scheme to compile in ${BOOTSTRAP_SUBDIR}/${name}/SCHEME for xctool" >& 2
         echo "and be sure that this scheme exists and is shared." >& 2
         echo "Or just delete ${HOME}/.mulle-bootstrap/xcodebuild and use xcodebuild (preferred)" >& 2
         exit 1
      fi
   fi

   local key
   local aux
   local value
   local keys

   aux=
   keys=`all_build_flag_keys "${name}"`
   for key in ${keys}
   do
      value=`read_build_setting "${name}" "${key}"`
      aux="${aux} ${key}=${value}"
   done

   # now don't load any settings anymoe
   local owd
   local command

   if [ "$MULLE_BOOTSTRAP_DRY" != "" ]
   then
      command=-showBuildSettings
   else
      command=install
   fi

      #
      # headers are complicated, the preference is to get it uniform into
      # dependencies/include/libraryname/..
      #

   local public_headers
   local private_headers
   local default

   default="/include/${name}"
   public_headers="`fixup_header_path "PUBLIC_HEADERS_FOLDER_PATH" "public_headers" "${name}" "${default}" ${arguments}`"
   default="/include/${name}/private"
   private_headers="`fixup_header_path "PRIVATE_HEADERS_FOLDER_PATH" "private_headers" "${name}" "${default}" ${arguments}`"

   owd=`pwd`
   cd "${srcdir}" || exit 1

      set -f

      arguments=""
      if [ ! -z "${projectname}" ]
      then
         arguments="${arguments} -project \"${projectname}\""
      fi
      if [ ! -z "${sdk}" ]
      then
         arguments="${arguments} -sdk \"${sdk}\""
      fi
      if [ ! -z "${schemename}" ]
      then
         arguments="${arguments} -scheme \"${schemename}\""
      fi
      if [ ! -z "${targetname}" ]
      then
         arguments="${arguments} -target \"${targetname}\""
      fi
      if [ ! -z "${mapped}" ]
      then
         arguments="${arguments} -configuration \"${mapped}\""
      fi


      # manually point xcode to our headers and libs
      # this is like manually doing xcode-setup
      local dependencies_framework_search_path
      local dependencies_header_search_path
      local dependencies_lib_search_path
      local inherited
      local path
      local escaped

      #
      # TODO: need to figure out the correct mapping here
      #
      inherited="`xcode_get_setting HEADER_SEARCH_PATHS ${arguments}`"
      path=`combined_escaped_search_path \
"${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${HEADER_PATH}" \
"/usr/local/include"`
      if [ -z "${inherited}" ]
      then
         dependencies_header_search_path="${path}"
      else
         dependencies_header_search_path="${path} ${inherited}"
      fi

      inherited="`xcode_get_setting LIBRARY_SEARCH_PATHS ${arguments}`"
      path=`combined_escaped_search_path \
"${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${mapped}" \
"${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${LIBRARY_PATH}" \
"/usr/local/lib"`
      if [ ! -z "$sdk" ]
      then
         escaped="`escaped_spaces "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${mapped}"'-$(EFFECTIVE_PLATFORM_NAME)'`"
         path="${escaped} ${path}" # prepend
      fi
      if [ -z "${inherited}" ]
      then
         dependencies_lib_search_path="${path}"
      else
         dependencies_lib_search_path="${path} ${inherited}"
      fi


      inherited="`xcode_get_setting FRAMEWORK_SEARCH_PATHS ${arguments}`"
      path=`combined_escaped_search_path \
"${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mapped}" \
"${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}"`
      if [ ! -z "$sdk" ]
      then
         escaped="`escaped_spaces "${owd}/${REFERENCE_DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mapped}"'-$(EFFECTIVE_PLATFORM_NAME)'`"
         path="${escaped} ${path}" # prepend
      fi
      if [ -z "${inherited}" ]
      then
         dependencies_framework_search_path="${path}"
      else
         dependencies_framework_search_path="${path} ${inherited}"
      fi

      if [ ! -z "${public_headers}" ]
      then
         arguments="${arguments} PUBLIC_HEADERS_FOLDER_PATH='${public_headers}'"
      fi
      if [ ! -z "${private_headers}" ]
      then
         arguments="${arguments} PRIVATE_HEADERS_FOLDER_PATH='${private_headers}'"
      fi


      # if it doesn't install, probably SKIP_INSTALL is set
      cmdline="\"${xcodebuild}\" \"${command}\" ${arguments} \
ARCHS='\${ARCHS_STANDARD_32_64_BIT}' \
DEPLOYMENT_LOCATION=YES \
DSTROOT='${owd}/${BUILD_DEPENDENCY_SUBDIR}' \
INSTALL_PATH='${LIBRARY_PATH}${suffix}' \
SYMROOT='${owd}/${builddir}/' \
OBJROOT='${owd}/${builddir}/obj' \
ONLY_ACTIVE_ARCH=NO \
${skip_install} \
HEADER_SEARCH_PATHS='${dependencies_header_search_path}' \
LIBRARY_SEARCH_PATHS='${dependencies_lib_search_path}' \
FRAMEWORK_SEARCH_PATHS='${dependencies_framework_search_path}'"

      eval_exekutor "${cmdline}" 1>&2 || exit 1

      set +f

   cd "${owd}"

   collect_and_dispense_product "${suffix}" "YES" || exit 1
}


build_xcodebuild_schemes_or_target()
{
   local builddir
   local name
   local project

   builddir="$3"
   name="$5"
   project="$7"

   if [ -d "${builddir}" -a "${CLEAN_BEFORE_BUILD}" != "" ]
   then
      rmdir_safer "${builddir}"
   fi

   local scheme
   local schemes

   schemes=`read_repo_setting "${name}" "schemes"`

   local old

   old="${IFS:-" "}"
   IFS="
"
   for scheme in $schemes
   do
      IFS="$old"
      log_fluff "Building scheme \"${scheme}\" of \"${project}\" ..."
      build_xcodebuild "$@" "${scheme}" ""
   done
   IFS="${old}"

   local target
   local targets

   targets=`read_repo_setting "${name}" "targets"`

   old="$IFS"
   IFS="
"
   for target in $targets
   do
      IFS="${old}"
      log_fluff "Building target \"${target}\" of \"${project}\" ..."
      build_xcodebuild "$@" "" "${target}"
   done
   IFS="${old}"

   if [ "${targets}" = "" -a "${schemes}" = "" ]
   then
      log_fluff "Building project \"${project}\"..."
      build_xcodebuild "$@"
   fi
}



build()
{
   local srcdir

   srcdir="$1"

   local name

   name=`basename "${srcdir}"`
   [ "${name}" != "${CLONES_SUBDIR}" ] || internal_fail "missing repo argument (${srcdir})"

   local preferences
   local configurations

   preferences=`read_config_setting "preferences" "script
xcodebuild
cmake
configure"`

   configurations=`read_build_root_setting "configurations" "Debug
Release"`

   local xcodebuild
   local cmake

   xcodebuild=`which "xcodebuild"`
   cmake=`which "cmake"`

   local sdk
   local sdks

   # need uniform SDK for our builds
   sdks=`read_build_root_setting "sdks" "Default"`
   [ ! -z "${sdks}" ] || fail "setting \"sdks\" must at least contain \"Default\" to build anything"

   local builddir
   local relative
   local built
   local configuration
   local preference

   for sdk in ${sdks}
   do
      for configuration in ${configurations}
      do
         if [ "$/{configuration}" = "${LIBRARY_PATH}" -o "/${configuration}" = "${HEADER_PATH}" -o "/${configuration}" = "${FRAMEWORK_PATH}" ]
         then
            fail "You are just asking for trouble."
         fi

         if [ "${configuration}" = "lib" -o "${configuration}" = "include" -o "${configuration}" = "Frameworks" ]
         then
            fail "You are just asking for major trouble."
         fi

         builddir="${CLONESBUILD_SUBDIR}/${configuration}/${name}"
         relative="${CLONESBUILD_RELATIVE}/../.."

         built=no
         for preference in ${preferences}
         do
            if [ -x "${SCRIPT}" -a "${preference}" = "script" ]
            then
               "${SCRIPT}" "${configuration}" "${srcdir}" "${builddir}" "${relative}" "${name}" "${sdk}" || exit 1
               built=yes
               break
            fi

            if [ "${preference}" = "xcodebuild" -a -x "${xcodebuild}" ]
            then
               project=`(cd "${srcdir}" ; find_xcodeproj "${name}")`

               if [ "$project" != "" ]
               then
                  build_xcodebuild_schemes_or_target "${configuration}" "${srcdir}" "${builddir}" "${relative}" "${name}" "${sdk}" "${project}"  || exit 1
                  built=yes
                  break
               fi
            fi

            if [ "${preference}" = "configure"  ]
            then
               if [ ! -f "${srcdir}/configure"  ]
               then
                  # try for autogen if installed (not coded yet)
                  :
               fi
               if [ -x "${srcdir}/configure" ]
               then
                  build_configure "${configuration}" "${srcdir}" "${builddir}" "${relative}" "${name}" "${sdk}"  || exit 1
                  built=yes
                  break
               fi
            fi

            if [ "${preference}" = "cmake" -a -x "${cmake}" ]
            then
               if [ -f "${srcdir}/CMakeLists.txt" ]
               then
                  build_cmake "${configuration}" "${srcdir}" "${builddir}" "${relative}" "${name}" "${sdk}"  || exit 1
                  built=yes
                  break
               fi
            fi
         done

         if [ "$built" != "yes" ]
         then
            fail "Don't know how to build ${name}"
         fi
      done
   done
}


#
# ${DEPENDENCY_SUBDIR} is split into
#
#  REFERENCE_DEPENDENCY_SUBDIR and
#  BUILD_DEPENDENCY_SUBDIR
#
# above this function, noone should access ${DEPENDENCY_SUBDIR}
#
build_wrapper()
{
   local clone

   clone="$1"

   REFERENCE_DEPENDENCY_SUBDIR="${DEPENDENCY_SUBDIR}"
   BUILD_DEPENDENCY_SUBDIR="${DEPENDENCY_SUBDIR}/tmp"

   DEPENDENCY_SUBDIR="WRONG_DONT_USE_DEPENDENCY_SUBDIR_DURING_BUILD"

   if [ -d "${BUILD_DEPENDENCY_SUBDIR}" ]
   then
      log_info "Cleaning up orphaned \"${BUILD_DEPENDENCY_SUBDIR}\""
      rmdir_safer "${BUILD_DEPENDENCY_SUBDIR}"
   fi

   #
   # move dependencies we have so far away into safety,
   # need that path for includes though
   #
   log_fluff "Setting up \"${BUILD_DEPENDENCY_SUBDIR}\""

   build "${clone}"

   log_fluff "Remove \"${BUILD_DEPENDENCY_SUBDIR}\""

   rmdir_safer "${BUILD_DEPENDENCY_SUBDIR}"

   DEPENDENCY_SUBDIR="${REFERENCE_DEPENDENCY_SUBDIR}"

   REFERENCE_DEPENDENCY_SUBDIR="WRONG_DONT_USE_REFERENCE_DEPENDENCY_SUBDIR_AFTER_BUILD"
   BUILD_DEPENDENCY_SUBDIR="WRONG_DONT_USE_BUILD_DEPENDENCY_SUBDIR_AFTER_BUILD"
}


build_if_readable()
{
   local clone
   local name
   local xdone

   clone="$1"
   name="$2"
   built="$3"

   if [ ! -r "${clone}" ]
   then
      echo "ignoring orphaned repo ${name}" >&2
   else
      xdone=`/bin/echo "${built}" | grep "${name}"`
      if [ "$xdone" = "" ]
      then
         build_wrapper "${clone}"
         echo "${name}
${built}"
      fi
   fi
}


build_clones()
{
   local clone
   local built
   local xdone
   local name

   for clone in ${CLONES_SUBDIR}/*.failed
   do
      if [ -d "${clone}" ]
      then
         fail "failed checkout $clone detected, can't continue"
      fi
   done

   #
   # build order is there, because we want to have gits
   # and maybe later hgs
   #
   if [ "$#" -eq 0 ]
   then
      built=`read_build_root_setting "buildignore"`

      for name in `read_build_root_setting "buildorder"`
      do
         clone="${CLONES_SUBDIR}/${name}"

         if [ -d "${clone}" ]
         then
            built=`build_if_readable "${clone}" "${name}" "${built}"`
            [ $? -eq 0 ] || exit 1
         else
            fail "buildorder contains unknown repo ${name}"
         fi
      done

      for clone in "${CLONES_SUBDIR}"/*
      do
         name=`basename "${clone}"`

         if [ -d "${clone}" ]
         then
            built=`build_if_readable "${clone}" "${name}" "${built}"`
            [ $? -eq 0 ] || exit 1
         fi
      done
   else
      for name in "$@"
      do
         clone="${CLONES_SUBDIR}/${name}"

         if [ -d "${clone}" ]
         then
            built=`build_if_readable "${clone}" "${name}" "${built}"`
            [ $? -eq 0 ] || exit 1
         else
            fail "unknown repo ${name}"
         fi
      done
   fi
}


install_tars()
{
   local tarballs
   local tar


   tarballs=`read_fetch_setting "tarballs" | sort | sort -u`
   if [ "${tarballs}" != "" ]
   then
      local old

      old="${IFS:-" "}"
      IFS="
"
      for tar in ${tarballs}
      do
         if [ ! -f "$tar" ]
         then
            fail "tarball \"$tar\" not found"
         else
            log_info "Installing tarball \"${tar}\""
            exekutor tar -xz -C "${DEPENDENCY_SUBDIR}" -f "${tar}" || fail "failed to extract ${tar}"
         fi
      done
      IFS="${old}"
   fi
}


main()
{
   local  no_clean

   log_info "Start build"

   log_fluff "Setting up ${DEPENDENCY_SUBDIR}"
   no_clean="`read_config_setting "dont_clean_dependencies_before_build"`"
   if [ "${no_clean}" != "YES" ]
   then
      rmdir_safer "${DEPENDENCY_SUBDIR}"
   fi


   #
   # START
   #
   if [ ! -d "${CLONES_SUBDIR}" ]
   then
      log_info "No repos fetched, nothing to do."
      return 0
   fi

   # if present then we didnt't want to clean and we do nothing special
   if [ ! -d "${DEPENDENCY_SUBDIR}" ]
   then
      mkdir_if_missing "${DEPENDENCY_SUBDIR}/usr/local/include"
      exekutor ln -s "usr/local/include" "${DEPENDENCY_SUBDIR}/include" || fail "failed to symlink future usr/local/include"
      install_tars "$@"
   fi

   build_clones "$@"
}

main "$@"
