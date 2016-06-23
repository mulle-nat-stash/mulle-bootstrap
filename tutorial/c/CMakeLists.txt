cmake_minimum_required (VERSION 3.0)

project (c)

include_directories( BEFORE SYSTEM
   dependencies/include
)

link_directories( ${CMAKE_BINARY_DIR}
   dependencies/lib
)


set(HEADERS
src/c.h)

add_library(c
src/c.c
)


target_link_libraries( c LINK_PUBLIC b)

INSTALL( TARGETS c DESTINATION "lib")
INSTALL( FILES ${HEADERS} DESTINATION "include/c")
