# Settings

> <font color="green">**Important: Setting values are delimited by LF.**</font>

1. All files in lowercase are regular settings
2. All files in uppercase are expansion settings (somewhar like an environment variable).These are not described here.
3 Config settings are local to the system. They are not part of a
distribution.


Root Settings
===================


Setting Name            |  Description
------------------------|----------------------------------------
`brews`                 | Homebrew formulae to install
`repositories`          | Repositories to clone, specify the URLs
`embedded_repositories` | Repositories to embed, specify the URLs
`tarballs`              | Tarballs to install (currently filesystem only)


> None of these settings are required, they are used to control the
> **mulle_bootstrap** build processs
>


Build Settings
===================


Setting Name                     |  Description                               | Default
---------------------------------|--------------------------------------------|---------------
`build_preferences`              | list order of preferred build tools. Will  |
                                 | be used in deciding if to use cmake or     |
                                 | xcodebuild, if both are available          | config setting
`configurations`                 | configurations to build                    | config setting
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
`sdks`                           | SDKs to build                              | config setting
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
`xcode_project`                  | The Xcode project file to use              |
`xcode_schemes`                  | The Xcode schemes to build                 |
`xcode_targets`                  | The Xcode targets to build                 |


Root Scripts
==========================

`bin/pre-build.sh`
`bin/post-build.sh`
`bin/pre-tag.sh`
`bin/post-tag.sh`


> None of these settings are required, they are used to tweak **mulle_bootstrap**
>
> <font color="green">**Important: Setting values are delimited by LF.**</font>


Config Settings
===================


##### General Settings

Setting Name                      |  Description                                  | Default
----------------------------------|-----------------------------------------------|--------------
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
`embedded_symlinks`               | mulle-bootstrap will attempt to symlink regular repositories       | NO (ignored on MINGW)
`symlinks`                        | mulle-bootstrap will attempt to symlink embedded repositories       | NO (ignored on MINGW)
`update_gitignore`                | add cleanable directories to .gitignore       | YES
`check_usr_local_include`         | do not fetch, if a system header of same      |
                                  | is present in `/usr/local/include`            | NO

##### Build Config Settings

Setting Name                      |  Description                                  | Default
----------------------------------|-----------------------------------------------|--------------
`build_preferences`               | list order of preferred build tools. Will be  |
                                  | used in deciding if to use cmake or           |
                                  | xcodebuild, if both are available             |
                                  | script\nxcodebuild\ncmake\nconfigure          |
`build_foldername`                | OBJROOT, build root for intermediate files    |
                                  | like .o                                       | `build/.repos`
`build_log_foldername`            | name of the output folder for logs            | `build/.repos/.logs
`clean_before_build`              | should mulle-bootstrap clean before building  | YES
`clean_dependencies_before_build` | usually before a build, mulle-bootstrap       |
                                  | cleans dependencies to avoid surprising       |
                                  | worked the second time" builds due to a wrong |
`configurations`                  | configurations to build                       | Release
`framework_dir_name`              | name of the Frameworks folder                 | `Frameworks`
`header_dir_name`                 | name of the headers folder in dependencies.   |
                                  | e.g. You dislike "include" and favor          |
                                  | "headers".                                    | `include`
`library_dir_name`                | as above, but for libraries                   | `lib`
`sdks`                            | SDKs to build                                 | Default
`skip_collect_and_dispense`       | don't collect and dispense products           | NO
`xcodebuild`                      | tool to use instead of xcodebuild (xctool ?)  | `xcodebuild`


##### Init Config Settings

Setting Name                      |  Description                                  | Default
----------------------------------|-----------------------------------------------|--------------
`create_default_files`            | if mulle-bootstrap init should populate       |
                                  | .bootstrap with some default files            | YES
`create_example_files`            | if mulle-bootstrap init should populate       |
                                  | .bootstrap with some example files            | YES
`editor`                          | the editor mulle-bootstrap init should use    |
                                  | to edit repositories                          | EDITOR environment variable
`open_repositories_file`          | if mulle-bootstrap init should open an editor |
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
