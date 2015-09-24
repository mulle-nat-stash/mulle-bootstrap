cmake_minimum_required (VERSION 3.0)

project (C)

set(HEADERS
src/C.h)

add_library(C
src/C.m
)


target_link_libraries( C LINK_PUBLIC B)

INSTALL(TARGETS B DESTINATION "lib")
INSTALL(FILES ${HEADERS} DESTINATION "include/C")
