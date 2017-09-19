#! /usr/bin/env bash
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
#
MULLE_BOOTSTRAP_BUILD_SH="included"


build_usage()
{
   local defk
   local defc
   local defkk

   defc="`printf "$OPTION_CONFIGURATIONS" | tr '\012' ','`"
   if [ "${OPTION_CLEAN_BEFORE_BUILD}" = "YES" ]
   then
      defk=""
      defkk="(default)"
   else
      defk="(default)"
      defkk=""
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_BOOTSTAP_EXECUTABLE} build [options] [repos]*
EOF

   cat <<EOF >&2
   You may specify the names of the repositories to build.
EOF

   local  repositories

   repositories="`all_repository_stashes`"
   if [ -z "${repositories}" ]
   then
      echo "Currently available repositories are:"
      echo "${repositories}" | sed 's/^/   /'
   fi

# to is experimental and maybe useless
#   --to <name>    :  force rebuild up to and including this project

   cat <<EOF >&2
Options:
   -c <name>      :  configurations to build ($defc), separate with comma
   --from <name>  :  force rebuild from this project
   -k             :  don't clean before building $defk
   -K             :  always clean before building $defkk
   --prefix <dir> :  use <dir> instead of /usr/local
EOF

   case "${UNAME}" in
      mingw*)
         :
      ;;

      *)
         cat <<EOF >&2
   -j             :  number of cores parameter for make (${CORES})
EOF
      ;;
   esac

   echo >&2

   exit 1
}


find_cmake()
{
   local name="$1"

   local toolname

   toolname=`read_build_setting "${name}" "cmake" "cmake"`
   verify_binary "${toolname}" "cmake" "cmake"
}


find_make()
{
   local name="$1"
   local defaultname="${2:-make}"

   local toolname
   local filename

   toolname="`read_build_setting "${name}" "make"`"
   if [ -z "${toolname}" -a "${OPTION_USE_CC_CXX}" = "YES" ]
   then
      filename="${srcdir}/.MAKE.${UNAME}"
      toolname="`cat "${filename}" 2>/dev/null`"

      if [ -z "${toolname}" ]
      then
         filename="${srcdir}/.MAKE"
         toolname="`cat "${filename}" 2>/dev/null`"

         if [ ! -z "${toolname}" ]
         then
            log_verbose "${C_RESET_BOLD}MAKE${C_VERBOSE} set to \
${C_MAGENTA}${C_BOLD}${toolname}${C_VERBOSE} found in \"${filename}\""
         fi
      fi
   fi

   if [ -z "${toolname}" ]
   then
      toolname="${defaultname}"
   fi

   verify_binary "${toolname}" "make" "${defaultname}"
}


find_xcodebuild()
{
   local name="$1"

   local toolname

   toolname=`read_build_setting "${name}" "xcodebuild" "xcodebuild"`
   verify_binary "${toolname}" "xcodebuild" "xcodebuild"
}


find_compiler()
{
   local name="$1"
   local srcdir="$2"
   local compiler_name="$3"

   local compiler
   local filename
   local path

   compiler="`read_build_setting "${name}" "${compiler_name}"`"
   if [ -z "${compiler}" -a "${OPTION_USE_CC_CXX}" = "YES" ]
   then
      filename="${srcdir}/.${compiler_name}.${UNAME}"
      compiler="`cat "${filename}" 2>/dev/null`"

      if [ -z "${compiler}" ]
      then
         filename="${srcdir}/.${compiler_name}"
         compiler="`cat "${filename}" 2>/dev/null`"

         if [ ! -z "${compiler}" ]
         then
            log_verbose "Compiler ${C_RESET_BOLD}${compiler_name}${C_VERBOSE} \
set to ${C_MAGENTA}${C_BOLD}${compiler}${C_VERBOSE} found in \"${filename}\""
         fi
      fi
   fi

   case "${UNAME}" in
      mingw)
         if [ "`read_config_setting "mangle_minwg_compiler" "YES"`" = "YES" ]
         then
            compiler="`mingw_mangle_compiler "${compiler}"`"
         fi
      ;;
   esac

   if [ ! -z "${compiler}" ]
   then
      path=`which_binary "${compiler}"`
      if [ -z "${path}" ]
      then
         fail "Compiler \"${compiler}\" not found.
Suggested fix:
   ${C_RESET}${C_BOLD}`suggest_binary_install "${compiler}"`"
      fi
      echo "${compiler}"
   fi
}


tools_environment_common()
{
   local name="$1"
   local srcdir="$2"

   # no problem if those are empty
   C_COMPILER="`find_compiler "${name}" "${srcdir}" CC`"
   CXX_COMPILER="`find_compiler "${name}" "${srcdir}" CXX`"
   TR="`verify_binary "tr" "tr" "tr"`"
   SED="`verify_binary "sed" "sed" "sed"`"
}


tools_environment_xcodebuild()
{
   local name="$1"
   local srcdir="$2"

   tools_environment_common "$@"

   XCODEBUILD="`find_xcodebuild "${name}"`"
}


tools_environment_make()
{
   local name="$1"
   local srcdir="$2"

   tools_environment_common "$@"

   local defaultmake

   defaultmake="`platform_make "${C_COMPILER}"`"

   case "${UNAME}" in
      mingw)
         MAKE="`find_make "${name}" "${defaultmake}"`"
      ;;

      darwin)
         MAKE="`find_make "${name}"`"
      ;;

      *)
         MAKE="`find_make "${name}"`"
      ;;
   esac
}


tools_environment_cmake()
{
   local name="$1"
   local srcdir="$2"

   tools_environment_make "$@"

   local defaultgenerator

   defaultgenerator="`platform_cmake_generator "${MAKE}"`"

   CMAKE="`find_cmake "${name}"`"
   CMAKE_GENERATOR="`read_build_setting "${name}" "cmake_generator" "${defaultgenerator}"`"

   [ -z "${CMAKE_GENERATOR}" ]  && internal_fail "CMAKE_GENERATOR must not be empty"
}


