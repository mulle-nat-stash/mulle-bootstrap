
> None of these settings are required, they are used to tweak **mulle_bootstrap**
>
> <font color="green">**Important: Setting values are delimited by LF.**</font>


Build Settings (Global only)
===================

#### Search Paths

1. `.bootstrap.auto/settings`
2. `.bootstrap.local/settings`
3. `.bootstrap/settings`

#### Settings


Setting Name              | Description                           |  Default
--------------------------|---------------------------------------|----------------------------
`build_ignore`            | repositories not to build             |
`build_order`             | repositories to build in that order.  |
                          | You only need to specify those, that  |
                          | need ordering. Otherwise              |
                          | mulle-bootstrap builds in default `ls`|
                          | sort order by name.                   |
`configurations`          | configurations to build               | Debug\nRelease
`sdks`                    | SDKs to build                         | Default


Build Settings
===================

These settings are usually repository specific, but can be set globally also. If they are
specified globally, they won't be inheritable by other projects bootstrapping this project
as a repository.

#### Search Paths

1. `.bootstrap.local/${reponame}/settings`
2. `.bootstrap/${reponame}/settings`
3. `.bootstrap.auto/${reponame}/settings`

4. `.bootstrap.auto/settings`
5. `.bootstrap.local/settings`
6. `.bootstrap/settings`

#### Settings

Setting Name                     |  Description                               | Default
---------------------------------|--------------------------------------------|---------------
`build_preferences`              | list order of preferred build tools. Will  |
                                 | be used in deciding if to use cmake or     |
                                 | xcodebuild, if both are available          |  config setting
`${configuration}.map`           | rename configuration for xcodebuild        |
`cmake-${configuration}.map`     | rename configuration for cmake             |
`configure-${configuration}.map` | rename configuration for configure         |
`dispense_headers_path`          | where the build should put headers,        |
                                 | relative to dependencies. Preferred way    |
                                 | for cmake and  configure projects to place |
                                 | headers.                                   | `/usr/local/${HEADER_DIR_NAME}`
`dispense_other_path`            | where the build should put other files     |
                                 | (excluding libraries, frameworks and headers),|
                                 | relative to dependencies                   | `/usr/local`
`dispense_other_product`         | if the build should dispense other files   | NO
`xcode_proper_skip_install`      | assume SKIP_INSTALL is set correctly in    |
                                 | Xcode project                              | NO
`xcode_public_headers`           | Substitute for PUBLIC_HEADERS_FOLDER_PATH  |
`xcode_private_headers`          | Substitute for PRIVATE_HEADERS_FOLDER_PATH |
                                 |                                            |
`xcode_mangle_header_paths`      | Mangle Xcode header paths. Specifcally     |
                                 | PUBLIC_HEADERS_FOLDER_PATH and             |
                                 | PRIVATE_HEADERS_FOLDER_PATH. Mangling is   |
                                 | controlled by the following settings       | NO
`xcode_mangle_include_prefix`    | remove /usr/local from Xcode header paths  | NO
`xcode_mangle_header_dash`       | convert '-' to '_' in Xcode header paths   | NO



Settings Repository Specific
===================


#### Search Paths

1. `.bootstrap.local/${reponame}/settings`
2. `.bootstrap/${reponame}/settings`
3. `.bootstrap.auto/${reponame}/settings`


#### Settings

Setting Name     | Used by       | Description
-----------------|---------------|---------------------------
`tag`            | fetch         | What to checkout after cloning/symlinking a repository.
`project`        | build,xcode   | The Xcode project file to use
`schemes`        | build         | The Xcode schemes to build
`targets`        | build         | The Xcode targets to build


Fetch Settings
===================

1. `.bootstrap.auto/settings`
2. `.bootstrap.local/settings`
3. `.bootstrap/settings`


Setting Name            |  Description
------------------------|----------------------------------------
`brews`                 | Homebrew formulae to install
`gems`                  | Ruby packages to install with gem
`repositories`          | Repositories to clone, specify the URLs
`embedded_repositories` | Repositories to embed, specify the URLs
`pips`                  | Python packages to install with pip
`taps`                  | Homebrew taps to install
`tarballs`              | Tarballs to install (currently filesystem only)



Config Settings
===================

Environment variables use the setting name, transformed to upper case and
prepended with "MULLE_BOOTSTRAP_". So preferences is MULLE_BOOTSTRAP_PREFERENCES
in the environment.

#### Search Paths

1. ENVIRONMENT
2. `.bootstrap.local/config`
3. `.bootstrap/config`
4. `.bootstrap.auto/config`
5. `~/.mulle-bootstrap`

