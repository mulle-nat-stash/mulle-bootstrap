cmake_minimum_required (VERSION 3.0)

# use C, because otherwise a CXX compiler is required
project( mulle-bootstrap C)

#
# Primarily used for packaging on Linux
#
# Debian:
#
# ```
# mkdir package
# cd package
# cmake ..
# cpack -G DEB
# ```
#

execute_process( COMMAND ./mulle-bootstrap version
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_BOOTSTRAP_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_BOOTSTRAP_VERSION is ${MULLE_BOOTSTRAP_VERSION} according to mulle-bootstrap")


set( PROJECT_VERSION "${MULLE_BOOTSTRAP_VERSION}")


set( SCRIPTS
mulle-bootstrap
mulle-bootstrap-dotdump
)


if(MINGW)
   set( SCRIPTS
${SCRIPTS}
mulle-mingw-cmake.sh
mulle-mingw-make.sh
mulle-mingw-cpp.sh
mulle-mingw-dumpdef.sh*
)

#
# Todo need to preprocess this to replace paths
#
   set( BATS
mulle-mingw-dumpdef.bat
)

endif()



set( LIBRARY_SCRIPTS
src/mulle-bootstrap-array.sh
src/mulle-bootstrap-auto-update.sh
src/mulle-bootstrap-brew.sh
src/mulle-bootstrap-build.sh
src/mulle-bootstrap-clean.sh
src/mulle-bootstrap-command.sh
src/mulle-bootstrap-common-settings.sh
src/mulle-bootstrap-core-options.sh
src/mulle-bootstrap-copy.sh
src/mulle-bootstrap-defer.sh
src/mulle-bootstrap-dependency-resolve.sh
src/mulle-bootstrap-fetch.sh
src/mulle-bootstrap-functions.sh
src/mulle-bootstrap-gcc.sh
src/mulle-bootstrap-init.sh
src/mulle-bootstrap-local-environment.sh
src/mulle-bootstrap-logging.sh
src/mulle-bootstrap-mingw.sh
src/mulle-bootstrap-mv-force.sh
src/mulle-bootstrap-paths.sh
src/mulle-bootstrap-project.sh
src/mulle-bootstrap-repositories.sh
src/mulle-bootstrap-scm.sh
src/mulle-bootstrap-scripts.sh
src/mulle-bootstrap-settings.sh
src/mulle-bootstrap-show.sh
src/mulle-bootstrap-snip.sh
src/mulle-bootstrap-status.sh
src/mulle-bootstrap-systeminstall.sh
src/mulle-bootstrap-tag.sh
src/mulle-bootstrap-warn-scripts.sh
src/mulle-bootstrap-xcode.sh
src/mulle-bootstrap-zombify.sh
)

INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")


INSTALL( FILES ${BATS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")

#
# future: install into libexec/mulle-bootstrap/${MULLE_BOOTSTRAP_VERSION}
#         allows multiple versions to co-exist (does it really ?)
#
INSTALL( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-bootstrap")


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.txt)
include( CPack)

