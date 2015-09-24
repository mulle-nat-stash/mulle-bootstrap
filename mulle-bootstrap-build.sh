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


CLEAN_BEFORE_BUILD=`read_local_setting "clean"`
HEADER_PATH=`read_local_setting "header_path" "/include"`
LIBRARY_PATH=`read_local_setting "library_path" "/lib"`
FRAMEWORK_PATH=`read_local_setting "frameworks_path" "/Frameworks"`


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
   local mode
   local sdk
   local suffix
   local hackish

   mode="$1"
   sdk="$2"

   suffix="/${mode}"
   if [ "${sdk}" != "Default" ]
   then
      hackish=`echo "${sdk}" | sed 's/^\([a-zA-Z]*\).*$/\1/g'`
      suffix="${suffix}-${hackish}"
   fi
   echo "${suffix}"
}


gcc_sdk_parameter()
{
   local mode
   local sdk
   local suffix
   local sdkpath


   mode="$1"
   sdk="$2"
   suffix="$2"

   if [ "`uname`" = "Darwin" ]
   then
      if [ "${sdk}" != "Default" ]
      then
         sdkpath="`xcrun --sdk macosx --show-sdk-path`"
         if [ "${sdkpath}" = "" ]
         then
            fail "SDK \"${sdk}\" is not installed"
         fi
         echo '-DCMAKE_OSX_SYSROOT='"${sdkpath}"
      fi
   fi
}