##### General Settings

Setting Name                      |  Description                                  | Default
----------------------------------|-----------------------------------------------|--------------
`repos_foldername`                | Where to place cloned repositories            | `.repos`
`output_foldername`               | DSTROOT, --prefix of headers and libraries    | `dependencies`
`trace`                           | see `MULLE_BOOTSTRAP_TRACE` for more info     | NO
`terse`                           | set output to less verbose                    | NO
`verbose`                         | set output to more verbose                    | NO
`no_warn_environment_setting`     | don't warn when a setting is defined by       |
                                  | environment                                   | NO
`no_warn_local_setting`           | don't warn when a setting is defined by       |
                                  | `.bootstrap.local`                            | NO
`no_warn_user_setting`            | don't warn when a setting is defined by       |
                                  | `~/.mulle-bootstrap`                          | NO


##### Fetch Config Settings

Setting Name                      |  Description                                  | Default
----------------------------------|-----------------------------------------------|--------------
`absolute_symlinks`               | Use absolute symlinks instead of relatives    | NO
`symlink_forbidden`               | mulle-bootstrap will not attempt to symlink   | NO
`update_gitignore`                | add cleanable directories to .gitignore       | YES
`check_usr_local_include`         | do not install, if a system header of same    |
                                  | is present in `/usr/local/include`            | NO

Build Config Settings

Setting Name                      |  Description                                  | Default
----------------------------------|-----------------------------------------------|--------------
`build_preferences`               | list order of preferred build tools. Will be  |
                                  | used in deciding if to use cmake or           |
                                  | xcodebuild, if both are available             | script\nxcodebuild\ncmake\nconfigure
`build_foldername`                | OBJROOT, build root for intermediate files    |
                                  | like .o                                       | `build/.repos`
`build_log_foldername`            | name of the output folder for logs            | `build/.repos/.logs
`clean_before_build`              | should mulle-bootstrap clean before building  | YES
`clean_dependencies_before_build` | usually before a build, mulle-bootstrap       |
                                  | cleans dependencies to avoid surprising       |
                                  | worked the second time" builds due to a wrong |
`framework_dir_name`              | name of the Frameworks folder                 | `Frameworks`
`header_dir_name`                 | name of the headers folder in dependencies.   |
                                  | e.g. You dislike "include" and favor          |
                                  | "headers".                                    | `include`
`library_dir_name`                | as above, but for libraries                   | `lib`
`skip_collect_and_dispense`       | don't collect and dispense products           | NO
`xcodebuild`                      | tool to use instead of xcodebuild (xctool ?)  | `xcodebuild`


##### Init Config Settings

Setting Name                    |  Description                                  | Default
--------------------------------|-----------------------------------------------|--------------
`create_default_files`          | if mulle-bootstrap init should populate       |
                                | .bootstrap with some default files            | YES
`create_example_files`          | if mulle-bootstrap init should populate       |
                                | .bootstrap with some example files            | YES
`editor`                        | the editor mulle-bootstrap init should use    |
                                | to edit repositories                          | EDITOR environment variable
`open_repositories_file`        | if mulle-bootstrap init should open an editor |
                                | to edit repositories (YES/NO/ASK)             | ASK


##### Clean Config Settings

Setting Name                      |  Description                                  | Default
----------------------------------|-----------------------------------------------|--------------
`clean_empty_parent_folders`      | e.g remove build, if its empty after removing |
                                  | build/.repos ?                                | YES
`clean_folders`                   | folders to delete for mulle-bootstrap clean   | `build/.repos`
`dist_clean_folders`              | folders to delete for mulle-bootstrap clean   |
                                  | dist                                          | `.repos\n/.bootstrap.auto`
`output_clean_folders`            | folders to delete for mulle-bootstrap clean   |
                                  | output                                        | `dependencies`


Fetch Script Settings
==========================

1. `.bootstrap.auto/settings/bin`
2. `.bootstrap.local/settings/bin`
3. `.bootstrap/settings/bin`

`pre-install.sh`
`post-install.sh`
`pre-upgrade.sh`
`post-upgrade.sh`
`pre-tag.sh`
`post-tag.sh`


Build Script Settings
==========================

1. `.bootstrap.local/${reponame}/settings/bin`
2. `.bootstrap/${reponame}/settings/bin`
3. `.bootstrap.auto/${reponame}/settings/bin`

`pre-install.sh
`post-install.sh`
`pre-upgrade.sh`
`post-upgrade.sh`
`pre-tag.sh`
`post-tag.sh`