#
# move stuff produced my cmake and configure to places
# where we expect them. Expect  others to build to
# <prefix>/include  and <prefix>/lib or <prefix>/Frameworks
#
dispense_files()
{
   local src="$1"
   local name="$2"
   local ftype="$3"
   local depend_subdir="$4"
   local dirpath="$5"

   local dst

   log_fluff "Consider copying ${ftype} from \"${src}\""


   if [ -d "${src}" ]
   then
      if dir_has_files "${src}"
      then

         dst="`add_component "${REFERENCE_DEPENDENCIES_DIR}${depend_subdir}" "${dirpath}"`"
         mkdir_if_missing "${dst}"

         # this fails with more nested header set ups, need to fix!

         log_fluff "Copying ${ftype} from \"${src}\" to \"${dst}\""
         exekutor cp -Ra ${COPYMOVEFLAGS} "${src}"/* "${dst}" >&2 || exit 1

         rmdir_safer "${src}"
      else
         log_fluff "But there are none"
      fi
   else
      log_fluff "But it doesn't exist"
   fi
}


dispense_headers()
{
   local sources="$1"
   local name="$2"
   local depend_subdir="$3"

   local headerpath

   headerpath="`read_build_setting "${name}" "dispense_headers_path" "${HEADER_DIR_NAME}"`"

   local src
   IFS="
"
   for src in $sources
   do
      IFS="${DEFAULT_IFS}"

      dispense_files "${src}" "${name}" "headers" "${depend_subdir}" "${headerpath}"
   done
   IFS="${DEFAULT_IFS}"
}


dispense_resources()
{
   local sources="$1"
   local name="$2"
   local depend_subdir="$3"

   local resourcepath

   resourcepath="`read_build_setting "${name}" "dispense_resources_path" "${RESOURCE_DIR_NAME}"`"

   local src
   IFS="
"
   for src in $sources
   do
      IFS="${DEFAULT_IFS}"

      dispense_files "${src}" "${name}" "resources" "${depend_subdir}" "${resourcepath}"
   done
   IFS="${DEFAULT_IFS}"
}


dispense_libexec()
{
   local sources="$1"
   local name="$2"
   local depend_subdir="$3"

   local libexecpath

   libexecpath="`read_build_setting "${name}" "dispense_resources_path" "/${LIBEXEC_DIR_NAME}"`"

   local src
   IFS="
"
   for src in $sources
   do
      IFS="${DEFAULT_IFS}"

      dispense_files "${src}" "${name}" "libexec" "${depend_subdir}" "${libexecpath}"
   done
   IFS="${DEFAULT_IFS}"
}


_dispense_binaries()
{
   local src="$1"
   local name="$2"
   local findtype="$3"
   local depend_subdir="$4"
   local subpath="$5"

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

         log_fluff "Moving binaries from \"${src}\" to \"${dst}\""
         mkdir_if_missing "${dst}"
         exekutor find "${src}" -xdev -mindepth 1 -maxdepth 1 \( -type "${findtype}" -o -type "${findtype2}" \) -print0 | \
            exekutor xargs -0 -I % mulle-bootstrap-mv-force.sh ${COPYMOVEFLAGS} "${copyflag}" % "${dst}" >&2
         [ $? -eq 0 ]  || exit 1
      else
         log_fluff "But there are none"
      fi
      rmdir_safer "${src}"
   else
      log_fluff "But it doesn't exist"
   fi
}


dispense_binaries()
{
   local sources="$1" ; shift

   local src
   IFS="
"
   for src in $sources
   do
      IFS="${DEFAULT_IFS}"

      _dispense_binaries "${src}" "$@"
   done
   IFS="${DEFAULT_IFS}"
}


_collect_and_dispense_product()
{
   log_debug "_collect_and_dispense_product" "$@"

   local name="$1"
   local build_subdir="$2"
   local depend_subdir="$3"
   local wasxcode="$4"

   if read_yes_no_config_setting "skip_collect_and_dispense" "NO"
   then
      log_info "Skipped collection and dispensal on request"
      return 0
   fi

   log_verbose "Collecting and dispensing \"${name}\" products"

   if [ "${MULLE_FLAG_LOG_DEBUG}" = "YES"  ]
   then
      log_debug "Contents of BUILD_DEPENDENCIES_DIR:"

      ls -lRa ${BUILD_DEPENDENCIES_DIR} >&2
   fi

   [ -z "${LIBRARY_DIR_NAME}" ]     && internal_fail "LIBRARY_DIR_NAME undefined"
   [ -z "${LIBEXEC_DIR_NAME}" ]     && internal_fail "LIBEXEC_DIR_NAME undefined"
   [ -z "${BIN_DIR_NAME}" ]         && internal_fail "BIN_DIR_NAME undefined"
   [ -z "${FRAMEWORK_DIR_NAME}" ]   && internal_fail "FRAMEWORK_DIR_NAME undefined"
   [ -z "${RESOURCE_DIR_NAME}" ]    && internal_fail "LIBRARY_DIR_NAME undefined"
   [ -z "${HEADER_DIR_NAME}" ]      && internal_fail "LIBRARY_DIR_NAME undefined"

   #
   # ensure basic structure is there to squelch linker warnings
   #
   log_fluff "Create default lib/, include/, Frameworks/ in ${REFERENCE_DEPENDENCIES_DIR}${depend_subdir}"

   mkdir_if_missing "${REFERENCE_DEPENDENCIES_DIR}${depend_subdir}/${FRAMEWORK_DIR_NAME}"
   mkdir_if_missing "${REFERENCE_DEPENDENCIES_DIR}${depend_subdir}/${LIBRARY_DIR_NAME}"
   mkdir_if_missing "${REFERENCE_DEPENDENCIES_DIR}${depend_subdir}/${HEADER_DIR_NAME}"

   #
   # probably should use install_name_tool to hack all dylib paths that contain .ref
   # (will this work with signing stuff ?)
   #
   if true
   then
      local sources
      ##
      ## copy lib
      ## TODO: isn't cmake's output directory also platform specific ?
      ##
      sources="${BUILD_DEPENDENCIES_DIR}${build_subdir}/lib
${BUILD_DEPENDENCIES_DIR}/usr/local/lib
${BUILD_DEPENDENCIES_DIR}/usr/lib
${BUILD_DEPENDENCIES_DIR}/lib"

      dispense_binaries "${sources}" "${name}" "f" "${depend_subdir}" "/${LIBRARY_DIR_NAME}"

      ##
      ## copy libexec
      ##
      sources="${BUILD_DEPENDENCIES_DIR}${build_subdir}/libexec
${BUILD_DEPENDENCIES_DIR}/usr/local/libexec
${BUILD_DEPENDENCIES_DIR}/usr/libexec
${BUILD_DEPENDENCIES_DIR}/libexec"

      dispense_libexec "${sources}" "${name}" "${depend_subdir}"


      ##
      ## copy resources
      ##
      sources="${BUILD_DEPENDENCIES_DIR}${build_subdir}/share
${BUILD_DEPENDENCIES_DIR}/usr/local/share
${BUILD_DEPENDENCIES_DIR}/usr/share
${BUILD_DEPENDENCIES_DIR}/share"

      dispense_resources "${sources}" "${name}" "${depend_subdir}"

      ##
      ## copy headers
      ##
      sources="${BUILD_DEPENDENCIES_DIR}${build_subdir}/include
${BUILD_DEPENDENCIES_DIR}/usr/local/include
${BUILD_DEPENDENCIES_DIR}/usr/include
${BUILD_DEPENDENCIES_DIR}/include"

      dispense_headers  "${sources}" "${name}" "${depend_subdir}"


      ##
      ## copy bin and sbin
      ##
      sources="${BUILD_DEPENDENCIES_DIR}${build_subdir}/bin
${BUILD_DEPENDENCIES_DIR}/usr/local/bin
${BUILD_DEPENDENCIES_DIR}/usr/bin
${BUILD_DEPENDENCIES_DIR}/bin
${BUILD_DEPENDENCIES_DIR}${build_subdir}/sbin
${BUILD_DEPENDENCIES_DIR}/usr/local/sbin
${BUILD_DEPENDENCIES_DIR}/usr/sbin
${BUILD_DEPENDENCIES_DIR}/sbin"

      dispense_binaries "${sources}" "${name}" "f" "${depend_subdir}" "/${BIN_DIR_NAME}"

      ##
      ## copy frameworks
      ##
      sources="${BUILD_DEPENDENCIES_DIR}${build_subdir}/Library/Frameworks
${BUILD_DEPENDENCIES_DIR}${build_subdir}/Frameworks
${BUILD_DEPENDENCIES_DIR}/Library/Frameworks
${BUILD_DEPENDENCIES_DIR}/Frameworks"

      dispense_binaries "${sources}" "${name}" "d" "${depend_subdir}" "/${FRAMEWORK_DIR_NAME}"
   fi

   local dst
   local src

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
               exekutor xargs -0 -I % mv ${COPYMOVEFLAGS} -f % "${dst}" >&2
         [ $? -eq 0 ]  || fail "moving files from ${src} to ${dst} failed"
      fi

      if [ "$MULLE_FLAG_LOG_VERBOSE" = "YES"  ]
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

   # now make it appear
   mkdir_if_missing "${BUILD_DEPENDENCIES_DIR}"
}


#
# if only one configuration is chosen, make it the default
# if there are multiple configurations, make Release the default
# if Release is not in multiple configurations, then there is no default
#
determine_build_subdir()
{
   log_debug "determine_build_subdir" "$*"

   local configuration="$1"
   local sdk="$2"

   [ -z "$configuration" ] && internal_fail "configuration must not be empty"
   [ -z "$sdk" ]           && internal_fail "sdk must not be empty"

   sdk=`echo "${sdk}" | "${SED:-sed}" 's/^\([a-zA-Z]*\).*$/\1/g'`

   if [ "${sdk}" = "Default" ]
   then
      if [ "${configuration}" != "Release" ]
      then
         echo "/${configuration}"
      fi
   else
      echo "/${configuration}-${sdk}"
   fi
}


determine_dependencies_subdir()
{
   log_debug "determine_dependencies_subdir" "$*"

   local configuration="$1"
   local sdk="$2"
   local style="$3"

   [ -z "$configuration" ] && internal_fail "configuration must not be empty"
   [ -z "$sdk" ]           && internal_fail "sdk must not be empty"
   [ -z "$BUILD_SDKS" ]    && internal_fail "BUILD_SDKS must not be empty"

   sdk=`echo "${sdk}" | "${SED}" 's/^\([a-zA-Z]*\).*$/\1/g'`

   if [ "${style}" = "auto" ]
   then
      style="configuration"

      n_sdks="`echo "${BUILD_SDKS}" | wc -l | awk '{ print $1 }'`"
      if [ $n_sdks -gt 1 ]
      then
         style="configuration-sdk"
      fi
   fi

   case "${style}" in
      "none")
      ;;

      "configuration-strict")
         echo "/${configuration}"
      ;;

      "configuration-sdk-strict")
         echo "/${configuration}-${sdk}"
      ;;

      "configuration-sdk")
         if [ "${sdk}" = "Default" ]
         then
            if [ "${configuration}" != "Release" ]
            then
               echo "/${configuration}"
            fi
         else
            echo "/${configuration}-${sdk}"
         fi
      ;;

      "configuration")
         if [ "${configuration}" != "Release" ]
         then
            echo "/${configuration}"
         fi
      ;;

      *)
         fail "unknown value \"${BUILD_DISPENSE_STYLE}\" for dispense_style"
      ;;
   esac
}


cmake_sdk_parameter()
{
   local sdk="$1"

   local sdkpath

   sdkpath=`gcc_sdk_parameter "${sdk}"`
   if [ ! -z "${sdkpath}" ]
   then
      log_fluff "Set cmake -DCMAKE_OSX_SYSROOT to \"${sdkpath}\""
      echo "-DCMAKE_OSX_SYSROOT='${sdkpath}'"
   fi
}


build_fail()
{
   if [ -f "$1" ]
   then
      printf "${C_RED}"
      egrep -B1 -A5 -w "[Ee]rror" "$1" >&2
      printf "${C_RESET}"
   fi

   if [ "$MULLE_TRACE" != "1848" ]
   then
      log_info "Check the build log: ${C_RESET_BOLD}$1${C_INFO}"
   fi
   fail "$2 failed"
}


build_log_name()
{
   local tool="$1"; shift
   local name="$1"; shift

   [ -z "${tool}" ] && internal_fail "tool missing"
   [ -z "${name}" ] && internal_fail "name missing"

   local logfile

   logfile="${BUILDLOGS_DIR}/${name}"

   while [ $# -gt 0 ]
   do
      if [ ! -z "$1" ]
      then
         logfile="${logfile}-$1"
      fi
      [ $# -eq 0 ] || shift
   done

   absolutepath "${logfile}.${tool}.log"
}


_build_flags()
{
   local configuration="$1"
   local srcdir="$2"
   local builddir="$3"
   local name="$4"
   local sdk="$5"
   local mapped="$6"

   local fallback

   fallback="`echo "${OPTION_CONFIGURATIONS}" | tail -1`"
   fallback="`read_build_setting "${name}" "fallback-configuration" "${fallback}"`"

   local mappedsubdir
   local fallbacksubdir
   local suffixsubdir

   suffixsubdir="`determine_dependencies_subdir "${configuration}" "${sdk}" "${OPTION_DISPENSE_STYLE}"`" || exit 1
   mappedsubdir="`determine_dependencies_subdir "${mapped}" "${sdk}" "${OPTION_DISPENSE_STYLE}"`" || exit 1
   fallbacksubdir="`determine_dependencies_subdir "${fallback}" "${sdk}" "${OPTION_DISPENSE_STYLE}"`" || exit 1

   (
      local nativewd
      local owd

      owd="${PWD}"
      nativewd="`pwd ${BUILD_PWD_OPTIONS}`"

      cd "${builddir}"

      local frameworklines
      local librarylines
      local includelines

      frameworklines=
      librarylines=
      includelines=

      if [ ! -z "${suffixsubdir}" ]
      then
         frameworklines="`add_path_if_exists "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}/${FRAMEWORK_DIR_NAME}"`"
         librarylines="`add_path_if_exists "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}/${LIBRARY_DIR_NAME}"`"
      fi

      if [ ! -z "${mappedsubdir}" -a "${mappedsubdir}" != "${suffixsubdir}" ]
      then
         frameworklines="`add_path_if_exists "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${FRAMEWORK_DIR_NAME}"`"
         librarylines="`add_path_if_exists "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${mappedsubdir}/${LIBRARY_DIR_NAME}"`"
      fi

      if [ ! -z "${fallbacksubdir}" -a "${fallbacksubdir}" != "${suffixsubdir}" -a "${fallbacksubdir}" != "${mappedsubdir}" ]
      then
         frameworklines="`add_path_if_exists "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${fallbacksubdir}/${FRAMEWORK_DIR_NAME}"`"
         librarylines="`add_path_if_exists "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${fallbacksubdir}/${LIBRARY_DIR_NAME}"`"
      fi

      includelines="`add_path_if_exists "${includelines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}/${HEADER_DIR_NAME}"`"
      includelines="`add_path_if_exists "${includelines}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}/${HEADER_DIR_NAME}"`"

      librarylines="`add_path_if_exists "${librarylines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}/${LIBRARY_DIR_NAME}"`"
      librarylines="`add_path_if_exists "${librarylines}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}/${LIBRARY_DIR_NAME}"`"

      frameworklines="`add_path_if_exists "${frameworklines}" "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}/${FRAMEWORK_DIR_NAME}"`"
      frameworklines="`add_path_if_exists "${frameworklines}" "${nativewd}/${REFERENCE_ADDICTIONS_DIR}/${FRAMEWORK_DIR_NAME}"`"

      if [ "${OPTION_ADD_USR_LOCAL}" = "YES" ]
      then
         includelines="`add_path_if_exists "${includelines}" "${USR_LOCAL_INCLUDE}"`"
         librarylines="`add_path_if_exists "${librarylines}" "${USR_LOCAL_LIB}"`"
      fi


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
            native_includelines="`echo "${native_includelines}" | "${TR}" '/' '\\'  2> /dev/null`"
            native_librarylines="`echo "${native_librarylines}" | "${TR}" '/' '\\'  2> /dev/null`"
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

      local cppflags
      local ldflags
      local path

      # cmake separator
      [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"
      IFS="${PATH_SEPARATOR}"
      for path in ${native_includelines}
      do
         IFS="${DEFAULT_IFS}"
         path="$("${SED}" 's/ /\\ /g' <<< "${path}")"
         cppflags="`concat "${cppflags}" "${includeprefix}${path}"`"
      done

      IFS="${PATH_SEPARATOR}"
      for path in ${native_librarylines}
      do
         IFS="${DEFAULT_IFS}"
         path="$("${SED}" 's/ /\\ /g' <<< "${path}")"
         ldflags="`concat "${ldflags}" "${libraryprefix}${path}"`"
      done

      IFS="${PATH_SEPARATOR}"
      for path in ${native_frameworklines}
      do
         IFS="${DEFAULT_IFS}"
         path="$("${SED}" 's/ /\\ /g' <<< "${path}")"
         cppflags="`concat "${cppflags}" "${frameworkprefix}${path}"`"
         ldflags="`concat "${ldflags}" "${frameworkprefix}${path}"`"
      done
      IFS="${DEFAULT_IFS}"

      #
      # the output one line each
      #
      echo "${cppflags}"
      echo "${ldflags}"
      echo "${native_includelines}"
      echo "${native_librarylines}"
      echo "${native_frameworklines}"

      echo "${includelines}"
      echo "${librarylines}"
      echo "${frameworklines}"
      echo "${nativewd}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}"
   )
}


build_unix_flags()
{
   log_debug "build_unix_flags" "$*"

   _build_flags "$@"
}


build_cmake_flags()
{
   log_debug "build_cmake_flags" "$*"

   (
      PATH_SEPARATOR=";"
      _build_flags "$@"
   )
}

#
# remove old builddir, create a new one
# depending on configuration cmake with flags
# build stuff into dependencies
# TODO: cache commandline in a file $ and emit instead of rebuilding it every time
#
build_cmake()
{
   log_debug "build_cmake" "$*"

   local configuration="$1"
   local srcdir="$2"
   local builddir="$3"
   local name="$4"
   local sdk="$5"

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
   local local_cmake_flags
   local local_make_flags

   local_cmake_flags="`read_build_setting "${name}" "CMAKEFLAGS"`"
   sdkparameter="`cmake_sdk_parameter "${sdk}"`"

   if [ ! -z "${CORES}" ]
   then
      local_make_flags="-j ${CORES}"
   fi

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

   # need this now
   mkdir_if_missing "${builddir}"

   local other_cflags
   local other_cxxflags
   local other_cppflags
   local other_ldflags

   other_cflags="`gcc_cflags_value "${name}"`"
   other_cxxflags="`gcc_cxxflags_value "${name}"`"
   other_cppflags="`gcc_cppflags_value "${name}"`"
   other_ldflags="`gcc_ldflags_value "${name}"`"

   local flaglines
   local mapped

   mapped="`read_build_setting "${name}" "cmake-${configuration}.map" "${configuration}"`"
   flaglines="`build_cmake_flags "$@" "${mapped}"`"


   local cppflags
   local ldflags
   local includelines
   local librarylines
   local frameworklines
   local dependenciesdir

   cppflags="`echo "${flaglines}"        | "${SED}" -n '1p'`"
   ldflags="`echo "${flaglines}"         | "${SED}" -n '2p'`"
   includelines="`echo "${flaglines}"    | "${SED}" -n '6p'`"
   librarylines="`echo "${flaglines}"    | "${SED}" -n '7p'`"
   frameworklines="`echo "${flaglines}"  | "${SED}" -n '8p'`"
   dependenciesdir="`echo "${flaglines}" | "${SED}" -n '9p'`"

   local addictionsdir
   local binpath

   addictionsdir="${PWD}/${REFERENCE_ADDICTIONS_DIR}"
   binpath="${dependenciesdir}/bin"

   # CMAKE_CPP_FLAGS does not exist in cmake
   # so merge into CFLAGS and CXXFLAGS

   if [ -z "${cppflags}" ]
   then
      other_cppflags="`concat "${other_cppflags}" "${cppflags}"`"
   fi

   if [ -z "${other_cppflags}" ]
   then
      other_cflags="`concat "${other_cflags}" "${other_cppflags}"`"
      other_cxxflags="`concat "${other_cxxflags}" "${other_cppflags}"`"
   fi

   if [ -z "${ldflags}" ]
   then
      other_ldflags="`concat "${other_ldflags}" "${ldflags}"`"
   fi

   local cmake_flags

   if [ ! -z "${other_cflags}" ]
   then
      cmake_flags="`concat "${cmake_flags}" "-DCMAKE_C_FLAGS='${other_cflags}'"`"
   fi
   if [ ! -z "${other_cxxflags}" ]
   then
      cmake_flags="`concat "${cmake_flags}" "-DCMAKE_CXX_FLAGS='${other_cxxflags}'"`"
   fi
   if [ ! -z "${other_ldflags}" ]
   then
      cmake_flags="`concat "${cmake_flags}" "-DCMAKE_SHARED_LINKER_FLAGS='${other_ldflags}'"`"
      cmake_flags="`concat "${cmake_flags}" "-DCMAKE_EXE_LINKER_FLAGS='${other_ldflags}'"`"
   fi

   local logfile1
   local logfile2

   mkdir_if_missing "${BUILDLOGS_DIR}"

   logfile1="`build_log_name "cmake" "${name}" "${configuration}" "${sdk}"`"
   logfile2="`build_log_name "make" "${name}" "${configuration}" "${sdk}"`"

#   cmake_keep_builddir="`read_build_setting "${name}" "cmake_keep_builddir" "YES"`"
#   if [ "${cmake_keep_builddir}" != "YES" ]
#   then
#      rmdir_safer "${builddir}"
#   fi
   (
      local owd
      local nativewd

      owd="${PWD}"
      nativewd="`pwd ${BUILD_PWD_OPTIONS}`"

      exekutor cd "${builddir}" || fail "failed to enter ${builddir}"

      # DONT READ CONFIG SETTING IN THIS INDENT
      set -f

      if [ "$MULLE_FLAG_VERBOSE_BUILD" = "YES" ]
      then
         logfile1="`tty`"
         logfile2="$logfile1"
      fi
      if [ "$MULLE_FLAG_EXEKUTOR_DRY_RUN" = "YES" ]
      then
         logfile1="/dev/null"
         logfile2="/dev/null"
      fi

      log_verbose "Build logs will be in \"${logfile1}\" and \"${logfile2}\""

      if [ "${MULLE_FLAG_VERBOSE_BUILD}" = "YES" ]
      then
         local_make_flags="${local_make_flags} VERBOSE=1"
      fi

      local oldpath
      local rval

      [ -z "${BUILDPATH}" ] && internal_fail "BUILDPATH not set"

      oldpath="$PATH"
      PATH="${binpath}:${BUILDPATH}"

      log_fluff "PATH temporarily set to $PATH"

      local prefixbuild

      prefixbuild="`add_cmake_path "${prefixbuild}" "${nativewd}/${BUILD_DEPENDENCIES_DIR}"`"

      local cmake_dirs

      if [ ! -z "${dependenciesdir}" ]
      then
         cmake_dirs="-DDEPENDENCIES_DIR='${dependenciesdir}'"
      fi

      if [ ! -z "${addictionsdir}" ]
      then
         cmake_dirs="`concat "${cmake_dirs}" "-DADDICTIONS_DIR='${addictionsdir}'"`"
      fi

      #
      # CMAKE_INCLUDE_PATH doesn't really do what one expects it would
      # it's a settinh for the rarely used find_file
      #
      #if [ ! -z "${includelines}" ]
      #then
      #   cmake_dirs="`concat "${cmake_dirs}" "-DCMAKE_INCLUDE_PATH='${includelines}'"`"
      #fi

      if [ ! -z "${librarylines}" ]
      then
         cmake_dirs="`concat "${cmake_dirs}" "-DCMAKE_LIBRARY_PATH='${librarylines}'"`"
      fi

      if [ ! -z "${frameworklines}" ]
      then
         cmake_dirs="`concat "${cmake_dirs}" "-DCMAKE_FRAMEWORK_PATH='${frameworklines}'"`"
      fi

      local relative_srcdir

      relative_srcdir="`relative_path_between "${owd}/${srcdir}" "${PWD}"`"
      case "${UNAME}" in
         mingw)
            relative_srcdir="`echo "${relative_srcdir}" | "${TR}" '/' '\\'  2> /dev/null`"
      esac

      logging_redirect_eval_exekutor "${logfile1}" "'${CMAKE}'" \
-G "'${CMAKE_GENERATOR}'" \
"-DMULLE_BOOTSTRAP_VERSION=${MULLE_EXECUTABLE_VERSION}" \
"-DCMAKE_BUILD_TYPE='${mapped}'" \
"-DCMAKE_INSTALL_PREFIX:PATH='${prefixbuild}'"  \
"${sdkparameter}" \
"${cmake_dirs}" \
"${cmake_flags}" \
"${c_compiler_line}" \
"${cxx_compiler_line}" \
"${local_cmake_flags}" \
"${CMAKEFLAGS}" \
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

   ) || exit 1
}


#
# remove old builddir, create a new one
# depending on configuration cmake with flags
# build stuff into dependencies
#
#
build_configure()
{
   log_debug "build_configure" "$*"

   local configuration="$1"
   local srcdir="$2"
   local builddir="$3"
   local name="$4"
   local sdk="$5"

   if [ -z "${MAKE}" ]
   then
      fail "No make available"
   fi

   enforce_build_sanity "${builddir}"

   log_info "Let ${C_RESET_BOLD}configure${C_INFO} do a \
${C_MAGENTA}${C_BOLD}${configuration}${C_INFO} build of \
${C_MAGENTA}${C_BOLD}${name}${C_INFO} for SDK \
${C_MAGENTA}${C_BOLD}${sdk}${C_INFO} in \"${builddir}\" ..."

   local configure_flags

   configure_flags="`read_build_setting "${name}" "configure_flags"`"

#   create_dummy_dirs_against_warnings "${mapped}" "${suffix}"

   local c_compiler_line
   local cxx_compiler_line

   if [ ! -z "${C_COMPILER}" ]
   then
      c_compiler_line="CC='${C_COMPILER}'"
   fi
   if [ ! -z "${CXX_COMPILER}" ]
   then
      cxx_compiler_line="CXX='${CXX_COMPILER}'"
   fi

   mkdir_if_missing "${builddir}"

   local other_cflags
   local other_cxxflags
   local other_cppflags
   local other_ldflags

   other_cflags="`gcc_cflags_value "${name}"`"
   other_cxxflags="`gcc_cxxflags_value "${name}"`"
   other_cppflags="`gcc_cppflags_value "${name}"`"
   other_ldflags="`gcc_ldflags_value "${name}"`"

   local flaglines
   local mapped

   mapped="`read_build_setting "${name}" "cmake-${configuration}.map" "${configuration}"`"
   flaglines="`build_unix_flags "$@" "${mapped}"`"

   local cppflags
   local ldflags
   local dependenciesdir

   cppflags="`echo "${flaglines}"        | "${SED}" -n '1p'`"
   ldflags="`echo "${flaglines}"         | "${SED}" -n '2p'`"
   dependenciesdir="`echo "${flaglines}" | "${SED}" -n '9p'`"

   local addictionsdir
   local binpath

   addictionsdir="${nativewd}/${REFERENCE_ADDICTIONS_DIR}"
   binpath="${dependenciesdir}/bin"

   # CMAKE_CPP_FLAGS does not exist in cmake
   # so merge into CFLAGS and CXXFLAGS

   if [ -z "${cppflags}" ]
   then
      other_cppflags="`concat "${other_cppflags}" "${cppflags}"`"
   fi

   if [ -z "${ldflags}" ]
   then
      other_ldflags="`concat "${other_ldflags}" "${ldflags}"`"
   fi

   local sdkpath

   sdkpath="`gcc_sdk_parameter "${sdk}"`"
   sdkpath="`echo "${sdkpath}" | "${SED}" -e 's/ /\\ /g'`"

   if [ ! -z "${sdkpath}" ]
   then
      other_cppflags="`concat "-isysroot ${sdkpath}" "${other_cppflags}"`"
      other_ldflags="`concat "-isysroot ${sdkpath}" "${other_ldflags}"`"
   fi

   local env_flags

   if [ ! -z "${other_cppflags}" ]
   then
      env_flags="`concat "${cmake_flags}" "CPPFLAGS='${other_cppflags}'"`"
   fi
   if [ ! -z "${other_cflags}" ]
   then
      env_flags="`concat "${cmake_flags}" "CFLAGS='${other_cflags}'"`"
   fi
   if [ ! -z "${other_cxxflags}" ]
   then
      env_flags="`concat "${cmake_flags}" "CXXFLAGS='${other_cxxflags}'"`"
   fi
   if [ ! -z "${other_ldflags}" ]
   then
      env_flags="`concat "${cmake_flags}" "LDFLAGS='${other_ldflags}'"`"
   fi

   local logfile1
   local logfile2

   mkdir_if_missing "${BUILDLOGS_DIR}"

   logfile1="`build_log_name "configure" "${name}" "${configuration}" "${sdk}"`"
   logfile2="`build_log_name "make" "${name}" "${configuration}" "${sdk}"`"

   (
      local owd
      local nativewd

      owd="${PWD}"
      nativewd="`pwd ${BUILD_PWD_OPTIONS}`"

      exekutor cd "${builddir}" || fail "failed to enter ${builddir}"

      # DONT READ CONFIG SETTING IN THIS INDENT
      set -f

      if [ "$MULLE_FLAG_VERBOSE_BUILD" = "YES" ]
      then
         logfile1="`tty`"
         logfile2="$logfile1"
      fi
      if [ "$MULLE_FLAG_EXEKUTOR_DRY_RUN" = "YES" ]
      then
         logfile1="/dev/null"
         logfile2="/dev/null"
      fi

      log_verbose "Build logs will be in \"${logfile1}\" and \"${logfile2}\""

      local prefixbuild

      prefixbuild="`add_component "${prefixbuild}" "${nativewd}/${BUILD_DEPENDENCIES_DIR}"`"

      local oldpath
      local rval

      oldpath="$PATH"
      PATH="${binpath}:${BUILDPATH}"

      log_fluff "PATH temporarily set to $PATH"

       # use absolute paths for configure, safer (and easier to read IMO)
      logging_redirect_eval_exekutor "${logfile1}" \
         DEPENDENCIES_DIR="'${dependenciesdir}'" \
         ADDICTIONS_DIR="'${addictionsdir}'" \
         "${c_compiler_line}" \
         "${cxx_compiler_line}" \
         "${env_flags}" \
         "'${owd}/${srcdir}/configure'" \
         "${configure_flags}" \
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

      set +f

   ) || exit 1
}



_xcode_get_setting()
{
   eval_exekutor "xcodebuild -showBuildSettings $*" || fail "failed to read xcode settings"
}


xcode_get_setting()
{
   local key=$1; shift

   _xcode_get_setting "$@" | egrep "^[ ]*${key}" | sed 's/^[^=]*=[ ]*\(.*\)/\1/'

   return 0
}


#
# Code I didn't want to throw away really
# In general just use "public_headers" or
# "private_headers" and set them to a /usr/local/include/whatever
#
create_mangled_header_path()
{
   local key="$1"
   local name="$2"
   local default="$3"

   local headers
#   local prefix

   headers="`xcode_get_setting "${key}" $*`"
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

   # prefix=""
   read_yes_no_build_setting "${name}" "xcode_mangle_include_prefix"
   if [ $? -ne 0 ]
   then
      headers="`remove_absolute_path_prefix_up_to "${headers}" "include"`"
      # prefix="${HEADER_DIR_NAME}"
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

   headers="`read_build_setting "${name}" "${setting_key}"`"
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
   log_debug "build_xcodebuild" "$*"

   local configuration="$1"
   local srcdir="$2"
   local builddir="$3"
   local name="$4"
   local sdk="$5"
   local project="$6"
   local schemename="$7"
   local targetname="$8"

   [ ! -z "${configuration}" ] || internal_fail "configuration is empty"
   [ ! -z "${srcdir}" ]        || internal_fail "srcdir is empty"
   [ ! -z "${builddir}" ]      || internal_fail "builddir is empty"
   [ ! -z "${name}" ]          || internal_fail "name is empty"
   [ ! -z "${sdk}" ]           || internal_fail "sdk is empty"
   [ ! -z "${project}" ]       || internal_fail "project is empty"

   enforce_build_sanity "${builddir}"

   local toolname

   toolname="`read_config_setting "xcodebuild" "xcodebuild"`"

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
   projectname=`read_build_setting "${name}" "xcode_project" "${project}"`

   local mapped
   local fallback

   fallback="`echo "${OPTION_CONFIGURATIONS}" | tail -1`"
   fallback="`read_build_setting "${name}" "fallback-configuration" "${fallback}"`"

   mapped=`read_build_setting "${name}" "${configuration}.map" "${configuration}"`
   [ -z "${mapped}" ] && internal_fail "mapped configuration is empty"

   local hackish
   local targetname
   local suffix

   suffix="${mapped}"
   if [ "${sdk}" != "Default" ]
   then
      hackish="`echo "${sdk}" | sed 's/^\([a-zA-Z]*\).*$/\1/g'`"
      suffix="${suffix}-${hackish}"
   else
      sdk=
   fi

#   create_dummy_dirs_against_warnings "${mapped}" "${suffix}"

   local mappedsubdir
   local fallbacksubdir
   local suffixsubdir
   local binpath

   suffixsubdir="`determine_dependencies_subdir "${configuration}" "${sdk}" "${OPTION_DISPENSE_STYLE}"`" || exit 1
   mappedsubdir="`determine_dependencies_subdir "${mapped}" "${sdk}" "${OPTION_DISPENSE_STYLE}"`" || exit 1
   fallbacksubdir="`determine_dependencies_subdir "${fallback}" "${sdk}" "${OPTION_DISPENSE_STYLE}"`" || exit 1
   binpath="${PWD}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}/bin"

   local xcode_proper_skip_install
   local skip_install

   skip_install=
   xcode_proper_skip_install=`read_build_setting "${name}" "xcode_proper_skip_install" "NO"`
   if [ "$xcode_proper_skip_install" != "YES" ]
   then
      skip_install="SKIP_INSTALL=NO"
   fi

   #
   # xctool needs schemes, these are often autocreated, which xctool cant do
   # xcodebuild can just use a target
   # xctool is by and large useless fluff IMO
   #
   if [ "${toolname}" = "xctool"  -a "${schemename}" = ""  ]
   then
      if [ ! -z "$targetname" ]
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

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" ]
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

   mkdir_if_missing "${BUILDLOGS_DIR}"

   logfile="`build_log_name "${toolname}" "${name}" "${configuration}" "${targetname}" "${schemename}" "${sdk}"`"

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

   xcconfig=`read_build_setting "${name}" "xcconfig"`
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
      if [ "${MULLE_FLAG_VERBOSE_BUILD}" = "YES" ]
      then
         logfile="`tty`"
      fi
      if [ "$MULLE_FLAG_EXEKUTOR_DRY_RUN" = "YES" ]
      then
         logfile="/dev/null"
      fi

      log_verbose "Build log will be in: ${C_RESET_BOLD}${logfile}${C_VERBOSE}"

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
"${owd}/${REFERENCE_DEPENDENCIES_DIR}/${HEADER_DIR_NAME}" \
"${owd}/${REFERENCE_ADDICTIONS_DIR}/${HEADER_DIR_NAME}"`
      if [ -z "${inherited}" ]
      then
         dependencies_header_search_path="${path}"
      else
         dependencies_header_search_path="${path} ${inherited}"
      fi

      inherited="`xcode_get_setting LIBRARY_SEARCH_PATHS ${arguments}`"
      path=`combined_escaped_search_path_if_exists \
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

      if [ "${OPTION_ADD_USR_LOCAL}" = "YES" ]
      then
         dependencies_header_search_path="${path} ${USR_LOCAL_INCLUDE}"
         dependencies_lib_search_path="${path} ${USR_LOCAL_LIB}"
      fi

      inherited="`xcode_get_setting FRAMEWORK_SEARCH_PATHS ${arguments}`"
      path=`combined_escaped_search_path_if_exists \
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
      PATH="${binpath}:${BUILDPATH}"

      log_fluff "PATH temporarily set to $PATH"

      # if it doesn't install, probably SKIP_INSTALL is set
      cmdline="\"${XCODEBUILD}\" \"${command}\" ${arguments} \
ARCHS='${ARCHS:-\${ARCHS_STANDARD_32_64_BIT}}' \
DSTROOT='${owd}/${BUILD_DEPENDENCIES_DIR}' \
SYMROOT='${owd}/${builddir}/' \
OBJROOT='${owd}/${builddir}/obj' \
DEPENDENCIES_DIR='${owd}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}' \
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
}


build_xcodebuild_schemes_or_target()
{
   log_debug "build_xcodebuild_schemes_or_target" "$*"

   local builddir="$3"
   local name="$4"
   local project="$6"

   local scheme
   local schemes

   schemes=`read_build_setting "${name}" "xcode_schemes"`

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

   targets=`read_build_setting "${name}" "xcode_targets"`

   IFS="
"
   for target in $targets
   do
      IFS="${DEFAULT_IFS}"
      log_fluff "Building target \"${target}\" of \"${project}\" ..."
      build_xcodebuild "$@" "" "${target}"
   done
   IFS="${DEFAULT_IFS}"

   if [ -z "${targets}" -a -z "${schemes}" ]
   then
      log_fluff "Building project \"${project}\" ..."
      build_xcodebuild "$@"
   fi
}



run_log_build_script()
{
   echo "$@"
   run_script "$@"
}


build_script()
{
   log_debug "build_script" "$*"

   local script

   script="$1"
   shift

   local configuration="$1"
   local srcdir="$2"
   local builddir="$3"
   local name="$4"
   local sdk="$5"

   enforce_build_sanity "${builddir}"

   local project
   local schemename
   local targetname
   local logfile

   mkdir_if_missing "${BUILDLOGS_DIR}"

   logfile="${BUILDLOGS_DIR}/${name}-${configuration}-${sdk}.script.log"
   logfile="`absolutepath "${logfile}"`"

   local suffixsubdir
   local binpath

   suffixsubdir="`determine_dependencies_subdir "${configuration}" "${sdk}" "${OPTION_DISPENSE_STYLE}"`" || exit 1
   binpath="${PWD}/${REFERENCE_DEPENDENCIES_DIR}${suffixsubdir}/bin"

   log_fluff "Build log will be in: ${C_RESET_BOLD}${logfile}${C_INFO}"

   mkdir_if_missing "${builddir}"

   local owd

   owd=`pwd`
   exekutor cd "${srcdir}" || exit 1

      if [ "$MULLE_FLAG_VERBOSE_BUILD" = "YES" ]
      then
         logfile="`tty`"
      fi
      if [ "$MULLE_FLAG_EXEKUTOR_DRY_RUN" = "YES" ]
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
      PATH="${binpath}:${BUILDPATH}"

      log_fluff "PATH temporarily set to $PATH"

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
}


collect_and_dispense_product()
{
   local name="$1"
   local configuration="$2"
   local sdk="$3"
   local wasxcode="$4"

   local depend_subdir

   depend_subdir="`determine_dependencies_subdir "${configuration}" "${sdk}" "${OPTION_DISPENSE_STYLE}"`" || exit 1
   _collect_and_dispense_product "${name}" "${build_subdir}" "${depend_subdir}" "${wasxcode}"
}


build_with_configuration_sdk_preferences()
{
   log_debug "build_with_configuration_sdk_preferences" "$*"

   local name="$1"; shift
   local configuration="$1"; shift
   local sdk="$1" ; shift
   local preferences="$1" ; shift

   if [ "/${configuration}" = "/${LIBRARY_DIR_NAME}" -o "/${configuration}" = "${HEADER_DIR_NAME}" -o "/${configuration}" = "${FRAMEWORK_DIR_NAME}" ]
   then
      fail "You are just asking for trouble naming your configuration \"${configuration}\"."
   fi

   if [ "${configuration}" = "lib" -o "${configuration}" = "include" -o "${configuration}" = "Frameworks" ]
   then
      fail "You are just asking for major trouble naming your configuration \"${configuration}\"."
   fi

   # always build into fully qualified
   local build_subdir
   local builddir

   build_subdir="`determine_build_subdir "${configuration}" "${sdk}"`" || exit 1
   builddir="${CLONESBUILD_DIR}${build_subdir}/${name}"

   if [ -d "${builddir}" -a "${OPTION_CLEAN_BEFORE_BUILD}" = "YES" ]
   then
      log_fluff "Cleaning build directory \"${builddir}\""
      rmdir_safer "${builddir}"
   fi

   local project
   local rval
   local wasxcode

   rval=1
   for preference in ${preferences}
   do
      wasxcode="NO"
      case "${preference}" in
         script)
            script="`find_build_setting_file "${name}" "bin/build.sh"`"
            if [ -x "${script}" ]
            then
               build_script "${script}" "${configuration}" "${srcdir}" "${builddir}" "${name}" "${sdk}" || exit 1
               rval=$?
               break
            else
               [ ! -e "${script}" ] || fail "script ${script} is not executable"
               log_fluff "There is no build script in \"`build_setting_path "${name}" "bin/build.sh"`\""
            fi
         ;;

         xcodebuild)
            tools_environment_xcodebuild "${name}" "${srcdir}"

            if [ ! -z "${XCODEBUILD}" ]
            then
               project="`(cd "${srcdir}" ; find_xcodeproj "${name}")`"

               if [ -z "${project}" ]
               then
                  log_fluff "There is no Xcode project in \"${srcdir}\""
               else
                  if [ -z "${XCODEBUILD}" ]
                  then
                     log_warning "Found a Xcode project, but ${C_RESET}${C_BOLD}xcodebuild${C_WARNING} is not installed"
                  else
                     build_xcodebuild_schemes_or_target "${configuration}" "${srcdir}" "${builddir}" "${name}" "${sdk}" "${project}"  || exit 1
                     rval=$?
                     wasxcode="YES"
                     break
                  fi
               fi
            else
               log_fluff "No xcodebuild found, that's unusual"
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
               tools_environment_make "${name}" "${srcdir}"

               if [ -z "${MAKE}" ]
               then
                  log_warning "Found a ./configure, but ${C_RESET}${C_BOLD}make${C_WARNING} is not installed"
               else
                  build_configure "${configuration}" "${srcdir}" "${builddir}" "${name}" "${sdk}"  || exit 1
                  rval=$?
                  break
               fi
            else
               log_fluff "There is no configure script in \"${srcdir}\""
            fi
         ;;

         cmake)
            if [ -f "${srcdir}/CMakeLists.txt" ]
            then
               tools_environment_cmake "${name}" "${srcdir}"

               if [ -z "${CMAKE}" ]
               then
                  log_warning "Found a CMakeLists.txt, but ${C_RESET}${C_BOLD}cmake${C_WARNING} is not installed"
               else
                  build_cmake "${configuration}" "${srcdir}" "${builddir}" "${name}" "${sdk}"  || exit 1
                  rval=$?
                  break
               fi
            else
               log_fluff "There is no CMakeLists.txt file in \"${srcdir}\""
            fi
         ;;

         "")
            # ignore empty
         ;;

         *)
            fail "Unknown build preference \"${preference}\""
         ;;
      esac
   done

   if [ $rval -eq 0 ]
   then
      collect_and_dispense_product "${name}" "${configuration}" "${sdk}" "${wasxcode}" || \
         internal_fail "collect failed silently"
   fi

   return $rval
}


build()
{
   log_debug "build" "$*"

   local name
   local srcdir

   name="$1"
   srcdir="$2"

   [ "${name}" != "${REPOS_DIR}" ] || internal_fail "missing repo argument (${srcdir})"

   log_verbose "Building ${name} ..."

   local preferences
   local directory

   #
   # repo may override how it wants to be build
   #
   preferences="`read_build_setting "${name}" "build_preferences"`"
   directory="`read_build_setting "${name}" "srcdir"`"
   srcdir="`add_component "${srcdir}" "${directory}"`"

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

   log_fluff "Build preferences for ${UNAME} are: `echo ${preferences}`"

   local configurations
   local configuration
   local sdks
   local sdk

   # need uniform SDK for our builds
   sdks=`read_build_setting "${name}" "sdks" "${OPTION_SDKS}"`

   [ ! -z "${sdks}" ] || fail "setting \"sdks\" must at least contain \"Default\" to build anything"

   # settings can override the commandline default
   configurations="`read_build_setting "${name}" "configurations" "${OPTION_CONFIGURATIONS}"`"

   # "export" some globals
   local BUILD_CONFIGURATIONS
   local BUILD_SDKS

   BUILD_CONFIGURATIONS="${configurations}"
   BUILD_SDKS="${sdks}"

   for sdk in ${sdks}
   do
      # remap macosx to Default, as EFFECTIVE_PLATFORM_NAME will not be appended by Xcode
      case "${UNAME}" in
         darwin)
            if [ "$sdk" = "macosx" ]
            then
               sdk="Default"
            fi
         ;;
      esac

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
   log_debug "build_wrapper" "$*"

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

   run_build_settings_script "pre-build" \
                             "${name}" \
                             "${srcdir}"

   build "${name}" "${srcdir}"

   run_build_settings_script "post-build" \
                             "${name}" \
                             "${srcdir}"

   if [ "${COMMAND}" != "ibuild"  ]
   then
      log_fluff "Remove \"${BUILD_DEPENDENCIES_DIR}\""
      rmdir_safer "${BUILD_DEPENDENCIES_DIR}"
   else
      log_fluff "Not removing \"${BUILD_DEPENDENCIES_DIR}\" because of \"${COMMAND}\""
   fi

   DEPENDENCIES_DIR="${REFERENCE_DEPENDENCIES_DIR}"
   ADDICTIONS_DIR="${REFERENCE_ADDICTIONS_DIR}"

   # for mulle-bootstrap developers
   REFERENCE_DEPENDENCIES_DIR="WRONG_DONT_USE_REFERENCE_DEPENDENCIES_DIR_AFTER_BUILD"
   BUILD_DEPENDENCIES_DIR="WRONG_DONT_USE_BUILD_DEPENDENCIES_DIR_AFTER_BUILD"
}


# keep until "to" but excluding it
# cut stuff until "to"
# keep "to" and keep rest

force_rebuild()
{
   log_debug "force_rebuild" "$*"

   local from="$1"
   local to="$2"

   remove_file_if_present "${REPOS_DIR}/.build_started"

   # if nothing's build yet, fine with us
   if [ ! -f "${REPOS_DIR}/.build_done" ]
   then
      log_fluff "Nothing has been built yet"
      return
   fi

   if [ -z "${from}" -a -z "${to}" ]
   then
      remove_file_if_present "${REPOS_DIR}/.build_done"
      return
   fi

   #
   # keep entries above parameter
   # os x doesn't have 'Q'
   # also q and i doesn't work on OS X <sigh>
   #
   local tmpfile

   [ -z "${MULLE_BOOTSTRAP_SNIP_SH}" ] && . mulle-bootstrap-snip.sh

   tmpfile="`exekutor mktemp "mulle-bootstrap.XXXXXXXX"`" || exit 1

   redirect_exekutor "${tmpfile}" snip_from_to_file "${from}" "${to}" "${REPOS_DIR}/.build_done"
   exekutor mv "${tmpfile}" "${REPOS_DIR}/.build_done"

   log_debug ".build_done=`cat "${REPOS_DIR}/.build_done"`"
}


build_if_alive()
{
   log_debug "build_if_alive" "$*"

   local name
   local stashdir

   name="$1"
   stashdir="$2"

   local xdone
   local zombie

   zombie="`dirname -- "${stashdir}"`/.zombies/${name}"
   if [ -e "${zombie}" ]
   then
      log_warning "Ignoring zombie repo ${name} as \"${zombie}${C_WARNING} exists"
   else
      xdone="`/bin/echo "${BUILT}" | grep -x "${name}"`"
      if [ "$xdone" = "" ]
      then
         build_wrapper "${name}" "${stashdir}"

         # memorize what we build
         merge_line_into_file "${REPOS_DIR}/.build_done" "${name}"

         BUILT="${name}
${BUILT}"
      else
         log_fluff "Ignoring \"${name}\" as already built."
      fi
   fi
}


build_stashes()
{
   log_debug "build_stashes" "$*"

   local name

   IFS="
"
   for name in `ls -1d "${STASHES_DEFAULT_DIR}"/*.failed 2> /dev/null`
   do
      IFS="${DEFAULT_IFS}"
      if [ -d "${name}" ]
      then
         fail "failed checkout \"${name}\" detected, can't continue"
      fi
   done
   IFS="${DEFAULT_IFS}"

   run_root_settings_script "pre-build"

   #
   # build_order is created by refresh
   #
   local stashdir
   local stashnames

   BUILT=""

   if [ "$#" -eq 0 ]
   then
      #
      # don't redo builds (if no names are specified)
      #

      BUILT="`read_setting "${REPOS_DIR}/.build_done"`"
      stashnames="`read_root_setting "build_order"`"
      if [ ! -z "${stashnames}" ]
      then
         IFS="
"
         for name in ${stashnames}
         do
            IFS="${DEFAULT_IFS}"

            stashdir="`stash_of_repository "${REPOS_DIR}" "${name}"`"
            if [ -z "${stashdir}" ]
            then
               fail "${REPOS_DIR}/${name} is missing, that shouldn't have happened. Maybe it's time to dist clean"
            fi

            if [ -d "${stashdir}" ]
            then
               build_if_alive "${name}" "${stashdir}" || exit  1
            else
               if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = "YES" ] && has_usr_local_include "${name}"
               then
                  log_info "${C_MAGENTA}${C_BOLD}${name}${C_INFO} is a system library, so not building it"
                  :
               else
                  if [ ! -z "${stashdir}" ]
                  then
                     fail "Build failed for repository \"${name}\": not found in (\"${stashdir}\") ($PWD)"
                  else
                     log_fluff "Ignoring \"${name}\" as \"${stashdir}\" is missing, but it is not required"
                  fi
               fi
            fi
         done
      fi
   else
      for name in "$@"
      do
         stashdir="`stash_of_repository "${REPOS_DIR}" "${name}"`"

         if [ -d "${stashdir}" ]
         then
            build_if_alive "${name}" "${stashdir}"|| exit 1
         else
            if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = "YES" ] && has_usr_local_include "${name}"
            then
               log_info "${C_MAGENTA}${C_BOLD}${name}${C_INFO} is a system library, so not building it"
               :
            else
               if [ ! -z "${stashdir}" ]
               then
                  fail "Build failed for repository \"${name}\": not found in (\"${stashdir}\") ($PWD)"
               else
                  fail "Unknown repo \"${name}\", possibly not a required one."
               fi
            fi
         fi
      done
   fi

   IFS="${DEFAULT_IFS}"

   run_root_settings_script "post-build"
}


have_tars()
{
   tarballs=`read_root_setting "tarballs"`
   [ ! -z "${tarballs}" ]
}


install_tars()
{
   log_debug "install_tars" "$*"

   local tarballs
   local tar

   tarballs=`read_root_setting "tarballs" | sort | sort -u`
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
         exekutor tar -xz ${TARFLAGS} -C "${DEPENDENCIES_DIR}" -f "${tar}" || fail "failed to extract ${tar}"
      fi
   done
   IFS="${DEFAULT_IFS}"
}


build_main()
{
   local  clean

   log_debug "::: build begin :::"

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]        && . mulle-bootstrap-settings.sh
   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh
   [ -z "${MULLE_BOOTSTRAP_REPOSITORIES_SH}" ]    && . mulle-bootstrap-repositories.sh

   local OPTION_CLEAN_BEFORE_BUILD
   local OPTION_CHECK_USR_LOCAL_INCLUDE
   local OPTION_CONFIGURATIONS
   local OPTION_SDKS
   local OPTION_ADD_USR_LOCAL
   local OPTION_USE_CC_CXX
   local OPTION_FROM
   local OPTION_TO
   local OPTION_DISPENSE_STYLE  # keep empty

   OPTION_CHECK_USR_LOCAL_INCLUDE="`read_config_setting "check_usr_local_include" "NO"`"
   OPTION_USE_CC_CXX="`read_config_setting "use_cc_cxx" "YES"`"
   OPTION_CLEAN_BEFORE_BUILD=`read_config_setting "clean_before_build" "NO"`

   #
   # it is useful, that fetch understands build options and
   # ignores them
   #
   while [ $# -ne 0 ]
   do
      case "$1" in
         -c|--configuration|--configurations)
            [ $# -eq 1 ] && fail "argument for $1 is missing"
            shift

            OPTION_CONFIGURATIONS="`printf "%s" "$1" | tr ',' '\012'`"
            ;;

         -cs|--check-usr-local-include)
            # set environment to be picked up by config
            OPTION_CHECK_USR_LOCAL_INCLUDE="YES"
         ;;

         --debug)
            OPTION_CONFIGURATIONS="Debug"
            OPTION_DISPENSE_STYLE="none"
         ;;

         --from)
            [ $# -eq 1 ] && fail "argument for $1 is missing"
            shift

            OPTION_FROM="$1"
         ;;

         -j|--cores)
            [ $# -eq 1 ] && fail "argument for $1 is missing"
            shift

            case "${UNAME}" in
               mingw)
                  build_usage
               ;;
            esac

            CORES="$1"
         ;;

         -k|--no-clean)
            OPTION_CLEAN_BEFORE_BUILD="NO"
         ;;

         -K|--clean)
            OPTION_CLEAN_BEFORE_BUILD="YES"
         ;;

         --prefix)
            [ $# -eq 1 ] && fail "argument for $1 is missing"
            shift

            USR_LOCAL_INCLUDE="$1/include"
            USR_LOCAL_LIB="$1/lib"
         ;;

         --release)
            OPTION_CONFIGURATIONS="Release"
            OPTION_DISPENSE_STYLE="none"
         ;;

         -sdk|--sdks)
            [ $# -eq 1 ] && fail "argument for $1 is missing"
            shift

            OPTION_SDKS="`printf "%s" "$1" | tr ',' '\012'`"
         ;;


         --to)
            [ $# -eq 1 ] && fail "argument for $1 is missing"
            shift
            OPTION_TO="$1"
         ;;

         --use-prefix-libraries)
            OPTION_ADD_USR_LOCAL=YES
         ;;

         # TODO: outdated!
         # fetch options, are just ignored (need to update this!)
         -e|--embedded-only|-es|--embedded-symlinks|-l|--symlinks)
            :
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown build option $1"
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
   if [ ! -f "${BOOTSTRAP_DIR}.auto/build_order" ]
   then
      log_info "No repositories fetched, so nothing to build."
      return 0  # not an error really, maybe only embedded stuff here
   fi

   build_complete_environment

   [ -z "${MULLE_BOOTSTRAP_COMMAND_SH}" ] && . mulle-bootstrap-command.sh
   [ -z "${MULLE_BOOTSTRAP_GCC_SH}" ]     && . mulle-bootstrap-gcc.sh
   [ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ] && . mulle-bootstrap-scripts.sh

   case "${ADDICTIONS_DIR}" in
      /*|~*)
         internal_fail "ADDICTIONS_DIR must not be an absolute path"
      ;;
   esac
   case "${DEPENDENCIES_DIR}" in
      /*|~*)
         internal_fail "DEPENDENCIES_DIR must not be an absolute path"
      ;;
   esac


   #
   #
   #
   if [ ! -f "${REPOS_DIR}/.build_done" ]
   then
      _create_file_if_missing "${REPOS_DIR}/.build_done"

      log_fluff "Cleaning dependencies directory as \"${DEPENDENCIES_DIR}\""
      rmdir_safer "${DEPENDENCIES_DIR}"
   else
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" != "NONE" ] || \
         [ ! -z "${OPTION_FROM}" -o ! -z "${OPTION_TO}" ]
      then
         force_rebuild "${OPTION_FROM}" "${OPTION_TO}"
      fi
   fi

   # parameter ? partial build!

   if [ -d "${DEPENDENCIES_DIR}" ]
   then
      log_fluff "Unprotecting \"${DEPENDENCIES_DIR}\" (as this is a partial build)."
      exekutor chmod -R u+w "${DEPENDENCIES_DIR}"
      if have_tars
      then
         log_verbose "Tars have not been installed, as \"${DEPENDENCIES_DIR}\" already exists."
      fi
   else
      install_tars "$@"
   fi

   build_stashes "$@"

   if [ -d "${DEPENDENCIES_DIR}" ]
   then
      write_protect_directory "${DEPENDENCIES_DIR}"
   else
      log_fluff "No dependencies have been generated"
   fi

   log_debug "::: build end :::"
}


