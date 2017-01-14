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
MULLE_BOOTSTRAP_BUILD_SH="included"


build_usage()
{
   local defk
   local defc
   local defkk

   defc="`printf "$CONFIGURATIONS" | tr '\012' ','`"
   if [ "${CLEAN_BEFORE_BUILD}" = "YES" ]
   then
      defk=""
      defkk="(default)"
   else
      defk="(default)"
      defkk=""
   fi

   cat <<EOF >&2
usage:
   mulle-bootstrap build [-ck] [repos]*

   -k             :  don't clean before building $defk
   -K             :  always clean before building $defkk
   -c <name>      :  configurations to build ($defc), separate with comma
   --prefix <dir> :  use <dir> instead of /usr/local
EOF

   case "${UNAME}" in
      mingw*)
         :
      ;;

      *)
         cat <<EOF >&2
   -j         :  number of cores parameter for make (${CORES})
EOF
      ;;
   esac

   cat << EOF >&2
   You can optionally specify the names of the repositories to build.
   Currently available names are:
EOF
   (cd "${REPOS_DIR}" ; ls -1 ) 2> /dev/null

   exit 1
}



#
# move stuff produced my cmake and configure to places
# where we expect them. Expect  others to build to
# <prefix>/include  and <prefix>/lib or <prefix>/Frameworks
#
dispense_headers()
{
   local name
   local src

   name="$1"
   src="$2"

   local dst
   local headerpath

   log_fluff "Consider copying headers from \"${src}\""

   if [ -d "${src}" ]
   then
      if dir_has_files "${src}"
      then
         headerpath="`read_build_setting "${name}" "dispense_headers_path" "/${HEADER_DIR_NAME}"`"

         dst="${REFERENCE_DEPENDENCIES_DIR}${headerpath}"
         mkdir_if_missing "${dst}"

         # this fails with more nested header set ups, need to fix!

         log_fluff "Copying \"${src}\" to \"${dst}\""
         exekutor cp -Ra ${COPYMOVEFLAGS} "${src}"/* "${dst}" || exit 1

         rmdir_safer "${src}"
      else
         log_fluff "But there are none"
      fi
   else
      log_fluff "But it doesn't exist"
   fi
}


dispense_binaries()
{
   local name
   local src
   local findtype
   local depend_subdir
   local subpath

   name="$1"
   src="$2"
   findtype="$3"
   depend_subdir="$4"
   subpath="$5"

   local dst
   local findtype2
   local copyflag

   findtype2="l"
   copyflag="-f"
   if [ "${findtype}" = "-d"  ]
   then
      copyflag="-n"
   fi
   log_fluff "Consider copying binaries from \"${src}\" for type \"${findtype}/${findtype2}\""

   if [ -d "${src}" ]
   then
      if dir_has_files "${src}"
      then
         dst="${REFERENCE_DEPENDENCIES_DIR}${depend_subdir}${subpath}"

         log_fluff "Copying \"${src}\" to \"${dst}\""
         mkdir_if_missing "${dst}"
         exekutor find "${src}" -xdev -mindepth 1 -maxdepth 1 \( -type "${findtype}" -o -type "${findtype2}" \) -print0 | \
            exekutor xargs -0 -I % mv ${COPYMOVEFLAGS} "${copyflag}" % "${dst}"
         [ $? -eq 0 ]  || exit 1
      else
         log_fluff "But there are none"
      fi
      rmdir_safer "${src}"
   else
      log_fluff "But it doesn't exist"
   fi
}


collect_and_dispense_product()
{
   local  name
   local  build_subdir
   local  depend_subdir
   local  name

   name="$1"
   build_subdir="$2"
   depend_subdir="$3"
   wasxcode="$4"

   local  dst
   local  src

   if read_yes_no_config_setting "skip_collect_and_dispense" "NO"
   then
      log_info "Skipped collection and dispensal on request"
      return 0
   fi

   log_verbose "Collecting and dispensing \"${name}\" products"

   #
   # probably should use install_name_tool to hack all dylib paths that contain .ref
   # (will this work with signing stuff ?)
   #
   if true
   then
      log_fluff "Choosing xcode dispense path"

      # cmake

      src="${BUILD_DEPENDENCIES_DIR}/usr/local/include"
      dispense_headers "${name}" "${src}"

      src="${BUILD_DEPENDENCIES_DIR}/usr/local/lib"
      dispense_binaries "${name}" "${src}" "f" "${depend_subdir}" "/${LIBRARY_DIR_NAME}"

      # pretty much xcodetool specific

      src="${BUILD_DEPENDENCIES_DIR}/usr/include"
      dispense_headers "${name}" "${src}"

      src="${BUILD_DEPENDENCIES_DIR}/include"
      dispense_headers "${name}" "${src}"

      src="${BUILD_DEPENDENCIES_DIR}${build_subdir}/lib"
      dispense_binaries "${name}" "${src}" "f" "${depend_subdir}" "/${LIBRARY_DIR_NAME}"

      src="${BUILD_DEPENDENCIES_DIR}${build_subdir}/Library/Frameworks"
      dispense_binaries "${name}" "${src}" "d" "${depend_subdir}" "/${FRAMEWORK_DIR_NAME}"

      src="${BUILD_DEPENDENCIES_DIR}${build_subdir}/Frameworks"
      dispense_binaries "${name}" "${src}" "d" "${depend_subdir}" "/${FRAMEWORK_DIR_NAME}"

      src="${BUILD_DEPENDENCIES_DIR}${build_subdir}/Library/Frameworks"
      dispense_binaries "${name}" "${src}" "d" "${depend_subdir}" "/${FRAMEWORK_DIR_NAME}"

      src="${BUILD_DEPENDENCIES_DIR}${build_subdir}/Frameworks"
      dispense_binaries "${name}" "${src}" "d" "${depend_subdir}" "/${FRAMEWORK_DIR_NAME}"

      src="${BUILD_DEPENDENCIES_DIR}/Library/Frameworks"
      dispense_binaries "${name}" "${src}" "d"  "${depend_subdir}" "/${FRAMEWORK_DIR_NAME}"

      src="${BUILD_DEPENDENCIES_DIR}/Frameworks"
      dispense_binaries "${name}" "${src}" "d" "${depend_subdir}" "/${FRAMEWORK_DIR_NAME}"
   fi

   #
   # Delete empty dirs if so
   #
   src="${BUILD_DEPENDENCIES_DIR}/usr/local"
   dir_has_files "${src}"
   if [ $? -ne 0 ]
   then
      rmdir_safer "${src}"
   fi

   src="${BUILD_DEPENDENCIES_DIR}/usr"
   dir_has_files "${src}"
   if [ $? -ne 0 ]
   then
      rmdir_safer "${src}"
   fi

   #
   # probably should hack all executables with install_name_tool that contain .ref
   #
   # now copy over the rest of the output
   if read_yes_no_build_setting "${name}" "dispense_other_product" "NO"
   then
      local usrlocal

      usrlocal="`read_build_setting "${name}" "dispense_other_path" "/usr/local"`"

      log_fluff "Considering copying ${BUILD_DEPENDENCIES_DIR}/*"

      src="${BUILD_DEPENDENCIES_DIR}"
      if [ "${wasxcode}" = "YES" ]
      then
         src="${src}${build_subdir}"
      fi

      if dir_has_files "${src}"
      then
         dst="${REFERENCE_DEPENDENCIES_DIR}${usrlocal}"

         log_fluff "Copying everything from \"${src}\" to \"${dst}\""
         exekutor find "${src}" -xdev -mindepth 1 -maxdepth 1 -print0 | \
               exekutor xargs -0 -I % mv ${COPYMOVEFLAGS} -f % "${dst}"
         [ $? -eq 0 ]  || fail "moving files from ${src} to ${dst} failed"
      fi

      if [ "$MULLE_BOOTSTRAP_VERBOSE" = "YES"  ]
      then
         if dir_has_files "${BUILD_DEPENDENCIES_DIR}"
         then
            log_fluff "Directory \"${dst}\" contained files after collect and dispense"
            log_fluff "--------------------"
            ( cd "${BUILD_DEPENDENCIES_DIR}" ; ls -lR >&2 )
            log_fluff "--------------------"
         fi
      fi
   fi

   rmdir_safer "${BUILD_DEPENDENCIES_DIR}"

   log_fluff "Done collecting and dispensing product"
   log_fluff
}


enforce_build_sanity()
{
   local builddir

   builddir="$1"

   # these must not exist
   if [ -d "${BUILD_DEPENDENCIES_DIR}" ]
   then
      fail "A previous build left \"${BUILD_DEPENDENCIES_DIR}\", can't continue"
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

   suffix="${configuration}"
   if [ "${sdk}" != "Default" ]
   then
      hackish=`echo "${sdk}" | sed 's/^\([a-zA-Z]*\).*$/\1/g'`
      suffix="${suffix}-${hackish}"
   fi
   echo "${suffix}"
}


#
# if only one configuration is chosen, make it the default
# if there are multiple configurations, make Release the default
# if Release is not in multiple configurations, then there is no default
#
determine_build_subdir()
{
   echo "/$1"
}


determine_dependencies_subdir()
{
   if [ "${N_CONFIGURATIONS}" -gt 1 ]
   then
      if [ "$1" != "Release" ]
      then
         echo "/$1"
      fi
   fi
}


cmake_sdk_parameter()
{
   local sdk

   sdk="$1"

   local sdkpath

   sdkpath=`gcc_sdk_parameter "${sdk}"`
   if [ ! -z "${sdkpath}" ]
   then
      log_fluff "Set cmake -DCMAKE_OSX_SYSROOT to \"${sdkpath}\""
      echo "-DCMAKE_OSX_SYSROOT='${sdkpath}'"
   fi
}


create_dummy_dirs_against_warnings()
{
   local mapped
   local suffix

   mapped="$1"
   suffix="$2"

   local mappedsubdir
   local suffixsubdir

   mappedsubdir="`determine_dependencies_subdir "${mapped}"`"
   suffixsubdir="`determine_dependencies_subdir "${suffix}"`"

   local owd

   owd="${PWD}"

   # to avoid warnings, make sure directories are all there
   mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCIES_DIR}/${HEADER_DIR_NAME}"

   mkdir_if_missing "${owd}/${REFERENCE_ADDICTIONS_DIR}${mappedsubdir}/${LIBRARY_DIR_NAME}"
   mkdir_if_missing "${owd}/${REFERENCE_ADDICTIONS_DIR}${mappedsubdir}/${FRAMEWORK_DIR_NAME}"

   mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}/${LIBRARY_DIR_NAME}"
   mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}/${FRAMEWORK_DIR_NAME}"

   mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${LIBRARY_DIR_NAME}"
   mkdir_if_missing "${owd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${FRAMEWORK_DIR_NAME}"
}


build_fail()
{
   if [ -f "$1" ]
   then
      printf "${C_RED}"
      egrep -B1 -A5 -w "[Ee]rror" "$1" >&2
      printf "${C_RESET}"
   fi

   if [ "$MULLE_BOOTSTRAP_TRACE" != "1848" ]
   then
      log_info "Check the build log: ${C_RESET_BOLD}$1${C_INFO}"
   fi
   fail "$2 failed"
}


build_log_name()
{
   local tool
   local name

   tool="$1"
   [ $# -eq 0 ] || shift
   name="$1"
   [ $# -eq 0 ] || shift

   local logfile
   logfile="${BUILDLOG_SUBDIR}/${name}"

   while [ $# -gt 0 ]
   do
      if [ ! -z "$1" ]
      then
         logfile="${logfile}-$1"
      fi
      [ $# -eq 0 ] || shift
   done

   echo "${logfile}.${tool}.log"
}


verify_binary()
{
   local toolname
   local toolfamily
   local tooldefaultname

   toolname="$1"
   toolfamily="$2"
   tooldefaultname="$3"

   [ -z "${toolname}" ] && internal_fail "toolname for \"${toolfamily}\" is empty"

   local path

   path=`which_binary "${toolname}"`
   if [ ! -z "${path}" ]
   then
      echo "${toolname}"
      return 0
   fi

   #
   # if user specified a certain tool, then it not being there is bad
   # otherwise it's maybe OK (f.e. only using xcodebuild not cmake)
   #
   toolname="`extension_less_basename "${toolname}"`"
   tooldefaultname="`extension_less_basename "${tooldefaultname}"`"

   if [ "${toolname}" != "${tooldefaultname}" ]
   then
      fail "${toolname} not found in PATH"
   else
      log_fluff "${toolname} not found in PATH"
   fi

   return
}


assert_binary()
{
   local toolname
   local toolfamily

   toolname="$1"
   toolfamily="$2"

   [ -z "${toolname}" ] && internal_fail "toolname for \"${toolfamily}\" is empty"

   local path

   path=`which_binary "${toolname}"`
   if [ -z "${path}" ]
   then
      which_binary "${toolname}"
      fail "${toolname} is an unknown build tool (PATH=$PATH)"
   fi
   # echo "$path"
}


find_cmake()
{
   local name

   name="$1"

   local toolname

   toolname=`read_build_setting "${name}" "cmake" "cmake"`
   verify_binary "${toolname}" "cmake" "cmake"
}


find_make()
{
   local name

   name="$1"

   local toolname
   local defaultname

   defaultname="${2:-make}"
   toolname=`read_build_setting "${name}" "make" "${defaultname}"`
   verify_binary "${toolname}" "make" "${defaultname}"
}


find_compiler()
{
   local compiler_name
   local name
   local file

   name="$1"
   compiler_name="$2"

   local compiler

   compiler="`read_build_setting "${name}" "${compiler_name}"`"
   if [ -z "${compiler}" ]
   then
      file="${REPOS_DIR}/${name}/.${compiler_name}"
      compiler="`cat "${file}" 2>/dev/null`"
      if [  ! -z "${compiler}" ]
      then
         log_verbose "Compiler ${C_RESET_BOLD}${compiler_name}${C_VERBOSE} set to ${C_MAGENTA}${C_BOLD}${compiler}${C_VERBOSE} found in \"${file}\""
      fi
   fi

   case "${UNAME}" in
      mingw)
         if [ "`read_config_setting "mangle_minwg_compiler" "YES"`" = "YES" ]
         then
            compile="`mingw_mangle_compiler "${compiler}"`"
         fi
      ;;
   esac

   if [ ! -z "${compiler}" ]
   then
      assert_binary "${compiler}" "${compiler_name}"
   fi
   echo "`basename -- "${compiler}"`"
}


find_xcodebuild()
{
   local name

   name="$1"

   local toolname

   toolname=`read_build_setting "${name}" "xcodebuild" "xcodebuild"`
   verify_binary "${toolname}" "xcodebuild" "xcodebuild"
}


tools_environment()
{
   local name

   name="$1"

   # no problem if those are empty
   C_COMPILER="`find_compiler "${name}" CC`"
   CXX_COMPILER="`find_compiler "${name}" CXX`"

   local defaultgenerator
   local defaultmake

   case "${UNAME}" in
      mingw)
         case "${C_COMPILER}" in
            ""|cl|cl.exe)
               defaultmake="nmake"
            ;;
            *)
               defaultmake="mingw32-make"
            ;;
         esac

         MAKE="`find_make "${name}" "${defaultmake}"`"
         case "${MAKE}" in
            n*|N*)
               defaultgenerator="NMake Makefiles"
            ;;
            mingw*|MINGW*)
               defaultgenerator="MinGW Makefiles"
            ;;
            *)
               defaultgenerator="MSYS Makefiles"
            ;;
         esac

         CMAKE="`find_cmake "${name}"`"
         # default use mingw32-make
         # except if the settings specify otherwise
      ;;

      darwin)
         XCODEBUILD="`find_xcodebuild "${name}"`"
         defaultgenerator="Unix Makefiles"
         MAKE="`find_make "${name}"`"
         CMAKE="`find_cmake "${name}"`"
      ;;

      *)
         defaultgenerator="Unix Makefiles"
         MAKE="`find_make "${name}"`"
         CMAKE="`find_cmake "${name}"`"
      ;;
   esac

   CMAKE_GENERATOR="`read_build_setting "${name}" "cmake_generator" "${defaultgenerator}"`"
}


#
# remove old builddir, create a new one
# depending on configuration cmake with flags
# build stuff into dependencies
# TODO: cache commandline in a file $ and emit instead of rebuilding it every time
#
build_cmake()
{
   local configuration
   local srcdir
   local builddir
   local name
   local sdk

   configuration="$1"
   srcdir="$2"
   builddir="$3"
   name="$4"
   sdk="$5"

   enforce_build_sanity "${builddir}"

   if [ -z "${CMAKE}" ]
   then
      fail "No cmake available"
   fi
   if [ -z "${MAKE}" ]
   then
      fail "No make available"
   fi

   log_info "Let ${C_RESET_BOLD}cmake${C_INFO} do a \
${C_MAGENTA}${C_BOLD}${configuration}${C_INFO} build of \
${C_MAGENTA}${C_BOLD}${name}${C_INFO} for SDK \
${C_MAGENTA}${C_BOLD}${sdk}${C_INFO} in \"${builddir}\" ..."

   local sdkparameter
   local suffix
   local mapped
   local fallback
   local localcmakeflags

   fallback="`echo "${CONFIGURATIONS}" | tail -1`"
   fallback="`read_build_setting "${name}" "fallback-configuration" "${fallback}"`"
   mapped="`read_build_setting "${name}" "cmake-${configuration}.map" "${configuration}"`"
   localcmakeflags="`read_build_root_setting "cmakeflags"`"
   suffix="`determine_suffix "${configuration}" "${sdk}"`"
   sdkparameter="`cmake_sdk_parameter "${sdk}"`"

   create_dummy_dirs_against_warnings "${mapped}" "${suffix}"

   local mappedsubdir
   local fallbacksubdir
   local suffixsubdir

   mappedsubdir="`determine_dependencies_subdir "${mapped}"`"
   suffixsubdir="`determine_dependencies_subdir "${suffix}"`"
   fallbacksubdir="`determine_dependencies_subdir "${fallback}"`"

   local c_compiler_line
   local cxx_compiler_line

   if [ ! -z "${C_COMPILER}" ]
   then
      c_compiler_line="-DCMAKE_C_COMPILER='${C_COMPILER}'"
   fi
   if [ ! -z "${CXX_COMPILER}" ]
   then
      cxx_compiler_line="-DCMAKE_CXX_COMPILER='${CXX_COMPILER}'"
   fi

   # linker="`read_build_setting "${name}" "LD"`"

   local other_cflags
   local other_cxxflags
   local other_ldflags

   other_cflags="`gcc_cflags_value "${name}"`"
   other_cxxflags="`gcc_cxxflags_value "${name}"`"
   other_ldflags="`gcc_ldflags_value "${name}"`"

   local logfile1
   local logfile2

   mkdir_if_missing "${BUILDLOG_SUBDIR}"

   logfile1="`build_log_name "cmake" "${name}" "${configuration}" "${sdk}"`"
   logfile2="`build_log_name "make" "${name}" "${configuration}" "${sdk}"`"

   log_verbose "Build logs will be in \"${logfile1}\" and \"${logfile2}\""

   local local_make_flags

   if [ ! -z "${CORES}" ]
   then
      local_make_flags="-j ${CORES}"
   fi

   local owd
   local nativewd

   owd="${PWD}"
   nativewd="`pwd ${BUILD_PWD_OPTIONS}`"

#   cmake_keep_builddir="`read_build_setting "${name}" "cmake_keep_builddir" "YES"`"
#   if [ "${cmake_keep_builddir}" != "YES" ]
#   then
#      rmdir_safer "${builddir}"
#   fi
   mkdir_if_missing "${builddir}"
   exekutor cd "${builddir}" || fail "failed to enter ${builddir}"

      # DONT READ CONFIG SETTING IN THIS INDENT
      set -f

      logfile1="${owd}/${logfile1}"
      logfile2="${owd}/${logfile2}"

      if [ "$MULLE_BOOTSTRAP_VERBOSE_BUILD" = "YES" ]
      then
         logfile1="`tty`"
         logfile2="$logfile1"
      fi
      if [ "$MULLE_EXECUTOR_DRY_RUN" = "YES" ]
      then
         logfile1="/dev/null"
         logfile2="/dev/null"
      fi

      local frameworklines
      local librarylines
      local includelines

      frameworklines=
      librarylines=
      includelines=

      if [ ! -z "${suffixsubdir}" ]
      then
         frameworklines="`add_cmake_path "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}/${FRAMEWORK_DIR_NAME}"`"
         librarylines="`add_cmake_path "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}/${LIBRARY_DIR_NAME}"`"
      fi

      if [ ! -z "${mappedsubdir}" -a "${mappedsubdir}" != "${suffixsubdir}" ]
      then
         frameworklines="`add_cmake_path "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${FRAMEWORK_DIR_NAME}"`"
         librarylines="`add_cmake_path "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${LIBRARY_DIR_NAME}"`"
      fi

      if [ ! -z "${fallbacksubdir}" -a "${fallbacksubdir}" != "${suffixsubdir}" -a "${fallbacksubdir}" != "${mappedsubdir}" ]
      then
         frameworklines="`add_cmake_path "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${fallbacksubdir}/${FRAMEWORK_DIR_NAME}"`"
         librarylines="`add_cmake_path "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${fallbacksubdir}/${LIBRARY_DIR_NAME}"`"
      fi

      includelines="`add_cmake_path "${includelines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}/${HEADER_DIR_NAME}"`"
      includelines="`add_cmake_path "${includelines}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}/${HEADER_DIR_NAME}"`"

      librarylines="`add_cmake_path "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}/${LIBRARY_DIR_NAME}"`"
      librarylines="`add_cmake_path "${librarylines}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}/${LIBRARY_DIR_NAME}"`"

      frameworklines="`add_cmake_path "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}/${FRAMEWORK_DIR_NAME}"`"
      frameworklines="`add_cmake_path "${frameworklines}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}/${FRAMEWORK_DIR_NAME}"`"

      if [ "${ADD_USR_LOCAL}" = "YES" ]
      then
         includelines="`add_cmake_path "${includelines}" "${USR_LOCAL_INCLUDE}"`"
         librarylines="`add_cmake_path "${librarylines}" "${USR_LOCAL_LIB}"`"
      fi

      local relative_srcdir
      local prefixbuild
      local dependenciesdir
      local addictionsdir
      local cmakemodulepath

      relative_srcdir="`relative_path_between "${owd}/${srcdir}" "${PWD}"`"

      prefixbuild="`add_cmake_path "${prefixbuild}" "${nativewd}/${BUILD_DEPENDENCIES_DIR}"`"
      dependenciesdir="`add_cmake_path "${dependenciesdir}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}"`"
      addictionsdir="`add_cmake_path "${addictionsdir}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}"`"

#      cmakemodulepath="\${CMAKE_MODULE_PATH}"
#      if [ ! -z "${CMAKE_MODULE_PATH}" ]
#      then
#         cmakemodulepath="${CMAKE_MODULE_PATH}${PATH_SEPARATOR}${cmakemodulepath}"   # prepend
#      fi

      local native_includelines
      local native_librarylines
      local native_frameworklines

      native_includelines="${includelines}"
      native_librarylines="${librarylines}"
      native_frameworklines="${frameworklines}"

      local frameworkprefix
      local libraryprefix
      local includeprefix

      frameworkprefix=
      libraryprefix="-L"
      includeprefix="-I"

      case "${UNAME}" in
         darwin)
            frameworkprefix="-F"
         ;;

         mingw)
            relative_srcdir="`echo "${relative_srcdir}" | tr '/' '\\'  2> /dev/null`"
            native_includelines="`echo "${native_includelines}" | tr '/' '\\'  2> /dev/null`"
            native_librarylines="`echo "${native_librarylines}" | tr '/' '\\'  2> /dev/null`"
            libraryprefix="/LIBPATH:"
            includeprefix="/I"
            frameworklines=
            native_frameworklines=
         ;;

         *)
            frameworklines=
            native_frameworklines=
         ;;
      esac

      # assemble -I /I and -L /LIBPATH:


      # cmake separator
      [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"
      IFS=";"
      for path in ${native_includelines}
      do
         IFS="${DEFAULT_IFS}"
         other_cflags="`concat "${other_cflags}" "${includeprefix}${path}"`"
         other_cxxflags="`concat "${other_cxxflags}" "${includeprefix}${path}"`"
      done

      IFS=";"
      for path in ${native_librarylines}
      do
         IFS="${DEFAULT_IFS}"
         other_ldflags="`concat "${other_ldflags}" "${libraryprefix}${path}"`"
      done

      IFS=";"
      for path in ${native_frameworklines}
      do
         IFS="${DEFAULT_IFS}"
         other_cflags="`concat "${other_cflags}" "${frameworkprefix}${path}"`"
         other_cxxflags="`concat "${other_cxxflags}" "${frameworkprefix}${path}"`"
         other_ldflags="`concat "${other_ldflags}" "${frameworkprefix}${path}"`"
      done

      IFS=";"
      if [ MULLE_BOOTSTRAP_VERBOSE_BUILD = "YES" ]
      then
         IFS="${DEFAULT_IFS}"
         local_make_flags="${local_make_flags} VERBOSE=1"
      fi

      IFS="${DEFAULT_IFS}"

      local oldpath
      local rval

      [ -z "${BUILDPATH}" ] && internal_fail "BUILDPATH not set"

      oldpath="$PATH"
      PATH="${BUILDPATH}"

      logging_redirect_eval_exekutor "${logfile1}" "'${CMAKE}'" \
-G "'${CMAKE_GENERATOR}'" \
"-DMULLE_BOOTSTRAP_VERSION=${MULLE_BOOTSTRAP_VERSION}" \
"-DCMAKE_BUILD_TYPE='${mapped}'" \
"-DDEPENDENCIES_DIR='${dependenciesdir}'" \
"-DADDICTIONS_DIR='${addictionsdir}'" \
"-DCMAKE_INSTALL_PREFIX:PATH='${prefixbuild}'"  \
"-DCMAKE_INCLUDE_PATH='${includelines}'" \
"-DCMAKE_LIBRARY_PATH='${librarylines}'" \
"-DCMAKE_FRAMEWORK_PATH='${frameworklines}'" \
"-DCMAKE_C_FLAGS='${other_cflags}'" \
"-DCMAKE_CXX_FLAGS='${other_cxxflags}'" \
"-DCMAKE_EXE_LINKER_FLAGS='${other_ldflags}'" \
"-DCMAKE_SHARED_LINKER_FLAGS='${other_ldflags}'" \
"${sdkparameter}" \
"${c_compiler_line}" \
"${cxx_compiler_line}" \
"${localcmakeflags}" \
"${CMAKE_FLAGS}" \
"'${relative_srcdir}'"
      rval=$?

      if [ $rval -ne 0 ]
      then
         PATH="${oldpath}"
         build_fail "${logfile1}" "cmake"
      fi

      logging_redirekt_exekutor "${logfile2}" "${MAKE}" ${MAKE_FLAGS} ${local_make_flags} install
      rval=$?

      PATH="${oldpath}"
      [ $rval -ne 0 ] && build_fail "${logfile2}" "make"

      set +f

   exekutor cd "${owd}"

   local depend_subdir

   depend_subdir="`determine_dependencies_subdir "${suffix}"`"
   collect_and_dispense_product "${name}" "${suffixsubdir}" "${depend_subdir}" || internal_fail "collect failed silently"
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
   local name
   local sdk

   configuration="$1"
   srcdir="$2"
   builddir="$3"
   name="$4"
   sdk="$5"

   if [ -z "${MAKE}" ]
   then
      fail "No make available"
   fi

   enforce_build_sanity "${builddir}"

   log_info "Let ${C_RESET_BOLD}configure${C_INFO} do a \
${C_MAGENTA}${C_BOLD}${configuration}${C_INFO} build of \
${C_MAGENTA}${C_BOLD}${name}${C_INFO} for SDK \
${C_MAGENTA}${C_BOLD}${sdk}${C_INFO} in \"${builddir}\" ..."

   local sdkpath
   local fallback
   local mapped
   local suffix
   local fallback
   local configureflags

   fallback="`echo "${CONFIGURATIONS}" | tail -1`"
   fallback="`read_build_setting "${name}" "fallback-configuration" "${fallback}"`"

   configureflags="`read_build_setting "${name}" "configure_flags"`"

   mapped="`read_build_setting "${name}" "configure-${configuration}.map" "${configuration}"`"
   suffix="`determine_suffix "${configuration}" "${sdk}"`"
   sdkpath="`gcc_sdk_parameter "${sdk}"`"
   sdkpath="`echo "${sdkpath}" | sed -e 's/ /\\ /g'`"

   create_dummy_dirs_against_warnings "${mapped}" "${suffix}"

   local mappedsubdir
   local fallbacksubdir
   local suffixsubdir

   mappedsubdir="`determine_dependencies_subdir "${mapped}"`"
   suffixsubdir="`determine_dependencies_subdir "${suffix}"`"
   fallbacksubdir="`determine_dependencies_subdir "${fallback}"`"

   local other_cflags
   local other_cxxflags
   local other_ldflags

   other_cflags="`gcc_cflags_value "${name}"`"
   other_cxxflags="`gcc_cxxflags_value "${name}"`"
   other_ldflags="`gcc_ldflags_value "${name}"`"

   local logfile1
   local logfile2

   mkdir_if_missing "${BUILDLOG_SUBDIR}"

   logfile1="`build_log_name "configure" "${name}" "${configuration}" "${sdk}"`"
   logfile2="`build_log_name "make" "${name}" "${configuration}" "${sdk}"`"

   log_verbose "Build logs will be in \"${logfile1}\" and \"${logfile2}\""

   local owd
   local nativewd

   owd="${PWD}"
   nativewd="`pwd ${BUILD_PWD_OPTIONS}`"

   mkdir_if_missing "${builddir}"
   exekutor cd "${builddir}" || fail "failed to enter ${builddir}"

      # DONT READ CONFIG SETTING IN THIS INDENT
       set -f

      logfile1="${owd}/${logfile1}"
      logfile2="${owd}/${logfile2}"

      if [ "$MULLE_BOOTSTRAP_VERBOSE_BUILD" = "YES" ]
      then
         logfile1="`tty`"
         logfile2="$logfile1"
      fi
      if [ "$MULLE_EXECUTOR_DRY_RUN" = "YES" ]
      then
         logfile1="/dev/null"
         logfile2="/dev/null"
      fi

      local frameworklines
      local librarylines
      local includelines

      frameworklines=
      librarylines=
      includelines=

      if [ ! -z "${suffixsubdir}" ]
      then
         frameworklines="`add_path "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}/${FRAMEWORK_DIR_NAME}"`"
         librarylines="`add_path "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}/${LIBRARY_DIR_NAME}"`"
      fi

      if [ ! -z "${mappedsubdir}" -a "${mappedsubdir}" != "${suffixsubdir}" ]
      then
         frameworklines="`add_path "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${FRAMEWORK_DIR_NAME}"`"
         librarylines="`add_path "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${LIBRARY_DIR_NAME}"`"
      fi

      if [ ! -z "${fallbacksubdir}" -a "${fallbacksubdir}" != "${suffixsubdir}" -a "${fallbacksubdir}" != "${mappedsubdir}" ]
      then
         frameworklines="`add_path "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${fallbacksubdir}/${FRAMEWORK_DIR_NAME}"`"
         librarylines="`add_path "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${fallbacksubdir}/${LIBRARY_DIR_NAME}"`"
      fi

      includelines="`add_path "${includelines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}/${HEADER_DIR_NAME}"`"
      includelines="`add_path "${includelines}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}/${HEADER_DIR_NAME}"`"

      librarylines="`add_path "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}/${LIBRARY_DIR_NAME}"`"
      librarylines="`add_path "${librarylines}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}/${LIBRARY_DIR_NAME}"`"

      frameworklines="`add_path "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}/${FRAMEWORK_DIR_NAME}"`"
      frameworklines="`add_path "${frameworklines}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}/${FRAMEWORK_DIR_NAME}"`"

      if [ "${ADD_USR_LOCAL}" = "YES" ]
      then
         includelines="`add_path "${includelines}" "${USR_LOCAL_INCLUDE}"`"
         librarylines="`add_path "${librarylines}" "${USR_LOCAL_LIB}"`"
      fi

      local prefixbuild
      local dependenciesdir
      local addictionsdir
      #local linker

      pathrefixbuild="`add_path "${prefixbuild}" "${nativewd}/${BUILD_DEPENDENCIES_DIR}"`"
      dependenciesdir="`add_path "${dependenciesdir}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}"`"
      addictionsdir="`add_path "${addictionsdir}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}"`"

      case "${UNAME}" in
         darwin)
            other_cflags="`concat "${other_cflags}" "-isysroot ${sdkpath}"`"
            other_ldflags="`concat "${other_ldflags}" "-isysroot ${sdkpath}"`"
         ;;

         *)
            frameworklines=
         ;;
      esac

      # assemble -I /I and -L /LIBPATH:


      IFS="${PATH_SEPARATOR}"
      for path in ${includelines}
      do
         IFS="${DEFAULT_IFS}"
         other_cflags="`concat "${other_cflags}" "${includeprefix}${path}"`"
      done

      IFS="${PATH_SEPARATOR}"
      for path in ${librarylines}
      do
         IFS="${DEFAULT_IFS}"
         other_ldflags="`concat "${other_ldflags}" "${libraryprefix}${path}"`"
      done

      IFS="${PATH_SEPARATOR}"
      for path in ${frameworklines}
      do
         IFS="${DEFAULT_IFS}"
         other_cflags="`concat "${other_cflags}" "${frameworkprefix}${path}"`"
         other_ldflags="`concat "${other_ldflags}" "${frameworkprefix}${path}"`"
      done

      other_cxxflags"`concat "${other_cflags}" "${other_cxxflags}"`"
      IFS="${DEFAULT_IFS}"

      local oldpath
      local rval

      oldpath="$PATH"
      PATH="${BUILDPATH}"

      # use absolute paths for configure, safer (and easier to read IMO)
      logging_eval_redirekt_exekutor "${logfile1}" \
         DEPENDENCIES_DIR="'${dependenciesdir}'" \
         ADDICTIONS_DIR="'${addictionsdir}'" \
         CC="'${C_COMPILER:-${CC}}'" \
         CXX="'${CXX_COMPILER:-${CXX}}'" \
         CFLAGS="'${other_cflags}'" \
         CXXFLAGS="'${other_cxxflags}'" \
         LDFLAGS="'${other_ldflags}'" \
         "'${owd}/${srcdir}/configure'" \
            "${configureflags}" \
             --prefix "'${prefixbuild}'"
      rval=$?

      if [ $rval -ne 0 ]
      then
         PATH="${oldpath}"
         build_fail "${logfile1}" "configure"
      fi

      logging_redirekt_exekutor "${logfile2}" "${MAKE}" ${MAKE_FLAGS} install
      rval=$?

      PATH="${oldpath}"
      [ $rval -ne 0 ] && build_fail "${logfile2}" "make"

      PATH="${oldpath}"
      set +f

   exekutor cd "${owd}"

   local depend_subdir

   depend_subdir="`determine_dependencies_subdir "${suffix}"`"
   collect_and_dispense_product "${name}" "${suffixsubdir}" "${depend_subdir}" || exit 1
}


_xcode_get_setting()
{
   eval_exekutor "xcodebuild -showBuildSettings $*" || fail "failed to read xcode settings"
}


xcode_get_setting()
{
   local key

   key="$1"
   shift

   _xcode_get_setting "$@" | egrep "^[ ]*${key}" | sed 's/^[^=]*=[ ]*\(.*\)/\1/'
}


#
# Code I didn't want to throw away really
# In general just use "public_headers" or
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

   headers=`xcode_get_setting "${key}" $*` || exit 1
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
      prefix="${HEADER_DIR_NAME}"
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
      read_yes_no_build_setting "${name}" "xcode_mangle_header_paths"
      if [ $? -ne 0 ]
      then
         return 1
      fi

      headers="`create_mangled_header_path "${key}" "${name}" "${default}"`"
   fi

   log_fluff "${key} set to \"${headers}\""

   echo "${headers}"
}


build_xcodebuild()
{
   local configuration
   local srcdir
   local builddir
   local name
   local sdk
   local project
   local schemename
   local targetname

   configuration="$1"
   srcdir="$2"
   builddir="$3"
   name="$4"
   sdk="$5"
   project="$6"
   schemename="$7"
   targetname="$8"

   [ ! -z "${configuration}" ] || internal_fail "configuration is empty"
   [ ! -z "${srcdir}" ]        || internal_fail "srcdir is empty"
   [ ! -z "${builddir}" ]      || internal_fail "builddir is empty"
   [ ! -z "${name}" ]          || internal_fail "name is empty"
   [ ! -z "${sdk}" ]           || internal_fail "sdk is empty"
   [ ! -z "${project}" ]       || internal_fail "project is empty"

   enforce_build_sanity "${builddir}"

   toolname=`read_config_setting "xcodebuild" "xcodebuild"`

   local info

   info=""
   if [ ! -z "${targetname}" ]
   then
      info=" Target ${C_MAGENTA}${C_BOLD}${targetname}${C_INFO}"
   fi

   if [ ! -z "${schemename}" ]
   then
      info=" Scheme ${C_MAGENTA}${C_BOLD}${schemename}${C_INFO}"
   fi

   log_info "Let ${C_RESET_BOLD}${toolname}${C_INFO} do a \
${C_MAGENTA}${C_BOLD}${configuration}${C_INFO} build of \
${C_MAGENTA}${C_BOLD}${name}${C_INFO} for SDK \
${C_MAGENTA}${C_BOLD}${sdk}${C_INFO}${info} in \
\"${builddir}\" ..."

   local projectname

    # always pass project directly
   projectname=`read_repo_setting "${name}" "xcode_project" "${project}"`

   local mapped
   local fallback

   fallback="`echo "${CONFIGURATIONS}" | tail -1`"
   fallback="`read_build_setting "${name}" "fallback-configuration" "${fallback}"`"

   mapped=`read_build_setting "${name}" "${configuration}.map" "${configuration}"`
   [ -z "${mapped}" ] && internal_fail "mapped configuration is empty"

   local hackish
   local targetname
   local suffix

   suffix="${configuration}"
   if [ "${sdk}" != "Default" ]
   then
      hackish="`echo "${sdk}" | sed 's/^\([a-zA-Z]*\).*$/\1/g'`"
      suffix="${suffix}-${hackish}"
   else
      sdk=
   fi

   create_dummy_dirs_against_warnings "${mapped}" "${suffix}"

   local mappedsubdir
   local fallbacksubdir
   local suffixsubdir

   mappedsubdir="`determine_dependencies_subdir "${mapped}"`"
   suffixsubdir="`determine_dependencies_subdir "${suffix}"`"
   fallbacksubdir="`determine_dependencies_subdir "${fallback}"`"

   local xcode_proper_skip_install
   local skip_install

   skip_install=
   xcode_proper_skip_install=`read_build_setting "${name}" "xcode_proper_skip_install" "NO"`
   if [ "$xcode_proper_skip_install" != "YES" ]
   then
      skip_install="SKIP_INSTALL=NO"
   fi

   local toolname

   #
   # xctool needs schemes, these are often autocreated, which xctool cant do
   # xcodebuild can just use a target
   # xctool is by and large useless fluff IMO
   #
   if [ "${toolname}" = "xctool"  -a "${schemename}" = ""  ]
   then
      if [ "$targetname" != "" ]
      then
         schemename="${targetname}"
         targetname=
      else
         echo "Please specify a scheme to compile in ${BOOTSTRAP_DIR}/${name}/SCHEME for xctool" >& 2
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

   if [ "$MULLE_EXECUTOR_DRY_RUN" != "" ]
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
   public_headers="`fixup_header_path "PUBLIC_HEADERS_FOLDER_PATH" "xcode_public_headers" "${name}" "${default}" ${arguments}`"
   default="/include/${name}/private"
   private_headers="`fixup_header_path "PRIVATE_HEADERS_FOLDER_PATH" "xcode_private_headers" "${name}" "${default}" ${arguments}`"


   local logfile

   mkdir_if_missing "${BUILDLOG_SUBDIR}"

   logfile="`build_log_name "${toolname}" "${name}" "${configuration}" "${targetname}" "${schemename}" "${sdk}"`"
   log_verbose "Build log will be in: ${C_RESET_BOLD}${logfile}${C_VERBOSE}"

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

# an empty xcconfig is nice, because it acts as a reset for
   local xcconfig

   xcconfig=`read_repo_setting "${name}" "xcconfig"`
   if [ ! -z "${xcconfig}" ]
   then
      arguments="${arguments} -xcconfig \"${xcconfig}\""
   fi

   local other_cflags
   local other_cxxflags
   local other_ldflags

   other_cflags="`gcc_cflags_value "${name}"`"
   other_cxxflags="`gcc_cxxflags_value "${name}"`"
   other_ldflags="`gcc_ldflags_value "${name}"`"

   if [ ! -z "${other_cflags}" ]
   then
      other_cflags="OTHER_CFLAGS=${other_cflags}"
   fi
   if [ ! -z "${other_cxxflags}" ]
   then
      other_cxxflags="other_cxxflags=${other_cxxflags}"
   fi
   if [ ! -z "${other_ldflags}" ]
   then
      other_ldflags="OTHER_LDFLAGS=${other_ldflags}"
   fi

   owd=`pwd`
   exekutor cd "${srcdir}" || exit 1

      # DONT READ CONFIG SETTING IN THIS INDENT
      logfile="${owd}/${logfile}"

      if [ "${MULLE_BOOTSTRAP_VERBOSE_BUILD}" = "YES" ]
      then
         logfile="`tty`"
      fi
      if [ "$MULLE_EXECUTOR_DRY_RUN" = "YES" ]
      then
         logfile="/dev/null"
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
      inherited="`xcode_get_setting HEADER_SEARCH_PATHS ${arguments}`" || exit 1
      path=`combined_escaped_search_path \
"${owd}/${REFERENCE_DEPENDENCIES_DIR}/${HEADER_DIR_NAME}" \
"${owd}/${REFERENCE_ADDICTIONS_DIR}/${HEADER_DIR_NAME}"`
      if [ -z "${inherited}" ]
      then
         dependencies_header_search_path="${path}"
      else
         dependencies_header_search_path="${path} ${inherited}"
      fi

      inherited="`xcode_get_setting LIBRARY_SEARCH_PATHS ${arguments}`" || exit 1
      path=`combined_escaped_search_path \
"${owd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${LIBRARY_DIR_NAME}" \
"${owd}/${REFERENCE_DEPENDENCIES_DIR}${fallbacksubdir}/${LIBRARY_DIR_NAME}" \
"${owd}/${REFERENCE_DEPENDENCIES_DIR}/${LIBRARY_DIR_NAME}" \
"${owd}/${REFERENCE_ADDICTIONS_DIR}/${LIBRARY_DIR_NAME}"`
      if [ ! -z "$sdk" ]
      then
         escaped="`escaped_spaces "${owd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${LIBRARY_DIR_NAME}"'-$(EFFECTIVE_PLATFORM_NAME)'`"
         path="${escaped} ${path}" # prepend
      fi
      if [ -z "${inherited}" ]
      then
         dependencies_lib_search_path="${path}"
      else
         dependencies_lib_search_path="${path} ${inherited}"
      fi

      if [ "${ADD_USR_LOCAL}" = "YES" ]
      then
         dependencies_header_search_path="${path} ${USR_LOCAL_INCLUDE}"
         dependencies_lib_search_path="${path} ${USR_LOCAL_LIB}"
      fi

      inherited="`xcode_get_setting FRAMEWORK_SEARCH_PATHS ${arguments}`" || exit 1
      path=`combined_escaped_search_path \
"${owd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${FRAMEWORK_DIR_NAME}" \
"${owd}/${REFERENCE_DEPENDENCIES_DIR}${fallbacksubdir}/${FRAMEWORK_DIR_NAME}" \
"${owd}/${REFERENCE_DEPENDENCIES_DIR}/${FRAMEWORK_DIR_NAME}" \
"${owd}/${REFERENCE_ADDICTIONS_DIR}/${FRAMEWORK_DIR_NAME}"`
      if [ ! -z "$sdk" ]
      then
         escaped="`escaped_spaces "${owd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${FRAMEWORK_DIR_NAME}"'-$(EFFECTIVE_PLATFORM_NAME)'`"
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

      local oldpath
      local rval

      oldpath="${PATH}"
      PATH="${BUILDPATH}"
      # if it doesn't install, probably SKIP_INSTALL is set
      cmdline="\"${XCODEBUILD}\" \"${command}\" ${arguments} \
ARCHS='${ARCHS:-\${ARCHS_STANDARD_32_64_BIT}}' \
DSTROOT='${owd}/${BUILD_DEPENDENCIES_DIR}' \
SYMROOT='${owd}/${builddir}/' \
OBJROOT='${owd}/${builddir}/obj' \
DEPENDENCIES_DIR='${owd}/${REFERENCE_DEPENDENCIES_DIR}' \
ADDICTIONS_DIR='${owd}/${REFERENCE_ADDICTIONS_DIR}' \
ONLY_ACTIVE_ARCH=${ONLY_ACTIVE_ARCH:-NO} \
${skip_install} \
${other_cflags} \
${other_cxxflags} \
${other_ldflags} \
${XCODEBUILD_FLAGS} \
HEADER_SEARCH_PATHS='${dependencies_header_search_path}' \
LIBRARY_SEARCH_PATHS='${dependencies_lib_search_path}' \
FRAMEWORK_SEARCH_PATHS='${dependencies_framework_search_path}'"

      logging_redirect_eval_exekutor "${logfile}" "${cmdline}"
      rval=$?

      PATH="${oldpath}"
      [ $rval -ne 0 ] && build_fail "${logfile}" "${toolname}"
      set +f

   exekutor cd "${owd}"

   local depend_subdir

   depend_subdir="`determine_dependencies_subdir "${suffix}"`"
   collect_and_dispense_product "${name}" "${suffixsubdir}" "${depend_subdir}" "YES" || exit 1
}


build_xcodebuild_schemes_or_target()
{
   local builddir
   local name
   local project

   builddir="$3"
   name="$4"
   project="$6"

   local scheme
   local schemes

   schemes=`read_repo_setting "${name}" "xcode_schemes"`

   IFS="
"
   for scheme in $schemes
   do
      IFS="${DEFAULT_IFS}"
      log_fluff "Building scheme \"${scheme}\" of \"${project}\" ..."
      build_xcodebuild "$@" "${scheme}" ""
   done
   IFS="${DEFAULT_IFS}"

   local target
   local targets

   targets=`read_repo_setting "${name}" "xcode_targets"`

   IFS="
"
   for target in $targets
   do
      IFS="${DEFAULT_IFS}"
      log_fluff "Building target \"${target}\" of \"${project}\" ..."
      build_xcodebuild "$@" "" "${target}"
   done
   IFS="${DEFAULT_IFS}"

   if [ "${targets}" = "" -a "${schemes}" = "" ]
   then
      log_fluff "Building project \"${project}\"..."
      build_xcodebuild "$@"
   fi
}


run_build_script()
{
   local script

   script="$1"
   shift

   [ ! -z "$script" ] || internal_fail "script is empty"

   if [ -x "${script}" ]
   then
      log_fluff "Executing script \"${script}\" $1"
      exekutor "${script}" "$@"
   else
      if [ ! -e "${script}" ]
      then
         fail "script \"${script}\" not found ($PWD)"
      else
         fail "script \"${script}\" not executable"
      fi
   fi
}


run_log_build_script()
{
   echo "$@"
   run_build_script "$@"
}


build_script()
{
   local script

   script="$1"
   shift

   local configuration
   local srcdir
   local builddir
   local name
   local sdk

   configuration="$1"
   srcdir="$2"
   builddir="$3"
   name="$4"
   sdk="$5"

   local project
   local schemename
   local targetname
   local logfile

   mkdir_if_missing "${BUILDLOG_SUBDIR}"

   logfile="${BUILDLOG_SUBDIR}/${name}-${configuration}-${sdk}.script.log"
   log_fluff "Build log will be in: ${C_RESET_BOLD}${logfile}${C_INFO}"

   mkdir_if_missing "${builddir}"

   local owd

   owd=`pwd`
   exekutor cd "${srcdir}" || exit 1

      logfile="${owd}/${logfile}"

      if [ "$MULLE_BOOTSTRAP_VERBOSE_BUILD" = "YES" ]
      then
         logfile="`tty`"
      fi
      if [ "$MULLE_EXECUTOR_DRY_RUN" = "YES" ]
      then
         logfile="/dev/null"
      fi

      log_info "Let ${C_RESET_BOLD}script${C_INFO} do a \
${C_MAGENTA}${C_BOLD}${configuration}${C_INFO} build of \
${C_MAGENTA}${C_BOLD}${name}${C_INFO} for SDK \
${C_MAGENTA}${C_BOLD}${sdk}${C_INFO}${info} in \
\"${builddir}\" ..."

      local oldpath
      local rval

      oldpath="${PATH}"
      PATH="${BUILDPATH}"

      run_log_build_script "${owd}/${script}" \
         "${configuration}" \
         "${owd}/${srcdir}" \
         "${owd}/${builddir}" \
         "${owd}/${BUILD_DEPENDENCIES_DIR}" \
         "${name}" \
         "${sdk}" > "${logfile}"
      rval=$?

      PATH="${oldpath}"
      [ $rval -ne 0 ] && build_fail "${logfile}" "build.sh"

   exekutor cd "${owd}"

   local suffix
   local depend_subdir
   local suffixsubdir

   suffix="`determine_suffix "${configuration}" "${sdk}"`"
   suffixsubdir="`determine_build_subdir "${suffix}"`"
   depend_subdir="`determine_dependencies_subdir "${suffix}"`"
   collect_and_dispense_product "${name}" "${suffixsubdir}" "${depend_subdir}" || internal_fail "collect failed silently"
}


build_with_configuration_sdk_preferences()
{
   local name
   local configuration
   local sdk
   local preferences

   name="$1"
   [ $# -ne 0 ] && shift
   configuration="$1"
   [ $# -ne 0 ] && shift
   sdk="$1"
   [ $# -ne 0 ] && shift
   preferences="$1"
   [ $# -ne 0 ] && shift

   if [ "/${configuration}" = "/${LIBRARY_DIR_NAME}" -o "/${configuration}" = "${HEADER_DIR_NAME}" -o "/${configuration}" = "${FRAMEWORK_DIR_NAME}" ]
   then
      fail "You are just asking for trouble naming your configuration \"${configuration}\"."
   fi

   if [ "${configuration}" = "lib" -o "${configuration}" = "include" -o "${configuration}" = "Frameworks" ]
   then
      fail "You are just asking for major trouble naming your configuration \"${configuration}\"."
   fi

   local builddir

   builddir="${CLONESBUILD_SUBDIR}/${configuration}/${name}"

   if [ -d "${builddir}" -a "${CLEAN_BEFORE_BUILD}" = "YES" ]
   then
      log_fluff "Cleaning build directory \"${builddir}\""
      rmdir_safer "${builddir}"
   fi

   #
   # execute pre-build script (f.e. for libcurl)
   #
   local script

   script="`find_build_setting_file "${name}" "bin/pre-build.sh"`"
   if [ -x "${script}" ]
   then
      build_script "${script}" "${configuration}" "${srcdir}" "${builddir}" "${name}" "${sdk}" || exit 1
   fi

   local project

   for preference in ${preferences}
   do
      case "${preference}" in
         script)
            script="`find_build_setting_file "${name}" "bin/build.sh"`"
            if [ -x "${script}" ]
            then
               build_script "${script}" "${configuration}" "${srcdir}" "${builddir}" "${name}" "${sdk}" || exit 1
               return 0
            else
               [ ! -e "${script}" ] || fail "script ${script} is not executable"
            fi
         ;;

         xcodebuild)
            if [ ! -z "${XCODEBUILD}" ]
            then
               project=`(cd "${srcdir}" ; find_xcodeproj "${name}")`

               if [ ! -z "$project" ]
               then
                  build_xcodebuild_schemes_or_target "${configuration}" "${srcdir}" "${builddir}" "${name}" "${sdk}" "${project}"  || exit 1
                  return 0
               fi
            fi
         ;;

         configure)
            if [ ! -f "${srcdir}/configure" ]
            then
               # try for autogen if installed (not coded yet)
               :
            fi
            if [ -x "${srcdir}/configure" ]
            then
               if [ -z "${MAKE}" ]
               then
                  log_warning "Found a configure, but make is not installed"
               else
                  build_configure "${configuration}" "${srcdir}" "${builddir}" "${name}" "${sdk}"  || exit 1
                  return 0
               fi
            fi
         ;;

         cmake)
            if [ -f "${srcdir}/CMakeLists.txt" ]
            then
               if [ -z "${CMAKE}" ]
               then
                  log_warning "Found a CMakeLists.txt, but cmake is not installed"
               else
                  build_cmake "${configuration}" "${srcdir}" "${builddir}" "${name}" "${sdk}"  || exit 1
                  return 0
               fi
            fi
         ;;

         *)
            fail "Unknown build preference \"$1\""
         ;;
      esac
   done

   return 1
}


build()
{
   local name
   local srcdir

   name="$1"
   srcdir="$2"

   [ "${name}" != "${REPOS_DIR}" ] || internal_fail "missing repo argument (${srcdir})"

   log_verbose "Building ${name} ..."

   # find make, cmake compilers for this repo

   tools_environment "${name}"

   local preferences

   #
   # repo may override how it wants to be build
   #
   preferences="`read_build_setting "${name}" "build_preferences"`"

   if [ -z "${preferences}" ]
   then
      case "${UNAME}" in
         darwin)
            preferences="`read_config_setting "build_preferences" "script
cmake
configure
xcodebuild"`"
         ;;


         *)
            preferences="`read_config_setting "build_preferences" "script
cmake
configure"`"
         ;;
      esac
   fi

   local configurations
   local configuration
   local sdks
   local sdk

   # need uniform SDK for our builds
   sdks=`read_build_root_setting "sdks" "Default"`
   [ ! -z "${sdks}" ] || fail "setting \"sdks\" must at least contain \"Default\" to build anything"

   # settings can override the commandline default
   configurations="`read_repo_setting "${name}" "configurations" "${CONFIGURATIONS}"`"

   for sdk in ${sdks}
   do
      # remap macosx to Default, as EFFECTIVE_PLATFORM_NAME will not be appeneded by Xcode
      if [ "$sdk" = "macosx" ]
      then
         sdk="Default"
      fi

      for configuration in ${configurations}
      do
         build_with_configuration_sdk_preferences "${name}" "${configuration}" "${sdk}" "${preferences}"
         if [ $? -ne 0 ]
         then
            fail "Don't know how to build ${name}"
         fi
      done
   done
}


#
# ${DEPENDENCIES_DIR} is split into
#
#  REFERENCE_DEPENDENCIES_DIR and
#  BUILD_DEPENDENCIES_DIR
#
# above this function, noone should access ${DEPENDENCIES_DIR}
#
build_wrapper()
{
   local srcdir
   local name

   name="$1"
   srcdir="$2"

   REFERENCE_ADDICTIONS_DIR="${ADDICTIONS_DIR}"
   REFERENCE_DEPENDENCIES_DIR="${DEPENDENCIES_DIR}"
   BUILD_DEPENDENCIES_DIR="${DEPENDENCIES_DIR}/tmp"

   DEPENDENCIES_DIR="WRONG_DONT_USE_DEPENDENCIES_DIR_DURING_BUILD"
   ADDICTIONS_DIR="WRONG_DONT_USE_ADDICTIONS_DIR_DURING_BUILD"

   log_fluff "Setting up BUILD_DEPENDENCIES_DIR as \"${BUILD_DEPENDENCIES_DIR}\""

   if [ "${COMMAND}" != "ibuild" -a -d "${BUILD_DEPENDENCIES_DIR}" ]
   then
      log_fluff "Cleaning up orphaned \"${BUILD_DEPENDENCIES_DIR}\""
      rmdir_safer "${BUILD_DEPENDENCIES_DIR}"
   fi


   #
   # move dependencies we have so far away into safety,
   # need that path for includes though
   #

   run_repo_settings_script "${name}" "${srcdir}" "pre-build" "$@" || exit 1

   build "${name}" "${srcdir}" || exit 1

   run_repo_settings_script "${name}" "${srcdir}" "post-build" "$@" || exit 1

   if [ "${COMMAND}" != "ibuild"  ]
   then
      log_fluff "Remove \"${BUILD_DEPENDENCIES_DIR}\""
      rmdir_safer "${BUILD_DEPENDENCIES_DIR}"
   fi

   DEPENDENCIES_DIR="${REFERENCE_DEPENDENCIES_DIR}"
   ADDICTIONS_DIR="${REFERENCE_ADDICTIONS_DIR}"

   # for mulle-bootstrap developers
   REFERENCE_DEPENDENCIES_DIR="WRONG_DONT_USE_REFERENCE_DEPENDENCIES_DIR_AFTER_BUILD"
   BUILD_DEPENDENCIES_DIR="WRONG_DONT_USE_BUILD_DEPENDENCIES_DIR_AFTER_BUILD"
}


build_if_alive()
{
   local name
   local srcdir

   name="$1"
   srcdir="$2"

   local xdone
   local zombie

   zombie="`dirname -- "${srcdir}"`/.zombies/${name}"
   if [ -e "${zombie}" ]
   then
      log_warning "Ignoring zombie repo ${name} as \"${zombie}${C_WARNING} exists"
   else
      xdone="`/bin/echo "${BUILT}" | grep -x "${name}"`"
      if [ "$xdone" = "" ]
      then
         build_wrapper "${name}" "${srcdir}"
         BUILT="${name}
${BUILT}"
      else
         log_fluff "Ignoring \"${name}\". (Either in \"build_ignore\" or already built)"
      fi
   fi
}


get_source_dir()
{
   local name

   name="$1"

   local srcdir
   local srcsubdir

   srcdir="${REPOS_DIR}/${name}"
   srcsubdir="`read_build_setting "${name}" "source_dir"`"
   if [ ! -z "${srcsubdir}" ]
   then
      srcdir="${srcdir}/${srcsubdir}"
   fi
   echo "${srcdir}"
}


build_clones()
{
   local clone

   IFS="
"
   for clone in `ls -1d ${REPOS_DIR}/*.failed 2> /dev/null`
   do
      IFS="${DEFAULT_IFS}"
      if [ -d "${clone}" ]
      then
         fail "failed checkout $clone detected, can't continue"
      fi
   done
   IFS="${DEFAULT_IFS}"

   run_build_root_settings_script "pre-build" "$@"

   # _parse_clone
   local name
   local url
   local branch
   local scm
   local tag

   #
   # build order is there, because we want to have gits
   # and maybe later hgs
   #
   BUILT="`read_build_root_setting "build_ignore"`"

   local srcdir

   if [ "$#" -eq 0 ]
   then
      clones="`read_fetch_setting "repositories"`"
      if [ "${clones}" != "" ]
      then
         IFS="
"
         for clone in ${clones}
         do
            IFS="${DEFAULT_IFS}"

            __parse_clone "${clone}"

            srcdir="`get_source_dir "${name}"`"

            if [ -d "${srcdir}" ]
            then
               build_if_alive "${name}" "${srcdir}" || exit  1
            else
               if [ "${CHECK_USR_LOCAL_INCLUDE}" = "YES" ] && has_usr_local_include "${name}"
               then
                  log_info "${C_MAGENTA}${C_BOLD}${name}${C_INFO} is a system library, so not building it"
                  :
               else
                  fail "build failed for repository \"${name}\": not found in (\"${srcdir}\") ($PWD)"
               fi
            fi
         done
      fi
   else
      for name in "$@"
      do
         srcdir="`get_source_dir "${name}"`"

         if [ -d "${srcdir}" ]
         then
            build_if_alive "${name}" "${srcdir}"|| exit 1
         else
            if [ "${CHECK_USR_LOCAL_INCLUDE}" = "YES" ] && has_usr_local_include "${name}"
            then
               log_info "${C_MAGENTA}${C_BOLD}${name}${C_INFO} is a system library, so not building it"
               :
            else
               fail "Unknown repo ${name}"
            fi
         fi
      done
   fi

   IFS="${DEFAULT_IFS}"

   run_build_root_settings_script "post-build" "$@"
}


have_tars()
{
   tarballs=`read_fetch_setting "tarballs"`
   [ "${tarballs}" != "" ]
}


install_tars()
{
   local tarballs
   local tar

   tarballs=`read_fetch_setting "tarballs" | sort | sort -u`
   if [ "${tarballs}" = "" ]
   then
      return 0
   fi

   IFS="
"
   for tar in ${tarballs}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -f "$tar" ]
      then
         fail "tarball \"$tar\" not found"
      else
         mkdir_if_missing "${DEPENDENCIES_DIR}"
         log_info "Installing tarball \"${tar}\""
         exekutor tar -xz -C "${DEPENDENCIES_DIR}" -f "${tar}" || fail "failed to extract ${tar}"
      fi
   done
   IFS="${DEFAULT_IFS}"
}


build_main()
{
   local  clean

   log_fluff "::: build begin :::"

   [ -z "${MULLE_BOOTSTRAP_BUILD_ENVIRONMENT_SH}" ] && . mulle-bootstrap-build-environment.sh

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   #
   # it is useful, that fetch understands build options and
   # ignores them
   #
   while [ $# -ne 0 ]
   do
      case "$1" in
         -K|--clean)
            CLEAN_BEFORE_BUILD="YES"
         ;;

         -k|--no-clean)
            CLEAN_BEFORE_BUILD=
         ;;

         --prefix)
            shift
            [ $# -ne 0 ] || fail "prefix missing"

            USR_LOCAL_INCLUDE="$1/include"
            USR_LOCAL_LIB="$1/lib"
         ;;


         -j|--cores)
            case "${UNAME}" in
               mingw)
                  build_usage
               ;;
            esac

            shift
            [ $# -ne 0 ] || fail "core count missing"

            CORES="$1"
         ;;

         --debug)
            CONFIGURATIONS="Debug"
         ;;

         --release)
            CONFIGURATIONS="Release"
         ;;

         -c|--configuration)
            shift
            [ $# -ne 0 ] || fail "configuration names missing"

            CONFIGURATIONS="`printf "%s" "$1" | tr ',' '\012'`"
            ;;

         -cs|--check-usr-local-include)
            # set environment to be picked up by config
            MULLE_BOOTSTRAP_CHECK_USR_LOCAL_INCLUDE="YES"
            export MULLE_BOOTSTRAP_CHECK_USR_LOCAL_INCLUDE
         ;;

         --use-prefix-libraries)
            ADD_USR_LOCAL=YES
         ;;

         # fetch options, are just ignored
         -i|--ignore-branch|-fc|--force-checkout|-nr|--no-recursion|-e|--embedded-only|-es|--embedded-symlink|-u|--update-symlinks)
            :
         ;;

         -*)
            log_error "${MULLE_BOOTSTRAP_FAIL_PREFIX}: Unknown build option $1"
            build_usage
         ;;

         ""|*)
            break
         ;;
      esac

      shift
      continue
   done


   #
   # START
   #
   if [ ! -d "${REPOS_DIR}" ]
   then
      log_info "No repositories in \"${REPOS_DIR}\", so nothing to build."
      return 0
   fi

   build_complete_environment

   [ -z "${MULLE_BOOTSTRAP_GCC_SH}" ] && . mulle-bootstrap-gcc.sh
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ] && . mulle-bootstrap-repositories.sh
   [ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ] && . mulle-bootstrap-scripts.sh

   CHECK_USR_LOCAL_INCLUDE="`read_config_setting "check_usr_local_include" "NO"`"

   remove_file_if_present "${REPOS_DIR}/.bootstrap_build_done"

   if [ $# -eq 0 ]
   then
      log_fluff "Setting up dependencies directory as \"${DEPENDENCIES_DIR}\""
      clean="`read_config_setting "clean_dependencies_before_build" "YES"`"
      if [ "${clean}" = "YES" ]
      then
         rmdir_safer "${DEPENDENCIES_DIR}"
      fi
   else
      log_fluff "Unprotecting \"${DEPENDENCIES_DIR}\" (as this is a partial build)."
      exekutor chmod -R u+w "${DEPENDENCIES_DIR}"
   fi

   # if present then we didnt't want to clean and we do nothing special
   if [ ! -d "${DEPENDENCIES_DIR}" ]
   then
      install_tars "$@"
   else
      if have_tars
      then
         log_warning "Tars have not been installed, as \"${DEPENDENCIES_DIR}\" already exists."
      fi
   fi

   build_clones "$@"

   if [ -d "${DEPENDENCIES_DIR}" ]
   then
      write_protect_directory "${DEPENDENCIES_DIR}"
   else
      log_fluff "No dependencies have been generated"
   fi

   create_file_if_missing "${REPOS_DIR}/.bootstrap_build_done"

   log_fluff "::: build end :::"
}


