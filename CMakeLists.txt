cmake_minimum_required (VERSION 3.0)

project( mulle-bootstrap)

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
src/mulle-bootstrap-shell.sh
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

#
# future: install into libexec/mulle-bootstrap/${MULLE_BOOTSTRAP_VERSION}
#         allows multiple versions to co-exist (does it really ?)
#
INSTALL( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-bootstrap")

#
# CPack and project specific stuff
#
######

set( CPACK_PACKAGE_NAME "mulle-bootstrap")
set( CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set( CPACK_PACKAGE_CONTACT "Nat! <nat@mulle-kybernetik.de>")
set( CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_SOURCE_DIR}/README.md")
set( CPACK_PACKAGE_DESCRIPTION_SUMMARY "👢 Cross platform dependency manager - using bash and cmake")
set( CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")
set( CPACK_STRIP_FILES false)

# stuff needed for Debian
# memo: its impossible to check for chosen generator here
#
# CPackDeb doesn't produce 100% proper debian file unfortunately
#
set( CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://github.com/mulle-nat/mulle-bootstrap")
# not strictly required
#set( CPACK_DEBIAN_PACKAGE_DEPENDS "cmake (>= 3.0.0)")

# stuff needed for RPM

set( CPACK_RPM_PACKAGE_VENDOR "Mulle kybernetiK")

######
#
# must be after CPACK_PACKAGE_VERSION
include( CPack)

