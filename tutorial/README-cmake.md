
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

## First try without mulle-bootstrap

Initially none of the folders contain a `.bootstrap` folder.

Try to build **b** with `cmake`. It will not work, because the header
`<a/a.h>` will not be found.  So first run **cmake**, it will produce the Makefile and then run **make**.

```console
cd b
( mkdir build ; cd build ; cmake -G "Unix Makefiles" .. ; make )
``` 

> On Windows with the MingGW bash, use
>
> ```console
> cd b
> ( mkdir build ; cd build ; `cmake -G "NMake Makefiles" .. ; nmake`)
> ```



It will produce an error like this:

```
/tutorial/b/src/b.c:1:10: fatal error: 'a/a.h' file not found
```

## mulle-bootstrap to the rescue

While being still in **b**:

```console
mulle-bootstrap init -n
```

This will create a `.bootstrap` for you with some default
content. View `b/.bootstrap/repositories` in an editor and you
should be seeing:

```shell
#
# Add repository URLs to this file.
#
# mulle-bootstrap [fetch] will download these into ".repos"
# mulle-bootstrap [build] will then build them into "dependencies"
#
# Each line consists of four fields, only the URL is necessary.
#
# URL;NAME;TAG;SCM
# ================
# ex. foo.com/bla.git;mybla;master;git
# ex. foo.com/bla.svn;;;svn
#
# Possible URLS for repositories:
#
# https://www.mulle-kybernetik.com/repositories/MulleScion
# git@github.com:mulle-nat/MulleScion.git
# ../MulleScion
# /Volumes/Source/srcM/MulleScion
#
```

Lines starting with a '#' are comments, these are fluff that can be
deleted. Lets overwrite the contents with our dependency **a**:

```
echo "a" > .bootstrap/repositories
```

Alright, ready to bootstrap.


```console
mulle-bootstrap
```

will produce the following question:

``` shell
There is a ../a folder in the parent
directory of this project.
Use it ? (y/N)
```

So **a** was found, and you have the option to use it,
which you should do. It will symlink **a** into your project and then mulle-bootstrap will build the library. 

> On Windows in the MingGW bash, this will not work, because there
> is no symlink support. You have to place 'a' under **git** control first
>
> ```
> ( cd ../a;
>   git init ;
>   git add . ;
>   git commit -m "Mercyful Release"
> )
>


Check out the contents of the `b/dependencies` folder.
It should contain the following files (`ls -GFR dependencies`):

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

> On Windows in the MingGW bash, the library will be `a.lib`


## Building **b** 

We need to modify b's `CMakeLists.txt` to use `dependencies/lib` and `dependencies/include` as search paths.


Put these lines into the `CMakeLists.txt` file to add the proper search paths:

```
include_directories( BEFORE SYSTEM
   dependencies/include
)

link_directories( ${CMAKE_BINARY_DIR}
   dependencies/lib
)
```

So that the file looks like this now:

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

Now **b** will be able to build:

```
( cd build ; cmake -G "Unix Makefiles" .. ; make )
```

> Windows Mingw: `( cd build ; cmake -G "NMake Makefiles" .. ; nmake )`


## Inheriting your work in **c**

Now let's do the same for `c`:

> Windows Mingw: Before you do this put **b** into git. Do not add the
> `build` folder, the `addictions` folder or the `dependencies` folder.
> Add the `.bootstrap` folder and all other required files, but ignore the
> `.bootstrap.auto` folder.
>
> ```
> git init
> git add src/ b.xcodeproj/ CMakeLists.txt  .bootstrap
> git commit -m "Mercyful Release"
> ```

```console
mulle-bootstrap init -n
echo "b" > .bootstrap/repositories
mulle-bootstrap
```

This will have used the dependency information from **b**, to automatically also
build **a** for you in the proper order.

Since the **c** `CMakeLists.txt` file is already setup properly, you can now just
build and run **c**:

```
mkdir build 2> /dev/null
( cd build ;
cmake -G "Unix Makefiles" .. ;
make ;
./c )
```

> Windows:
> ```
> mkdir build 2> /dev/null
> ( cd build ; 
> cmake -G "NMake Makefiles" .. ;
> nmake ;
> ./c.exe )
```





