
# "a b c" Tutorial

> This tutorial shows you how to orchestrate your own libraries during
> developement.

This directory contains a simple test with 3 folders `a`, `b`,  `c`. Each folder
contains a minimal C-language project of the same name.  Project **c* depends
on **b**. And project **b** depends on **a**.

`a.h`:

```
extern int a( void);
```

`a.c`:

```
int a( void)
{
   return( 1848);
}
```

**b** requires **a** to be present:


`b.h`:

```
extern int b( void);
```

`b.c`:

```
#include <a/a.h>

int b( void)
{
   return( a() == 1848  ? 1 : 0);
}
```

**c** is a little executable, that links with **a** and **b**


`main.c`:

```
#include <b/b.h>
#include <stdio.h>


int main( int  arcg, char *argv[])
{
   printf( "version: %d\n",  b() ? 1848 : 1849);
   return( 0);
}

```

Initially none of the folders contain a `.bootstrap` folder.


Try to build **b** with `cmake`. It will not work, because the header
`<a/a.h>` will not be found.

```console
cd b
mkdir build
cd build
cmake ..
# -- The C compiler identification is AppleClang 7.0.2.7000181
# -- The CXX compiler identification is AppleClang 7.0.2.7000181
# -- Check for working C compiler: /applications/Xcode-7.2.1.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc
# -- Check for working C compiler: /applications/Xcode-7.2.1.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc -- works
# -- Detecting C compiler ABI info
# -- Detecting C compiler ABI info - done
# -- Detecting C compile features
# -- Detecting C compile features - done
# -- Check for working CXX compiler: /applications/Xcode-7.2.1.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++
# -- Check for working CXX compiler: /applications/Xcode-7.2.1.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ -- works
# -- Detecting CXX compiler ABI info
# -- Detecting CXX compiler ABI info - done
# -- Detecting CXX compile features
# -- Detecting CXX compile features - done
# -- Configuring done
# -- Generating done
# -- Build files have been written to: /tutorial/b/build
# Scanning dependencies of target bcd 
# [ 50%] Building C object CMakeFiles/b.dir/src/b.c.o
# /tutorial/b/src/b.c:1:10: fatal error: 'a/a.h' file not found
# include <a/a.h>
#         ^
# 1 error generated.
# make[2]: *** [CMakeFiles/b.dir/src/b.c.o] Error 1
# make[1]: *** [CMakeFiles/b.dir/all] Error 2
# make: *** [all] Error 2mu
#
cd ../..
```

## mulle-bootstrap to the rescue

If you don't have cmake installed yet, you can use `mulle-bootstrap` to install
it (on OS X and Linux). Here we set up **mulle-bootstrap** to fetch cmake.


```console
cd b
mulle-bootstrap init
echo "cmake" >> .bootstrap/brews
```

At that point a `.bootstrap` will be created with some default
content. Take the option to edit **repositories** and you should be in an editor
seeing:

```shell
# add projects that should be cloned with git in order
# of their inter-dependencies
#
# some possible types of repository specifications:
# http://www.mulle-kybernetik.com/repositories/MulleScion
# git@github.com:mulle-nat/MulleScion.git
# ../MulleScion
# /Volumes/Source/srcM/MulleScion
#
```
Lines starting with a '#' are comments, these are just useless fluff in the
long run, so delete them all, and add a line containing 'a'.
The file now looks like this.

`.bootstrap/repositories`:

```
a
```

Alright, ready to bootstrap.  First lets see what **mulle-bootstrap** will do
using the `-n`option

```console
mulle-bootstrap -n
# Dry run is active.
# mkdir -p .repos
# There is a ../a folder in the parent
# directory of this project.
# Use it ? (y/N)
```

**a** will be found in the parent directory, and you have the option to use it,
which you should do.

```console
# Use it ? (y/N) y
# ../a is not a git repository (yet ?)
# So symlinking is the only way to go.
# ln -s -f ../../a .repos/a
# Symlinking a ...
# ==> ln -s -f ../../a .repos/a
# ==> [ -e .repos/a ]
# ==> [ -e .repos/a ]
# ==> [ -e .repos/a ]
# ==> mkdir -p .repos
# ==> touch .repos/.fetch_update_started
# Dry run is active.
# ==> mkdir -p .repos
# Dry run is active.
# No repositories in ".repos", so nothing to build.
```

It can not preview the build stage, because there are no repositories really
setup yet.

The conservative choice now is to do it in two steps. `mulle-bootstrap fetch`
and the `mulle-bootstrap build`. `mulle-bootstrap` without a command
combines both steps into one.

Lets go with `mulle-bootstrap fetch` first, so we can examine the build
processs afterwards. It will be just like above, but the symlink should be in
place now.

```
mulle-bootstrap fetch
# There is a ../a folder in the parent
# directory of this project.
# Use it ? (y/N) > y
# ../a is not a git repository (yet ?)
# So symlinking is the only way to go.
# Symlinking a ...
```

