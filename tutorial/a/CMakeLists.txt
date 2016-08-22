cmake_minimum_required (VERSION 3.0)

project (a)

set(HEADERS
src/a.h)

add_library(a
src/a.c
)

INSTALL(TARGETS a DESTINATION lib)
INSTALL(FILES ${HEADERS} DESTINATION "include/a")
