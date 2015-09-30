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


CLEAN_BEFORE_BUILD=`read_config_setting "clean_before_build"`
HEADER_PATH=`read_config_setting "header_path" "/include"`
LIBRARY_PATH=`read_config_setting "library_path" "/lib"`
FRAMEWORK_PATH=`read_config_setting "framework_path" "/Frameworks"`

#
# move stuff produced my cmake and configure to places
# where we expect them. Expect  others to build to
# <prefix>/include  and <prefix>/lib or <prefix>/Frameworks
#
collect_and_dispense_product()
{
   local  subdir
   local  dst
   local  src

   output="$1"
   subdir="$2"

   src="${output}/include"
   if [ -d "${src}" ]
   then
      if dir_has_files "${src}"
      then
         dst="${DEPENDENCY_SUBDIR}${HEADER_PATH}"
         exekutor mkdir -p "${dst}" 2> /dev/null
         exekutor find -x "${src}" ! -path "${src}" -depth 1 -type d -exec mv -v -n '{}' "${dst}" \;  2> /dev/null
         exekutor find -x  "${src}" ! -path "${src}" -depth 1 -type f -exec mv -v -n '{}' "${dst}" \;  2> /dev/null
      fi
      exekutor rm -rf "${src}"
   fi

   src="${output}/lib"
   if [ -d  "${src}" ]
   then
      if dir_has_files "${src}"
      then
         dst="${DEPENDENCY_SUBDIR}${LIBRARY_PATH}${subdir}"
         exekutor mkdir -p "${dst}" 2> /dev/null
         exekutor find -x  "${src}" ! -path "${src}" -depth 1 -exec mv -v '{}' "${dst}" \;  2> /dev/null
      fi
      exekutor rm -rf "${src}"
   fi

   src="${output}/Frameworks"
   if [ -d "${src}" ]
   then
      if dir_has_files "${src}"
      then
         dst="${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${subdir}"
         exekutor mkdir -p "${dst}" 2> /dev/null
         exekutor find -x "${src}" ! -path "${src}" -depth 1 -exec mv -v '{}' "${dst}" \; 2> /dev/null
      fi
      exekutor rm -rf "${src}"
   fi

   # now copy over the rest of the output

   dst="${DEPENDENCY_SUBDIR}"
   exekutor find -x "${output}" ! -path "${output}" -depth 1 -exec mv -v -n '{}' "${dst}" \;  2> /dev/null

   return 0
}


