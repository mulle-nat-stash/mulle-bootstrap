
> None of these settings are required, they are used to tweak **mulle_bootstrap**
>
> <font color="green">**Important: Setting values are delimited by LF.**</font>


Build Settings (Global only)
===================

#### Search Paths

1. ./bootstrap.auto/settings
2. ./bootstrap.local/settings
3. ./bootstrap/settings

#### Settings


Setting Name            | Description                           |  Default
------------------------|---------------------------------------|----------------------------
buildignore             |  repositories not to build            |
buildorder              |  repositories to build in that order. You only need to specify those, that need ordering. Otherwise mulle-bootstrap build in default sort order by name.   |
configurations          |  configurations to build              | Debug\nRelease
sdks                    |  SDKs to build                        | Default

Build Settings
===================

These settings are usually repository specific, but can be set globally also. If they are
specified globally, they won't be inheritable by other projects bootstrapping this project
as a repository.

#### Search Paths

1. ./bootstrap.local/${reponame}/settings
2. ./bootstrap/${reponame}/settings
3. ./bootstrap.auto/${reponame}/settings
4. ./bootstrap.auto/settings
5. ./bootstrap.local/settings
6. ./bootstrap/settings

#### Settings

Setting Name                   |  Description                              | Default
-------------------------------|-------------------------------------------|---------------
${configuration}.map           | rename configuration for xcodebuild       |
cmake-${configuration}.map     | rename configuration for cmake            |
configure-${configuration}.map | rename configuration for configure        |
xcode_proper_skip_install      | assume SKIP_INSTALL is set correctly in Xcode project                          | NO
xcode_mangle_header_settings   | mangle Xcode header paths. Specifcally PUBLIC_HEADERS_FOLDER_PATH and PRIVATE_HEADERS_FOLDER_PATH        | NO
xcode_mangle_include_prefix    | remove /usr/local from Xcode header paths | NO
xcode_mangle_header_dash       | convert '-' to '_' in Xcode header paths  | NO


Settings Repository Specific
===================


#### Search Paths

1. ./bootstrap.local/${reponame}/settings
2. ./bootstrap/${reponame}/settings
3. ./bootstrap.auto/${reponame}/settings


#### Settings

Setting Name   | Used by       | Description
---------------|---------------|---------------------------
tag            | fetch         | What to checkout after cloning/symlinking a repository.
project        | build,xcode   | The Xcode project file to use
schemes        | build         | The Xcode schemes to build
targets        | build         | The Xcode targets to build

Fetch Settings
===================

1. ./bootstrap.auto/settings
2. ./bootstrap.local/settings
3. ./bootstrap/settings


Setting Name       |  Description
-------------------|----------------------------------------
brews              | Homebrew formulae to install
gems               | Ruby packages to install with gem
gits               | Repositories to clone, specify the URLs
pips               | Python packages to install with pip
taps               | Homebrew taps to install
tarballs           | Tarballs to install (currently filesystem only)



Config Settings
===================

Environment variables use the setting name, transformed to upper case and prepended with "MULLE_BOOTSTRAP_". So preferences is MULLE_BOOTSTRAP_PREFERENCES in the environment.

#### Search Paths

1. ENVIRONMENT
1. ./bootstrap.local/config
2. ./bootstrap/config
3. ./bootstrap.auto/config
5. ~/.mulle-bootstrap

Setting Name                   |  Description                                  | Default
-------------------------------|-----------------------------------------------|----------------
clean_before_build             | should mulle-bootstrap clean before building  | NO
dont_clean_dependencies_before_build |  usually before a build, mulle-bootstrap cleans dependencies to avoid surprising  "it worked the second time" builds due to wrong buildorder
                                                                               | NO
framework_path                  | name of the Frameworks folder                | Frameworks
header_dir_name                 | name of the headers folder in
dependencies. e.g. You dislike "include" and favor "headers".                                                                      | include
library_dir_name                | as above, but for libraries                   | lib
preferences                    | list order of preferred build tools. Will be used in deciding if to use cmake or xcodebuild, if both are available       | script\nxcodebuild\ncmake\nconfigure
headers_c_and_d_prefix  | where the build should put headers, relative to dependencies | /usr/local
others_c_and_d_prefix   | where the build should put other files (excluding libraries, frameworks and headers), relative to dependencies | /usr/local
symlink_forbidden              | mulle-bootstrap will not attempt to symlink          | NO
trace                          | see MULLE_BOOTSTRAP_TRACE for more info   | NO
xcodebuild                     | tool to use instead of xcodebuild (xctool ?) | xcodebuild
                     |                                                     |
clean_folders        | folders to delete for mulle-bootstrap clean         | build/.repos
dist_clean_folders   | folders to delete for mulle-bootstrap clean dist    | .repos\n/.bootstrap.auto
output_clean_folders | folders to delete for mulle-bootstrap clean output  | dependencies
                  |                                                        |
repos_foldername  |  Where to place cloned repositories                    | .repos
output_foldername |  DSTROOT, --prefix of headers and libraries            | dependencies
build_foldername  |  OBJROOT, build root for intermediate files like .o    | build/.repos
      |                                                        |
no_warn_environment_setting | don't warn when a setting is defined by environment        | NO
no_warn_local_setting       | don't warn when a setting is defined by .bootstrap.local   | NO
no_warn_user_setting        | don't warn when a setting is defined by ~/.mulle-bootstrap | NO
      |                                                        |

Fetch Script Settings
==========================

1. ./bootstrap.auto/settings/bin
2. ./bootstrap.local/settings/bin
3. ./bootstrap/settings/bin

pre-install.sh
post-install.sh
pre-upgrade.sh
post-upgrade.sh
pre-tag.sh
post-tag.sh

Build Script Settings
==========================

1. ./bootstrap.local/${reponame}/settings/bin
2. ./bootstrap/${reponame}/settings/bin
3. ./bootstrap.auto/${reponame}/settings/bin

pre-install.sh
post-install.sh
pre-upgrade.sh
post-upgrade.sh
pre-tag.sh
post-tag.sh
