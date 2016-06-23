cmake_minimum_required (VERSION 3.0)

project (b)

set(HEADERS
src/b.h)

add_library(b
src/b.c
)


target_link_libraries( b LINK_PUBLIC a)

INSTALL(TARGETS b DESTINATION "lib")
INSTALL(FILES ${HEADERS} DESTINATION "include/b")
