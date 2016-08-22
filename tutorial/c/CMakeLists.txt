cmake_minimum_required (VERSION 3.0)

project (c)

include_directories( BEFORE SYSTEM
   dependencies/include
)

link_directories( ${CMAKE_BINARY_DIR}
   dependencies/lib
)


add_executable(c
src/main.c
)


target_link_libraries( c LINK_PUBLIC a b)
