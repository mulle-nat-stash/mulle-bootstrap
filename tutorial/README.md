---
layout: post
author: Nat!
title:
open_comments: true
date: 2015-10-02 20:48
---
# "A B C" Tutorial

This directory contains a simple test with 3 folder A B C, each containing a
minimal Objective-C project.  C depends on B, which depends on A.
A depends on a system library "Foundation", which is a given.

A.h

```objectivec
#import <Foundation/Foundation.h>

@interface A : NSObject

@end
```

B imports A, but expects the header to reside in a subdirectory A

B.h

```objectivec
#import <A/A.h>

@interface B : A

@end
```

C is quite like B.

C.h

```objectivec
#import <B/B.h>

@interface C : B

@end
```

Initially none of the folders contain a `.bootstrap` folder.

## Using xcodebuild


### First problem: the header isn't found

Try to build B with `xcodebuild`. It will not work, because the header
`<A/A.h>` will not be found.

The first step is to initalize A for **mulle-bootstrap**. You use

```console
$ mulle-bootstrap init
```

At that point a `.bootstrap` will be created with some default
content. Take the option to edit **gists** and you should be in an editor
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
long run, so delete them all, and add a line containing 'A'.
The file now looks like this.

```
$ cat .bootstrap/gists
A
```

Alright, ready to bootstrap.  First lets see what **mulle-bootstrap** will do
using the `-n`option

```console
$ mulle-bootstrap -n
Dry run is active.
mkdir -p .repos
There is a ../A folder in the parent
directory of this project.
Use it instead of cloning A ? (y/N)
```

**A** will be found in the parent directory, and you have the option to use it, which you should do.

```console
y
../A is not a git repository (yet ?)
So symlinking is the only way to go.
ln -s -f ../../A .repos/A
[ -e .repos/A ]

Dry run is active.
No repos fetched, nothing to do.
```

It can not preview the build stage, because there are no repositories really setup yet.

The conservative choice now is to do it in two steps. **mulle-bootstrap fetch** and then **mulle-bootstrap build**. **mulle-bootstrap** alone combined both steps into one.

Lets go with **mulle-bootstrap fetch** first, so we can examine the build
processs afterwards. It will be just like above, but the symlink should be in place now.

```console
$ mulle-bootstrap -n build
Dry run is active.
mkdir -p dependencies/usr/local/include
ln -s usr/local/include dependencies/include
Do a xcodebuild Debug of A for SDK Default  ...
"xcodebuild" "install"  -project "./A.xcodeproj" -configuration "Debug" ARCHS='${ARCHS_STANDARD_32_64_BIT}' DEPLOYMENT_LOCATION=YES DSTROOT='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/tmp' INSTALL_PATH='/lib/Debug' SYMROOT='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/build/.repos/Debug/A/' OBJROOT='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/build/.repos/Debug/A/obj' ONLY_ACTIVE_ARCH=NO SKIP_INSTALL=NO HEADER_SEARCH_PATHS='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/include /usr/local/include /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include' LIBRARY_SEARCH_PATHS='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/include /usr/local/include /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/lib/Debug /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/lib /usr/local/lib' FRAMEWORK_SEARCH_PATHS='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/include /usr/local/include /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/lib/Debug /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/lib /usr/local/lib /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/Frameworks/Debug /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/Frameworks'
Collecting and dispensing "A" "Debug" products
Do a xcodebuild Release of A for SDK Default  ...
"xcodebuild" "install"  -project "./A.xcodeproj" -configuration "Release" ARCHS='${ARCHS_STANDARD_32_64_BIT}' DEPLOYMENT_LOCATION=YES DSTROOT='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/tmp' INSTALL_PATH='/lib/Release' SYMROOT='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/build/.repos/Release/A/' OBJROOT='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/build/.repos/Release/A/obj' ONLY_ACTIVE_ARCH=NO SKIP_INSTALL=NO HEADER_SEARCH_PATHS='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/include /usr/local/include /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include' LIBRARY_SEARCH_PATHS='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/include /usr/local/include /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/lib/Release /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/lib /usr/local/lib' FRAMEWORK_SEARCH_PATHS='/Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/include /usr/local/include /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/lib/Release /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/lib /usr/local/lib /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/Frameworks/Release /Volumes/Source/srcM/mulle-bootstrap/tutorial/B/dependencies/Frameworks'
Collecting and dispensing "A" "Release" products
```

As the saying goes "Probieren geht über Studieren", so lets do it for real,
and use **mulle-bootstrap** build (or just **mulle-bootstrap**). This creates
a lot of output now shown here.

In the end we wind up with the "dependencies" folder, which should contain
the following files (`ls -GFR dependencies`):

~~~
include@
dependencies/lib/Debug/libA.a
dependencies/lib/Release/libA.a
dependencies/usr/local/include/A.h
~~~

**include@** is a symlink to `/usr/local/include`, that will always be there. There is a library **libA** for each configuraration. The include file is in `dependencies/usr/local/include`, which is not where we need it.

#### Tweaking the output

We can instruct **mulle-bootstrap** to place the headers somewhere else. This is done on a per-repository basis in `.bootstrap/settings`. Since it's an xcode project, it's more foolproof to use "xcode_public_headers":

```console
$ mkdir -p .bootstrap/settings/A
$ echo "/usr/local/include/A" > .bootstrap/settings/A/xcode_public_headers
```

Now build it again with **mulle-bootstrap**, the header should appear as `dependencies/usr/local/include/A/A.h`, if not you may have made an exciting mistake (see "Figuring out what went wrong").

Ok, the proof is in the pudding. Let's build B again with **xcodebuild**.

#### The header isn't found again

We



## Using cmake

Then try it again with cmake. Here we set up **mulle-bootstrap** to fetch cmake
if not present and to use cmake as the only build tool:

```console
cd C
mulle-bootstrap clean    # throw away results from "Using xcodebuild"
echo "cmake" >> .bootstrap/brews
mkdir -p .bootstrap/settings
echo "cmake" >> .bootstrap/settings/build_preferences
mulle-bootstrap
```

Now at this point it can be assumed that C.xcodeproj already has the proper
settings, from doing the example above, but doing it again should be harmless:

```console
mulle-bootstrap xcode
xcodebuild
```

In many cases, especially if you didn't change any mulle-bootstrap settings,
you can also easily remove the added settings again:

```console
mulle-bootstrap xcode remove
xcodebuild  # fails again
cd ..
```

## Play around with some settings


### Clone or symlink from local folder

Change the `gits` file of C and see what happens

```console
mulle-bootstrap clean dist
echo "git@github.com:invalid-user/B" > ".bootstrap.local/gits"
mulle-bootstrap
```


