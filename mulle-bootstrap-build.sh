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


CLEAN_BEFORE_BUILD=`read_config_setting "clean"`
HEADER_PATH=`read_config_setting "header_path" "/include"`
LIBRARY_PATH=`read_config_setting "library_path" "/lib"`
FRAMEWORK_PATH=`read_config_setting "frameworks_path" "/Frameworks"`

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
         mkdir -p "${dst}" 2> /dev/null
         find -x "${src}" ! -path "${src}" -depth 1 -type d -exec mv -v -n '{}' "${dst}" \;  2> /dev/null
         find -x  "${src}" ! -path "${src}" -depth 1 -type f -exec mv -v -n '{}' "${dst}" \;  2> /dev/null
      fi
      rm -rf "${src}"
   fi

   src="${output}/lib"
   if [ -d  "${src}" ]
   then
      if dir_has_files "${src}"
      then
         dst="${DEPENDENCY_SUBDIR}${LIBRARY_PATH}${subdir}"
         mkdir -p "${dst}" 2> /dev/null
         find -x  "${src}" ! -path "${src}" -depth 1 -exec mv -v '{}' "${dst}" \;  2> /dev/null
      fi
      rm -rf "${src}"
   fi

   src="${output}/Frameworks"
   if [ -d "${src}" ]
   then
      if dir_has_files "${src}"
      then
         dst="${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${subdir}"
         mkdir -p "${dst}" 2> /dev/null
         find -x "${src}" ! -path "${src}" -depth 1 -exec mv -v '{}' "${dst}" \; 2> /dev/null
      fi
      rm -rf "${src}"
   fi

   # now copy over the rest of the output

   dst="${DEPENDENCY_SUBDIR}"
   find -x "${output}" ! -path "${output}" -depth 1 -exec mv -v -n '{}' "${dst}" \;  2> /dev/null

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
      rm -rf "${builddir}"
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

   [ ! -z $configuration ] || fail "configuration must not be empty"
   [ ! -z $sdk ] || fail "sdk must not be empty"

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
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" 2> /dev/null
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}" 2> /dev/null
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" 2> /dev/null

   mkdir -p "${builddir}" 2> /dev/null
   cd "${builddir}" || exit 1

      # check that relative ise right
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" ] || exit 1
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}" ] || exit 1
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" ] || exit 1

      #
      # cmake doesn't seem to "get" CMAKE_CXX_FLAGS or -INCLUDE
      #
      set -f
      set -x
      cmake "-DCMAKE_BUILD_TYPE=${mapped}" \
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

      make all install 1>&2 || exit 1
      set +x
      set +f

   cd "${owd}"

   collect_and_dispense_product "${owd}/${DEPENDENCY_SUBDIR}/tmp" "${suffix}" || exit 1

   rm -rf "${owd}/${DEPENDENCY_SUBDIR}/tmp"
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
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" 2> /dev/null
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}" 2> /dev/null
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" 2> /dev/null

   mkdir -p "${builddir}" 2> /dev/null
   cd "${builddir}" || exit 1

      # check that relative ise right
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" ] || exit 1
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${configuration}" ] || exit 1
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" ] || exit 1

      set -f
      set -x

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
      "${owd}/${srcdir}/configure" --prefix "${owd}/${DEPENDENCY_SUBDIR}/tmp" 1>&2  || exit 1

      make all install 1>&2 || exit 1

      set +x
      set +f

   cd "${owd}"

   collect_and_dispense_product "${owd}/${DEPENDENCY_SUBDIR}/tmp" "${suffix}" || exit 1

   rm -rf "${owd}/${DEPENDENCY_SUBDIR}/tmp"
}