#
# remove old builddir, create a new one
# depending on mode cmake with flags
# build stuff into dependencies
#
#
build_cmake()
{
   local mode
   local srcdir
   local builddir
   local relative
   local name
   local sdk
   local mapped

   mode="$1"
   srcdir="$2"
   builddir="$3"
   relative="$4"
   name="$5"
   sdk="$6"

   enforce_build_sanity

   mapped=`read_build_setting "$name" "cmake-${mode}.map" "${mode}"`
   suffix=`determine_suffix "${mode}" "${sdk}"`
   sdk=`gcc_sdk_parameter "${mode}" "${sdk}" "${suffix}"`

   owd="${PWD}"
   # to avoid warning make sure directories are all there
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" 2> /dev/null
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mode}" 2> /dev/null
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" 2> /dev/null

   mkdir -p "${builddir}" 2> /dev/null
   cd "${builddir}" || exit 1

      # check that relative ise right
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" ] || exit 1
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mode}" ] || exit 1
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
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mode} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${sdk}" \
"-DCMAKE_CXX_FLAGS=\
-I${relative}/${DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mode} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}" \
"-DCMAKE_LD_FLAGS=\
-L${relative}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}${suffix} \
-L${relative}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${mode} \
-L${relative}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mode} \
-F${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
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
# depending on mode cmake with flags
# build stuff into dependencies
#
#
build_configure()
{
   local mode
   local srcdir
   local builddir
   local relative
   local name
   local sdk
   local mapped

   mode="$1"
   srcdir="$2"
   builddir="$3"
   relative="$4"
   name="$5"
   sdk="$6"

   enforce_build_sanity

   mapped=`read_build_setting "$name" "configure-${mode}.map" "${mode}"`
   suffix=`determine_suffix "${mode}" "${sdk}"`
   sdk=`gcc_sdk_parameter "${mode}" "${sdk}" "${suffix}"`

   owd="${PWD}"
   # to avoid warning make sure directories are all there
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" 2> /dev/null
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mode}" 2> /dev/null
   mkdir -p "${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" 2> /dev/null

   mkdir -p "${builddir}" 2> /dev/null
   cd "${builddir}" || exit 1

      # check that relative ise right
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${HEADER_PATH}" ] || exit 1
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mode}" ] || exit 1
      [ -d "${relative}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix}" ] || exit 1

      set -f
      set -x

      # use absolute paths for configure, safer (and easier to read IMO)
      CFLAGS="\
-I${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mode} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${sdk}" \
      CPPFLAGS="\
-I${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mode} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
${sdk}" \
      LDFLAGS="\
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}${suffix} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mode} \
-F${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
-L${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}${suffix} \
-L${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${mode} \
-L${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}" \
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

   xcodebuild -showBuildSettings -configuration "${configuration}" "$@" | egrep "^[ ]*${key}" | sed 's/^[^=]*=[ ]*\(.*\)/\1/' || exit 1
}


build_xcodebuild()
{
   local mode
   local srcdir
   local builddir
   local relative
   local name
   local sdk
   local project

   mode="$1"
   srcdir="$2"
   builddir="$3"
   relative="$4"
   name="$5"
   sdk="$6"
   project="$7"

   if [ -d "${builddir}" -a "${CLEAN_BEFORE_BUILD}" != "" ]
   then
      rm -rf "${builddir}"
   fi

   local project
   local projectname

   # always pass project directly
   projectname=`read_repo_setting "${name}" "project"`
   if [ "${projectname}" != "" ]
   then
      project="-project ${projectname}"
   else
      project="-project ${project}"
   fi

   local scheme
   local schemename

   scheme=
   schemename=`read_repo_setting "${name}" "scheme"`
   if [ "$schemename" != "" ]
   then
      scheme="-scheme ${schemename}"
   fi

   local target
   local targetname

   target=
   targetname=`read_repo_setting "${name}" "target"`
   if [ "$targetname" != "" ]
   then
      target="-target ${targetname}"
   fi

   local mapped

   mapped=`read_build_setting "${name}" "${mode}.map" "${mode}"`

   local hackish
   local targetname
   local suffix

   suffix="/${mode}"
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
   proper_skip_install=`read_repo_setting "${name}" "proper_skip_install" "NO"`
   if [ "$proper_skip_install" != "YES" ]
   then
      skip_install="SKIP_INSTALL=NO"
   fi

   local public_headers
   local private_headers_subdir

   public_headers=`read_repo_setting "${name}" "public_headers" "${HEADER_PATH}/${name}"`
   private_headers_subdir=`read_repo_setting "${name}" "private_headers_subdir" "private"`

   local xcodebuild
   local binary

   xcodebuild=`read_local_setting "xcodebuild" "xcodebuild"`
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
      dependencies_header_search_path="HEADER_SEARCH_PATHS=\
${owd}/${DEPENDENCY_SUBDIR}${HEADER_PATH} \
/usr/local/include \
${inherited}"

      inherited=`xcode_get_setting LIBRARY_SEARCH_PATHS "${mapped}" $project $scheme $target`
      dependencies_lib_search_path="LIBRARY_SEARCH_PATHS=\
${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${mapped}-\$(EFFECTIVE_PLATFORM_NAME) \
${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH}/${mapped} \
${owd}/${DEPENDENCY_SUBDIR}${LIBRARY_PATH} \
/usr/local/lib \
${inherited}"

      inherited=`xcode_get_setting FRAMEWORK_SEARCH_PATHS "${mapped}" $project $scheme $target`
      dependencies_framework_search_path="FRAMEWORK_SEARCH_PATHS=\
${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mapped}-\$(EFFECTIVE_PLATFORM_NAME) \
${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH}/${mapped} \
${owd}/${DEPENDENCY_SUBDIR}${FRAMEWORK_PATH} \
/usr/local/lib \
${inherited}"

      set -f
      set -x

      echo "${BOOTSTRAP_SUBDIR}" >&2
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
      "PRIVATE_HEADERS_FOLDER_PATH=${public_headers}/${private_headers_subdir}" \
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

   preferences=`read_local_setting "preferences"`
   if [ "$preferences" = "" ]
   then
      preferences=`read_build_root_setting "preferences" "script
xcodebuild
cmake
configure"`
   fi

   configurations=`read_local_setting "configurations"`
   if [ "$configurations" = "" ]
   then
      configurations=`read_build_root_setting "configurations" "Debug
Release"`
   fi

   xcodebuild=`which "xcodebuild"`
   cmake=`which "cmake"`

   # need uniform SDK for our builds
   sdks=`read_build_root_setting "sdks" "Default"`

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
                  build_xcodebuild "${configuration}" "${srcdir}" "${builddir}" "${relative}" "${name}" "${sdk}" "${project}"  || exit 1
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
            xdone=`/bin/echo "${built}" | grep "${name}"`
            if [ "$xdone" = "" ]
            then
               build "${clone}"
               built="${name}
${built}"
            fi
         else
            fail "buildorder contains unknown repo ${name}"
         fi
      done

      for clone in ${CLONES_SUBDIR}/*
      do
         name=`basename "${clone}"`

         if [ -d "${clone}" ]
         then
            xdone=`/bin/echo "${built}" | grep "${name}"`
            if [ "$xdone" = "" ]
            then
               build "${clone}"
               built="${name}
${built}"
            fi
         fi
      done
   else
      for clone in "$@"
      do
         clone="${CLONES_SUBDIR}/${name}"

         xdone=`/bin/echo "${built}" | grep "${name}"`
         if [ "$xdone" = "" ]
         then
            build "${clone}"
            built="${name}
${built}"
         fi
      done
   fi
}


main()
{
   build_clones "$@"
}

main "$@"
