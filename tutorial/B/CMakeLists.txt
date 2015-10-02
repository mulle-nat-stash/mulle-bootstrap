cmake_minimum_required (VERSION 3.0)

project (B)

set(HEADERS
src/B.h)

add_library(B
src/B.m
)


target_link_libraries( B LINK_PUBLIC A)

INSTALL(TARGETS B DESTINATION "lib")
INSTALL(FILES ${HEADERS} DESTINATION "include/B")
