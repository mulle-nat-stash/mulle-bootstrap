# A B C

## Using xcodebuild

This directory contains a simple test, where C depends on B, which depends on A.
Issue these commands in a terminal:

```
cd C
mulle-bootstrap
```

This should create a `dependencies` folder with the stuff you need in `C`:

```console
ls -R dependencies
```

Building the project **C** itself won't work yet, because the `dependencies` folder is not yet known to the project `C.xcodeproj`.

```console
xcodebuild  # fails
```

You could add the search paths to HEADER_SEARCH_PATHS, LIBRATY_SEARCH_PATHS and FRAMEWORK_SEARCH_PATHS manually, but why bother, when **mulle-bootstrap** can do it for you:

```console
mulle-bootstrap  setup-xcode
xcodebuild  # works
cd ..
```

## Using cmake

Then try it again with cmake. Here we set up **mulle-bootstrap** to fetch cmake if not present and to use cmake as the only build tool:

```console
cd C
mulle-bootstrap clean    # throw away results from "Using xcodebuild"
echo "cmake" >> .bootstrap/brews
echo "cmake" >> .bootstrap/preferences
mulle-bootstrap
```

Now at this point it can be assumed that C.xcodeproj already has the proper settings, from doing the example above, but doing it again should be harmless:

```console
mulle-bootstrap setup-xcode
xcodebuild
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

# Big

This shows a more complicated setup, where **mulle-bootstrap** clones and builds a xcodebuild based projeczt, a cmake make based project and a configure based project.

```console
cd Big
mulle-bootstrap
```