xcode_get_setting()
{
   local key
   local configuration

   key="$1"
   shift
   configuration="$1"
   shift

   xcodebuild -showBuildSettings -configuration "${configuration}" $* | \
   egrep "^[ ]*${key}" | \
   sed 's/^[^=]*=[ ]*\(.*\)/\1/' || \
   exit 1
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

   log_info "Do a xcodebuild for SDK ${sdk}, ${targetname}${schemename}..."

   local projectname

    # always pass project directly
   projectname=`read_repo_setting "${name}" "project" "${project}"`
   project="-project ${projectname}"

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
      sdk="-sdk ${sdk}"
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

   local xcflags

   xcflags=`read_build_setting "${name}" "xcodebuild-flags"`
   local xcconfig
   local xcconfigname

   xcconfig=
   xcconfigname=`read_build_setting "${name}" xcconfig`
   if [ "$xcconfigname" != "" ]
   then
      xcconfig="-xcconfig ${xcconfigname}"
   fi

   #
   # xctool needs schemes, these are often autocreated, which xctool cant do
   # xcodebuild can just use a target
   # xctool is by and large useless fluff IMO
   #
   local target
   local scheme

   if [ "$xcodebuild" = "xctool"  -a "${schemename}" = ""  ]
   then
      if [ "$targetname" != "" ]
      then
         target=
         scheme="-scheme ${targetname}"
      else
         echo "Please specify a scheme to compile in ${BOOTSTRAP_SUBDIR}/${name}/SCHEME for xctool" >& 2
         echo "and be sure that this scheme exists and is shared." >& 2
         echo "Or just delete ${HOME}/.mulle-bootstrap/xcodebuild and use xcodebuild (preferred)" >& 2
         exit 1
      fi
   else
     if [ "${schemename}" != "" ]
     then
        scheme="-scheme ${schemename}"
     fi
     if [ "${targetname}" != "" ]
     then
        target="-target ${targetname}"
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

      #
      # headers are complicated, the preference is to get it uniform into
      # dependencies/include/libraryname/..
      #
      local public_headers
      local private_headers
      local public_header_name
      local private_header_name

      public_headers=`xcode_get_setting PUBLIC_HEADERS_FOLDER_PATH "${mapped}" "${project}" "${scheme}" "${target}"`
      private_headers=`xcode_get_setting PRIVATE_HEADERS_FOLDER_PATH "${mapped}" "${project}" "${scheme}" "${target}"`

      read_yes_no_build_setting "${name}" "keep_xcode_header_settings"
      if [ $? -ne 0 ]
      then
         public_header_name=`remove_absolute_path_prefix_up_to "${public_headers}" "include"`
         private_header_name=`remove_absolute_path_prefix_up_to "${private_headers}" "include"`

         if read_yes_no_build_setting "${name}" "mangle_header_dash"
         then
            public_header_name=`echo "${public_header_name}" | tr '-' '_'`"
            private_header_name=`echo "${private_header_name}" | tr '-' '_'`"
         fi

         if [ "${public_header_name}" != "" ]
         then
            public_header_name="/${public_header_name}"
         fi
         if [ "${private_header_name}" != "" ]
         then
            private_header_name="/${private_header_name}"
         fi

         public_headers=`read_repo_setting "${name}" "public_headers" "${HEADER_PATH}${public_header_name}"`
         private_headers=`read_repo_setting "${name}" "private_headers" "${HEADER_PATH}${private_header_name}"`
      fi


      # manually point xcode to our headers and libs
      # this is like manually doing xcode-setup
      local dependencies_framework_search_path
      local dependencies_header_search_path
      local dependencies_lib_search_path
      local inherited

      #
      # TODO: need to figure out the correct mapping here
      #
      inherited=`xcode_get_setting HEADER_SEARCH_PATHS "${mapped}" $project $scheme $target`
      dependencies_header_search_path="HEADER_SEARCH_PATHS="
      dependencies_header_search_path="${dependencies_header_search_path} \
         ${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH}"
      dependencies_header_search_path="${dependencies_header_search_path} \
         /usr/local/include"
      dependencies_header_search_path="${dependencies_header_search_path} \
         ${inherited}"

      inherited=`xcode_get_setting LIBRARY_SEARCH_PATHS "${mapped}" $project $scheme $target`
      dependencies_lib_search_path="LIBRARY_SEARCH_PATHS="
      if [ ! -z $sdk ]
      then
         dependencies_lib_search_path="${dependencies_lib_search_path} \
            ${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${mapped}-\$(EFFECTIVE_PLATFORM_NAME)"
      fi
      dependencies_lib_search_path="${dependencies_lib_search_path} \
         ${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${mapped}"
      dependencies_lib_search_path="${dependencies_lib_search_path} \
         ${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}"
      dependencies_lib_search_path="${dependencies_lib_search_path} \
         /usr/local/lib"
      dependencies_lib_search_path="${dependencies_lib_search_path} \
         ${inherited}"

      inherited=`xcode_get_setting FRAMEWORK_SEARCH_PATHS "${mapped}" $project $scheme $target`
      dependencies_framework_search_path="FRAMEWORK_SEARCH_PATHS="
      if [ ! -z $sdk ]
      then
         dependencies_framework_search_path="${dependencies_framework_search_path} \
            ${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mapped}-\$(EFFECTIVE_PLATFORM_NAME)"
      fi
      dependencies_framework_search_path="${dependencies_framework_search_path} \
         ${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mapped}"
      dependencies_framework_search_path="${dependencies_framework_search_path} \
         ${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}"
      dependencies_framework_search_path="${dependencies_framework_search_path} \
         ${inherited}"

      set -f
      set +x

      # if it doesn't install, probably SKIP_INSTALL is set
      $xcodebuild $command $project $sdk $scheme $target -configuration "${mapped}" \
      ${xcflags} \
      ${xcconfig} \
      ${aux} \
      "ARCHS=\${ARCHS_STANDARD_32_64_BIT}" \
      "DEPLOYMENT_LOCATION=YES" \
      "DSTROOT=${owd}/${DEPENDENCY_SUBDIR}" \
      "INSTALL_PATH=${LIBRARY_PATH}${suffix}" \
      "PUBLIC_HEADERS_FOLDER_PATH=${public_headers}" \
      "PRIVATE_HEADERS_FOLDER_PATH=${private_headers}" \
      SYMROOT="${owd}/${builddir}/" \
      OBJROOT="${owd}/${builddir}/obj" \
      ONLY_ACTIVE_ARCH=NO \
      ${skip_install} \
      "${dependencies_header_search_path}" \
      "${dependencies_lib_search_path}" \
      "${dependencies_framework_search_path} " \
      1>&2 || exit 1
   # TODO: why is it ${builddir} and not ../../${builddir} ??
      set +x
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
      rm -rf "${builddir}"
   fi

   local scheme
   local schemes

   schemes=`read_repo_setting "${name}" "schemes"`
   for scheme in $schemes
   do
      build_xcodebuild "$@" "${scheme}" ""
   done

   local target
   local targets

   targets=`read_repo_setting "${name}" "targets"`
   for target in $targets
   do
      build_xcodebuild "$@" "" "${target}"
   done

   if [ "${targets}" = "" -a "${schemes}" = "" ]
   then
      build_xcodebuild "$@"
   fi
}


build()
{
   local clone
   local name
   local builddir
   local relative
   local srcdir
   local built
   local sdk
   local configuration
   local preference

   srcdir="$1"
   name=`basename "${srcdir}"`

   local preferences
   local configurations
   local sdks
   local cmake
   local xcodebuild

   preferences=`read_config_setting "build_preferences" "script
xcodebuild
cmake
configure"`

   configurations=`read_build_root_setting "configurations" "Debug
Release"`

   xcodebuild=`which "xcodebuild"`
   cmake=`which "cmake"`

   # need uniform SDK for our builds
   sdks=`read_build_root_setting "sdks" "Default"`
   [ -z "${sdks}" ] && fail "setting \"sdks\" must at least contain \"Default\" to build anything"

   log_info "building ${srcdir} ..." >&2

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

      for clone in ${CLONES_SUBDIR}/*
      do
         name=`basename "${clone}"`

         if [ -d "${clone}" ]
         then
            built=`build_if_readable "${clone}" "${name}" "${built}"`
         fi
      done
   else
      for clone in "$@"
      do
         clone="${CLONES_SUBDIR}/${name}"

         built=`build_if_readable "${clone}" "${name}" "${built}"`
      done
   fi
}


main()
{
   build_clones "$@"
}

main "$@"