enforce_build_sanity()
{
   # these must not exist
   if [ -d "${DEPENDENCY_SUBDIR}/tmp" ]
   then
      fail "A previous build left ${DEPENDENCY_SUBDIR}/tmp can't continue"
   fi

   if [ -d "${builddir}" -a "${CLEAN_BEFORE_BUILD}" != "" ]
   then
      exekutor rm -rf "${builddir}"
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

   enforce_build_sanity

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
   exekutor mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" 2> /dev/null
   exekutor mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}" 2> /dev/null
   exekutor mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" 2> /dev/null

   exekutor mkdir -p "${builddir}" 2> /dev/null
   exekutor cd "${builddir}" || exit 1

      # check that relative ise right
      exekutor [ -d "${relative}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" ] || exit 1
      exekutor [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}" ] || exit 1
      exekutor [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" ] || exit 1

      #
      # cmake doesn't seem to "get" CMAKE_CXX_FLAGS or -INCLUDE
      #
      set -f

      exekutor cmake "-DCMAKE_BUILD_TYPE=${mapped}" \
"-DCMAKE_INSTALL_PREFIX:PATH=${owd}/${DEPENDENCY_SUBDIR}/tmp"  \
"-DCMAKE_C_FLAGS=\
-I${relative}/${DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${other_cflags} \
${sdk}" \
"-DCMAKE_CXX_FLAGS=\
-I${relative}/${DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${other_cppflags} \
${sdk}" \
"-DCMAKE_LD_FLAGS=\
-L${relative}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}${suffix} \
-L${relative}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${configuration} \
-L${relative}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${other_ldflags} \
${sdk}" \
"${relative}/${srcdir}" 1>&2  || exit 1

      exekutor make all install 1>&2 || exit 1

      set +f

   exekutor cd "${owd}"

   collect_and_dispense_product "${owd}/${DEPENDENCY_SUBDIR}/tmp" "${suffix}" || exit 1

   exekutor rm -rf "${owd}/${DEPENDENCY_SUBDIR}/tmp"
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

   enforce_build_sanity

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
   # to avoid warning make sure directories are all there
   exekutor mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" 2> /dev/null
   exekutor mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}" 2> /dev/null
   exekutor mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" 2> /dev/null

   exekutor mkdir -p "${builddir}" 2> /dev/null
   exekutor cd "${builddir}" || exit 1

      # check that relative ise right
      exekutor [ -d "${relative}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" ] || exit 1
      exekutor [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}" ] || exit 1
      exekutor [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" ] || exit 1

      set -f

      # use absolute paths for configure, safer (and easier to read IMO)
      CFLAGS="\
-I${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${other_cflags} \
${sdk}" \
      CPPFLAGS="\
-I${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${other_cppflags} \
${sdk}" \
      LDFLAGS="\
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
-L${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}${suffix} \
-L${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${configuration} \
-L${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH} \
${other_ldflags} \
${sdk}" \
      exekutor "${owd}/${srcdir}/configure" --prefix "${owd}/${DEPENDENCY_SUBDIR}/tmp" 1>&2  || exit 1

      exekutor make all install 1>&2 || exit 1

      set +f

   exekutor cd "${owd}"

   collect_and_dispense_product "${owd}/${DEPENDENCY_SUBDIR}/tmp" "${suffix}" || exit 1

   rm -rf "${owd}/${DEPENDENCY_SUBDIR}/tmp"
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
# What we can not fix up is
# /usr/local/include/${PROJECT_NAME}
# since we can't read the unresolved value (yet)
#
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

   read_yes_no_build_setting "${name}" "xcode_mangle_header_settings"
   if [ $? -ne 0 ]
   then
      return 1
   fi

   local headers

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

   headers="`read_repo_setting "${name}" "${setting_key}" "${prefix}${headers}"`"

   log_fluff "${key} set to \"${headers}\""

   echo "${headers}"
}


escaped_spaces()
{
   echo "$1" | sed 's/ /\\ /g'
}


combined_escaped_search_path()
{
   for i in $*
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
"${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" \
"/usr/local/include"`
      if [ -z "${inherited}" ]
      then
         dependencies_header_search_path="${path}"
      else
         dependencies_header_search_path="${path} ${inherited}"
      fi

      inherited="`xcode_get_setting LIBRARY_SEARCH_PATHS ${arguments}`"
      path=`combined_escaped_search_path \
"${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${mapped}" \
"${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}" \
"/usr/local/lib"`
      if [ ! -z "$sdk" ]
      then
         escaped="`escaped_spaces "${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${mapped}"'-$(EFFECTIVE_PLATFORM_NAME)'`"
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
"${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mapped}" \
"${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}"`
      if [ ! -z "$sdk" ]
      then
         escaped="`escaped_spaces "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mapped}"'-$(EFFECTIVE_PLATFORM_NAME)'`"
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
DSTROOT='${owd}/${DEPENDENCY_SUBDIR}' \
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
}


build_xcodebuild_schemes_or_target()
{
   local builddir
   local name

   builddir="$3"
   name="$5"

   if [ -d "${builddir}" -a "${CLEAN_BEFORE_BUILD}" != "" ]
   then
      exekutor rm -rf "${builddir}"
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
      build_xcodebuild "$@" "" "${target}"
   done
   IFS="${old}"

   if [ "${targets}" = "" -a "${schemes}" = "" ]
   then
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
   [ -z "${sdks}" ] && fail "setting \"sdks\" must at least contain \"Default\" to build anything"

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
                  build_configure "${configuration}" "${srcdir}" "${builddir}" "${relative}" "${name}" "${sdk}" || exit 1
                  built=yes
                  break
               fi
            fi

            if [ "${preference}" = "cmake" -a -x "${cmake}" ]
            then
               if [ -f "${srcdir}/CMakeLists.txt" ]
               then
                  build_cmake "${configuration}" "${srcdir}" "${builddir}" "${relative}" "${name}" "${sdk}" || exit 1
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
         build "${clone}"
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

   #
   # START
   #
   if [ ! -d "${CLONES_SUBDIR}" ]
   then
      log_info "No repos fetched, nothing to do."
      return 0
   fi

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
         fi
      done
   else
      for name in "$@"
      do
         clone="${CLONES_SUBDIR}/${name}"

         if [ -d "${clone}" ]
         then
            built=`build_if_readable "${clone}" "${name}" "${built}"`
         else
            fail "unknown repo ${name}"
         fi
      done
   fi
}


main()
{
   build_clones "$@"
}

main "$@"
