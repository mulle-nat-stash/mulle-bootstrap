
> None of these settings are required, they are used to tweak **mulle_bootstrap**
>
> <font color="green">**Important: Setting values are delimited by LF.**</font>


Assume you have **a** that depends on **b**.  The following
rules are with respect to **a**.


# What ends up in the .bootstrap.auto folder

1. **a**'s `.bootstrap.local` folder is copied first
2. **a**'s `.bootstrap` folder contents are added (except `.bootstrap/config`),

3. **b**'s `.bootstrap.local` folder is ignored
4. any **file** in **b**'s `.bootstrap` folder except the file
`embedded_repositories` is merged in. If it would overwrite a file copied
from  **a**'s' `.bootstrap.local` the merge is not done.
5. **b**'s `.bootstrap/settings` and `.bootstrap/config` folders are ignored
6. any other **folder** from **b**'s' `./bootstrap`folder is copied, if it
doesn't overwrite an existing folder.


Mergable Settings
===================

1. `.bootstrap.local`
2. `.bootstrap`       (Merge)


##### Fetch Settings

Setting Name            |  Description
------------------------|----------------------------------------
`brews`                 | Homebrew formulae to install
`repositories`          | Repositories to clone, specify the URLs
`embedded_repositories` | Repositories to embed, specify the URLs
`taps`                  | Homebrew taps to install
`tarballs`              | Tarballs to install (currently filesystem only)
                        |

##### Build Settings

All build settings are searched OS specific first and then globally.
Example: on OS X, "build_ignore.darwin" will be searched first followed
by a search for "build_ignore".

Setting Name            |  Description
------------------------|----------------------------------------
`build_ignore`          | repositories not to build



Build Settings
===================

These settings are usually repository specific, but can be set globally also.

#### Search Paths

1. `.bootstrap.local/${reponame}`
2. `.bootstrap/${reponame}`          (Inheritable)

3. `.bootstrap.local/settings`
4. `.bootstrap/settings`
5. `.bootstrap/public_settings`       (Inheritable)


#### Settings

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



Repository Specific Settings
===================

Some settings are not supplied by root build settings.

#### Search Paths

1. `.bootstrap.local/${reponame}`
2. `.bootstrap/${reponame}`       (Inheritable)


#### Settings

Setting Name     | Used by       | Description
-----------------|---------------|---------------------------
`tag`            | fetch         | What to checkout after fetching a
                 |               | repository. (Preferably don't use)
`xcode_project`  | build,xcode   | The Xcode project file to use
`xcode_schemes`  | build         | The Xcode schemes to build
`xcode_targets`  | build         | The Xcode targets to build


Scripts
==========================

Scripts are run at various times during the fetch, build and tag process.
Root scripts must be aware, that they will be called for every repository.

1. `.bootstrap.local/${reponame}/bin`
2. `.bootstrap/${reponame}/bin`     (Inheritable)

3. `.bootstrap.local/settings/bin`
4. `.bootstrap/settings/bin`
5. `.bootstrap/public_settings/bin` (Inheritable)

`pre-install.sh`
`post-install.sh`
`pre-upgrade.sh`
`post-upgrade.sh`
`pre-tag.sh`
`post-tag.sh`



Config Settings
===================

Environment variables use the setting name, transformed to upper case and
prepended with "MULLE_BOOTSTRAP_". So "preferences" is `MULLE_BOOTSTRAP_PREFERENCES`
in the environment. These can only be specified locally. They are not inherited.

#### Search Paths

1. ENVIRONMENT
2. `.bootstrap.local/config`
3. `~/.mulle-bootstrap`


##### General Settings

Setting Name                      |  Description                                  | Default
----------------------------------|-----------------------------------------------|--------------
`repos_foldername`                | Where to place cloned repositories            | `.repos`
`output_foldername`               | DSTROOT, --prefix of headers and libraries    | `dependencies`
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
`symlink_forbidden`               | mulle-bootstrap will not attempt to symlink   | NO (ignored on MINGW)
`update_gitignore`                | add cleanable directories to .gitignore       | YES
`check_usr_local_include`         | do not install, if a system header of same    |
                                  | is present in `/usr/local/include`            | NO

Build Config Settings

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