Now lets see what `mulle-bootstrap build` will do:

```console
Dry run is active.
==> mkdir -p .repos/.zombies
==> touch .repos/.zombies/a
Dry run is active.
==> [ -e .repos/a ]
Let cmake do a Release build of a for SDK Default in "build/.repos/Release/a" ...
==> mkdir -p /tmp/tutorial/b/dependencies/include
==> mkdir -p /tmp/tutorial/b/dependencies/Release/lib
==> mkdir -p /tmp/tutorial/b/dependencies/Release/Frameworks
==> mkdir -p /tmp/tutorial/b/dependencies/Release/lib
==> mkdir -p /tmp/tutorial/b/dependencies/Release/Frameworks
==> mkdir -p build/.repos/.logs
==> mkdir -p build/.repos/Release/a
==> cd build/.repos/Release/a
==> cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_SYSROOT=/applications/Xcode-7.2.1.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk -DDEPENDENCIES_DIR=/tmp/tutorial/b/dependencies -DCMAKE_INSTALL_PREFIX:PATH=/tmp/tutorial/b/dependencies/tmp/usr/local -DCMAKE_C_FLAGS=-I/tmp/tutorial/b/dependencies/include -F/tmp/tutorial/b/dependencies/Release/Frameworks -F/tmp/tutorial/b/dependencies/Release/Frameworks -F/tmp/tutorial/b/dependencies/Release/Frameworks -F/tmp/tutorial/b/dependencies/Frameworks  -DCMAKE_CXX_FLAGS=-I/tmp/tutorial/b/dependencies/include -F/tmp/tutorial/b/dependencies/Release/Frameworks -F/tmp/tutorial/b/dependencies/Release/Frameworks -F/tmp/tutorial/b/dependencies/Release/Frameworks -F/tmp/tutorial/b/dependencies/Frameworks  -DCMAKE_EXE_LINKER_FLAGS=-L/tmp/tutorial/b/dependencies/Release/lib -L/tmp/tutorial/b/dependencies/Release/lib -L/tmp/tutorial/b/dependencies/Release/lib -L/tmp/tutorial/b/dependencies/lib  -DCMAKE_SHARED_LINKER_FLAGS=-L/tmp/tutorial/b/dependencies/Release/lib -L/tmp/tutorial/b/dependencies/Release/lib -L/tmp/tutorial/b/dependencies/Release/lib -L/tmp/tutorial/b/dependencies/lib  -DCMAKE_MODULE_PATH=;${CMAKE_MODULE_PATH} .repos/a
==> make -j 12 VERBOSE=1 install
==> cd /tmp/tutorial/b
==> [ -e .repos/a ]
Write-protecting dependencies to avoid spurious header edits
==> chmod -R a-w dependencies
```

Lets do it for real, and use `mulle-bootstrap build`.

```
mulle-bootstrap build
# Let cmake do a Release build of a for SDK Default in "build/.repos/Release/a" ...
# CMake Warning:
#   Manually-specified variables were not used by the project:
#
#     DEPENDENCIES_DIR
#
#
# Write-protecting dependencies to avoid spurious header edits
```

In the end we wind up with the "dependencies" folder, which should contain
the following files (`ls -GFR dependencies`):

~~~
Frameworks/ include/    lib/

dependencies/Frameworks:

dependencies/include:
a/

dependencies/include/a:
a.h

dependencies/lib:
libA.a
~~~


## modify CMakeLists.txt to use dependencies as search path


Put these lines into the `CMakeLists.txt` file to add the proper search paths:

```
include_directories( BEFORE SYSTEM
   dependencies/include
)

link_directories( ${CMAKE_BINARY_DIR}
   dependencies/lib
)
```

`CMakeLists.txt`:

```
cmake_minimum_required (VERSION 3.0)

project (b)

include_directories( BEFORE SYSTEM
   dependencies/include
)

link_directories( ${CMAKE_BINARY_DIR}
   dependencies/lib
)

set(HEADERS
src/b.h)

add_library(b
src/b.c
)

target_link_libraries( b LINK_PUBLIC a)

INSTALL(TARGETS b DESTINATION "lib")
INSTALL(FILES ${HEADERS} DESTINATION "include/b")
```

Now **b** will build:

```
mkdir build
cd build
cmake ..
make
cd ..
```

## Inheriting our work in **c**


Now let's do the same for `c`:

```console
mulle-bootstrap init
echo "b" > .bootstrap/repositories
mulle-bootstrap
```

This will have used the dependency information from b, to automatically also
build a for you in the proper order.

Since the CMakeLists.txt file is already setup properly, you can now just
build and run **c**:

```
mkdir build 2> /dev/null
cd build
cmake ..
make
cd ..
```

And see **c** work

```
cd build
./c
cd ..
```






