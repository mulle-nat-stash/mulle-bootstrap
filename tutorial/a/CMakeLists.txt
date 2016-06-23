cmake_minimum_required (VERSION 3.0)

project (a)

set(HEADERS
src/a.h)

add_library(A
src/a.c
)

INSTALL(TARGETS A DESTINATION lib)
INSTALL(FILES ${HEADERS} DESTINATION "include/a")
