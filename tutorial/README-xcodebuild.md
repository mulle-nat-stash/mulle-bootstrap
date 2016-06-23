You can also use xcodebuild instead of cmake. This file lists the few
differerences:


#  Change build_preferences to `xcodebuild`

```console
cd b
mulle-bootstrap init
mkdir -p .bootstrap.local/settings
echo "xcodebuild" >> .bootstrap.local/settings/build_preferences
```


# Set dispense_headers_path to control header output


After `mulle-bootstrap build` we wind up with the "dependencies" folder,
which should contain the following files (`ls -GFR dependencies`):

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

The header file `a.h` is in `dependencies/include`, which is not where we need
it. We want it to be in `dependencies/include/a`.


We can instruct **mulle-bootstrap** to place the headers somewhere else. This
is done on a per-repository basis in `.bootstrap/settings`.


```console
mkdir -p .bootstrap/settings/a
echo "/include/a" > .bootstrap/settings/a/dispense_headers_path
```

Now build it again with **mulle-bootstrap**, the header should appear as
`dependencies/include/a/a.h`, if not you may have made an exciting
mistake (see "Figuring out what went wrong").



#### Tell xcodebuild where the dependencies are

```console
mulle-bootstrap xcode add
# Settings will be added to B.xcodeproj.
# In the long term it may be more useful to copy/paste the
# following lines into a set of local .xcconfig file, that is
# inherited by all configurations.
# -----------------------------------------------------------
# Common.xcconfig:
# -----------------------------------------------------------
# DEPENDENCIES_DIR=$(PROJECT_DIR)/dependencies
# HEADER_SEARCH_PATHS=$(DEPENDENCIES_DIR)/include /usr/local/include $(inherited)
# LIBRARY_SEARCH_PATHS=$(DEPENDENCIES_DIR)/$(LIBRARY_CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)/lib $(DEPENDENCIES_DIR)/$(LIBRARY_CONFIGURATION)/lib $(DEPENDENCIES_DIR)/$(EFFECTIVE_PLATFORM_NAME)/lib $(DEPENDENCIES_DIR)/lib /usr/local/lib $(inherited)
# FRAMEWORK_SEARCH_PATHS=$(DEPENDENCIES_DIR)/$(LIBRARY_CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)/Frameworks $(DEPENDENCIES_DIR)/$(LIBRARY_CONFIGURATION)/Frameworks $(DEPENDENCIES_DIR)/$(EFFECTIVE_PLATFORM_NAME)/Frameworks $(DEPENDENCIES_DIR)/Frameworks $(inherited)
# -----------------------------------------------------------
# Debug.xcconfig:
# -----------------------------------------------------------
# #include "Common.xcconfig"
#
# LIBRARY_CONFIGURATION=Debug
# -----------------------------------------------------------
# Release.xcconfig:
# -----------------------------------------------------------
# #include "Common.xcconfig"
#
# LIBRARY_CONFIGURATION=Release
# -----------------------------------------------------------
# Add dependencies/lib and friends to search paths of B.xcodeproj ? (y/N) >
```

where you should say 'y'. Now it will build.

