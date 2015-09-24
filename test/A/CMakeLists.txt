cmake_minimum_required (VERSION 3.0)

project (A)

set(HEADERS
src/A.h)

add_library(A
src/A.m
)

INSTALL(TARGETS A DESTINATION lib)
INSTALL(FILES ${HEADERS} DESTINATION "include/A")
