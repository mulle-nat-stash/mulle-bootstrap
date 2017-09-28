### 3.13.5

* fix corruption of motd file

### 3.13.4

* protect CC renames affecting subsequent builds

### 3.13.3

* add --lenient flag to mulle-bootstrap, used in mulle-bootstrap git to not abort on failure

### 3.13.1

* use CC, CXX and MAKE internally and heed possible external environment variable of same name

## 3.13.0

* add mulle-bootstrap log command, for looking at build logs of a specific dependency


### 3.12.4

* MAKE_FLAGS is MAKEFLAGS for consistency

### 3.12.1

* deal with empty/bad repositories more gracefully

## 3.12.0

* Various improvements for mingw. New version number for mulle-tests

### 3.11.2

* improvements for mingw, also improved speed a bit

### 3.11.1

* fixes for mingw
* fix a problem with zip archives tests


## 3.11.0

Clean command reworked

* `mulle-bootstrap clean build` followed by `mulle-bootstrap build` actually rebuilds everything as one would expect. The old functionality is now called `mulle-bootstrap clean cruft`
* `clean build` does not throw away dependencies, use `clean full` for that

## 3.10.0

* new clean command 'full' is now also the new default
* new config `dispense_style` . See [DISPENSE_STYLE](dox/settings/dispense_style/DISPENSE_STYLE.md)


### 3.9.3

* fix some problems with tar archives
* subcommand !!! `mulle-bootstrap shell` has been moved to mulle-sde, a new project

### 3.9.2

* fix for github tar archives having the same name

### 3.9.1

* remove debug -x from release
* fix a bug with renamed non-git repositories

## 3.9.0

* new mulle-bootstrap shell command to make life in a virtual env even easier
* fix various xcode related build bugs
* mulle-bootstrap doesn't do kill 0 anymore
* add `mulle-bootstrap-core-options.sh` for external script users
* `mulle-bootstrap -f build` now forces a rebuild, as one would expect

### 3.8.5

* fix broken xcode build path
* allow some plural synonmys for setting, config, expansion command

### 3.8.4

* fix `Abort now (y/N) > y` not really aborting

### 3.8.3

* fix upgrade and status for tar/zip SCM, which previously errored out

### 3.8.2

* fix setting listings for os specific settings and build settings
in general
* fix reading of dispense settings

### 3.8.1

* fix archive extraction on linux

## 3.8.0

* new build setting `srcdir` where you can specify the subdirectory, that contains configure, CMakeLists et.c

### 3.7.2

* git fetch exception fixed when mirroring

### 3.7.1

* save git mirrors under their fork names

## 3.7.0

* experimentally added ${GITHUB_REMOTE_ORIGIN} expansion, so you can specify
dependencies relative to the original project.
* when moving embedded directories around, mulle-bootstrap will now create
missing target directories
* renamed `clone_cache` to `git_mirror` because that's better. `refresh_cache` is now `refresh_git_mirror`.
* added option `--no-git-mirror`
* added `type` command to introspect the bootstrap topology easier
* avoid superflous updating of mirrored git clones during one session, which
speeds up things considerably, when mirroring
* fix bug of failing symlinks, when the destination itself is accessed via a
symlink

### 3.6.7

* reduce verbosity in some places and hide ugly symlink paths

### 3.6.6

* fix a few regressions

### 3.6.5

* remove superflous set_build_needed

### 3.6.4

* fix accidental create of `.bootstap.local` as a file
* when using clone chaches, mulle-bootstrap update and upgrade now work as one
would expect. It would be good to erase your old clone caches.


### 3.6.3

* fix missing include in warn scripts

### 3.6.2

* fix and improve systeminstall (formerly just install)

### 3.6.1

* bug fixes


## 3.6

* Improved the dependencies copying routing. Now also copies `share` `sbin`
`bin` `libexec` and picks up more possible output directories. `sbin` and `bin`
will me merged into `dependencies/bin`.
* Improve path construction, omitting empty components
* Don't output superflous linefeed with paths
* removed -fb flag, because it's just the same as clean before build.
* Added a --from flag to build, so you can rebuild from a starting point.


### 3.5.4

* fix brews not being installed
* clean dist now also dist cleans minions embedded repositories


### 3.5.4

* fix bug in ${expansion:-default}


### 3.5.2

#### `caches_path`renamed to more sensible `search_path`

* experimentally, don't kill so hard anymore when failing (mostly for
mulle-builds sake)
* Because `mulle-bootstrap setting` now works, init by default does not
create demo files any more. Inverted meaning of -d flag.
* Various improvements to mulle-brew handling
* The paths default is now to output an unquoted one-liner. This is less
correct but simpler.
* Added `mulle-bootstrap run`. See mulle-brew for more details.
* Add proper version check in mulle-functions, so that mulle-brew doesn't
run with wrong libraries

### 3.4.0

* added handling of `additional_repositories`. This is supposed to be used
in `.bootstrap.local`. This way I can specify a "MulleFoundation" dependency
if I want to compile for mulle-objc. But sometimes I want the Apple Foundation.
* finally added list command for `setting`. All that's needed now is a scripts
setting to list all scripts
* -fb automatically adds `-U *` to CMAKEFLAGS so that cached values are ignored,
this reduces a lot of WTF moments.
* `CMAKE_FLAGS` is now `CMAKEFLAGS


### 3.3.0

* `mulle-bootstrap project-path` prints out what it thinks your project path is.
This is helpful for **mulle-build**.
* Improve output of `mulle-bootstrap -v help`.
* An empty expansion in repositories is now an error by default. But you can
change it back to previous behavior with  `mulle-bootstrap config -n empty_expansion_is_error`
* The `-g` option no longer works for `mulle-bootstrap config`, use the `-u`
setting to set values in `~/.bootstrap`. This unconfuses the '-g' which means
`.bootstrap` and not `.bootstrap.local`, the default.
* `mulle-bootstrap expansion -l` works now
* You can now use `<key>=<value>` to set settings and expansions. This makes
it easier to copy/paste show output.
* Missing but not required repositories no longer produce a build error
* added `-fb` as lesser -force mode than -f.
* old Frameworks of previous builds are not a problem anymore
* With config `use_cc_cxx=NO` mulle-bootstrap won't read the compiler to use
from `.CC` and `.CXX`.


### 3.2.0

Do not specify cmake dependency in homebrew formula for mulle-bootstrap, since
cmake is not absolutely required. Rather check this at runtime and output
some helpful hints.


### 3.1.0

You can allow optional fetches to fail my listing repository-names, that
are required. (embeded_repositories <-> embedded_required)
Fixes some bugs.

Still alpha though.


# 3.0

#### New commands: defer, emancipate, flags, status

#### mulle-bootstrap command syntax was related to git, but now it's related
to homebrew and apt-get. This has been done, because I wan't to have mulle-brew
as a separate shell command, and the git syntax doesn't fit.

That means, mulle-bootstrap fetch is now just a deprecated synonym for
mulle-bootstrap install

mulle-bootstrap update is now mulle-bootstrap upgrade.

mulle-bootstrap install is now mulle-bootstrap systeminstall


#### The way settings work as drastically changed too much to list here

* config now returns the default value, if nothing is configured
* various changes in variables

Now               | Before              | Description
------------------|---------------------|--------------------------
DEPENDENCIES_DIR  | DEPENDENCIES_DIR    |
ADDICTIONS_DIR    | ADDICTIONS_DIR      |
BOOTSTRAP_DIR     | BOOTSTRAP_SUBDIR    |
REPOS_DIR         | CLONES_SUBDIR       |
                  | CLONESFETCH_SUBDIR  | Does not exist anymore


* libexec is now found relative to $0 so the install script does not need to
patch anymore. It's also convenient for the test scripts
* various status files are now prefixed with .bootstrap_
* **tag** as a setting does not exist anymore. Now its part of the repositories line
* A lot of options have changed. Too many to mention. Sorry about this, but progres...


### 2.6.1

* fix bug with absolute paths

## 2.6.0

* mulle-bootstrap announces itself to cmake with -DMULLE_EXECUTABLE_VERSION

### 2.5.2

* -v -h gives more help
* renamed -tt  to -tit and -tp to -tip, because it's more logical

### 2.5.1

* Allow --debug and --release as shortcuts for -c Debug and -c Release, because
I am lazy and I expect it.


## 2.5.0

* Improve usage for `mulle-bootstrap init`
* Reduce verbosity for PATH to fluff
* The --no-recursion flag has been fixed, the  old behaviour is now available
as --no-embedded.
* Use eval exekutor for cmake to better inherit CMAKEFLAGS and protect paths
with spaces.
* build now acknowledges --check-usr-local-include also
* With --prefix you can change /usr/local on the commandline for build and fetch


### 2.4.2

Make PATH generation compatible with homebrew shims


### 2.4.1

Exit with 0 when printing version.
Emit better .gitignore code for symlinked embedded repos

## 2.4.0

Fix failing update for projects with only embedded repositories.

* experimental fetch flag -es added. This allows fetch to symlink embedded
repositories.


## 2.3

The main new feature of 2.3 is support for working with different repositories.
E.g. I host releases on GitHub on a branch "release", which are accessed via
https://, but when I develop I use Mulle KybernetiK on branch "master".

The "trick" is to use parameterized branches and urls like so:

```
$ cat .bootstrap/repositories
${MULLE_REPOSITORIES}/mulle-c11;;${MULLE_C11_BRANCH:-release}
$ cat .bootstrap/MULLE_REPOSITORIES
https://github.com/mulle-nat
```

This works for the release part. Locally though in the non-committed
`.bootstrap.local`:

```
$ cat MULLE_REPOSITORIES
nat@mulle-kybernetik.com:/scm/public_git/repositories
$ cat MULLE_C11_BRANCH
master
```

### Changes

* clarified the use of options vs. flags some more. e.g. git GITFLAGS command GITOPTIONS.
* update will now also refresh
* improved refresh check, should now properly detect edited config files, except if the
edit is less than a second after the last refresh run. Death of the hidden -fr flag
* start version checking bootstrap contents
* -f flag will now also try to checkout branches, that are checked out
incorrectly
* fetch gains -i option, to ignore "wrongly" checked out repositories
* fails are prefixed with the command, that caused the failure
* use unexpanded URLs for dependency matches and store those into .bootstrap.auto
* mulle-bootstrap now picks up URL changes and corrects them in fetched
repositiories, but that does not per se force an update.
* try to detect changes in .bootstrap better
* improved retrieval of settings for embedded repositories
* improved dependency code
* some more checks, that embedded repositories do not clobber symlinked content
* added -D bootstrap flag to create .bootstrap.local definition files. Convenient for specifiying alternate URLs for example.


### 2.2.1


* fix for Linux

## 2.2

* `mulle-bootstrap tag` will now also tag embedded repositories
* `mulle-bootstrap git` will now also grace embedded repositories, so `mulle-bootstrap git status -s` is now better
* reworked tag to be more aware of git flags, so `mulle-bootstrap tag -l` now
works

### 2.1.4

* use a safer but uglier method to append to .gitignore

### 2.1.3

* Improve performance especially on windows, due to less superflous refreshes

### 2.1.2

* expose some more flags to usage. Distinguish between flags and options.
* The description of -V was wrong.
* Moved -c to fetch options as -cs to avoid clash with build flags

### 2.1.1

* Improve usage to show more available commands
* redid the IFS setting/resetting chores


## 2.1

**The changes should be harmless, but to be safe
`mulle-bootstrap dist clean` your projects**

This version has some additions, that enable a more flexible use of
embedded repositories to "compose" source trees. Up till 2.1 embedded
repositories were always placed into the project root. Now you can
specify the subdirectory like "src/embedded/foo" (relative to project root).

Better fetch and build code checks that dependencies, that are
installed in `/usr/local` already, need not be fetched again. This can
be helpful, when building brew packages (for example). (**-nb**)

Support for `mulle-build` which has an in general more optimistic approach to
life. 2.3 will focus on making operations faster in the Windows bash shell.

#### Commands

* started on `mulle-bootstrap config`. First implemented setting is
`warn_scripts`. You can turn off scripts warning, with
`mulle-bootstrap config -on dont_warn_scripts`
* added `git` command, so you can say `mulle-bootstrap git status`. Going to
become more useful over time.
* renamed hidden option **-r** to **-l** (sorry)
* **-f** option removed from build/fetch options, as it didn't do anything. The
**-f** for mulle-bootstrap is still there though.
* new **-c** switch to enable checking `/usr/local/include` for dependency libraries
conveniently from the command line. Fix build to add `/usr/local/include` to
build, if `check_usr_local_include` is YES.
* remove obsolete `mulle-bootstrap-project.sh` and `mulle-bootstrap project`.
The idea behind that has been moved to `mulle-build`.

#### Features

* embedded repositories can now be placed at an arbitrary position within your
project tree
* allow build and fetch options to be passed to `bootstrap`
* improved comments in `repositories` and `embedded_repositories` templates
* pass ADDICTIONS_DIR to build systems
* improve optimistic support, by memorizing if a fetch, refresh, build went
thru successfully. The automatic refresh should run much less often now.

#### Cmake

* fixed multiple path settings for cmake
* a project can indicate its preferred CC or CXX compiler by files .CC and .CXX
in it's project root. e.g. `echo "mulle-clang" > .CC`. This can be overridden
by settings. It's there because I have problems when not specifying the compiler
on the command line.

#### Bugfixes

* fixed a problem in the parsing of the repositories file
* fixed some as of yet unknown bugs, by improving some path functions
* changes in deeply embedded repositories are now better tracked
* call warn scripts earlier, when bootstrapping
* fix dry run for commands with output redirection
* fix ALL/NONE in yes no answers to work again


### 2.0.1

Fixes two bugs

* fix problem in refresh using '==' instead of '='
* fix cut not using -s for extra parameters


# 2.0

#### YOUR OLD STUFF MAY NOT RUN ANYMORE

Do a `mulle-bootstrap dist clean`.


### YOUR OLD SETTINGS MAY NOT WORK ANYMORE!

Move all repo specific setting directories from

`.bootstrap/settings/<reponame> `

to

`.bootstrap/<reponame>`

#### YOUR OLD SCRIPTS MAY NOT WORK ANYMORE!

* Fetch script names have changed. *-install.sh is now *-fetch.sh.

#### Changes

* Add pre-build.sh script phase (for libcurl really)
* Brew formulas are now installed locally into "addictions". A folder which
lies besides "dependencies". This is a pretty huge change. By removing pips and
gems, mulle-bootstrap can now claim to do only project relative installs.
* mulle-bootstrap xcode changed to emit a non-xcode project relative
 `$(DEPENDENCIES_DIR)` setting. Admittedly an experimental hack. But the old
 more proper way, didn't work with cmake generated xcode projects.
* reorganized repository structure a bit
* You can now specify ALL (always YES) or NONE (always NO) at the y/n prompt.
* Support for MINGW on Windows for cmake and configure (experimental)
* Finally added a proper dependency resolver
* -f option now recognized by build and fetch
* rewrote mulle-bootstrap so that the files in libexec are included and not
executed, which is nicer for less environment pollution and ever so slightly
better performance.
* rewrote mulle-bootstrap so that it works on systems, which do not have
symlinks available.  This meant that I had to redo the whole settings
inheritance scheme.
* -v is now more interesting to watch
* renamed build setting OTHER_CPPFLAGS to OTHER_CXXFLAGS (!)
* UNAME is now simplified and lowercased(!)
* redid the settings merge and inheritance logic. It's now a bit more scrutable.
* removed build_order from settings
* script names have changed. For instance, post-install.sh is now post-fetch.sh.
* dist-clean is gone, now dist means "clean dist". You can also say dist clean
it doesn't matter.
* don't pollute .gitignore with embedded repositories inside .repos#
* reduced configurability of mulle-bootstrap, since I didn't use it so far much and it slows things down on MINGW


## 1.1

* Fix tar install, which was broken
* Fix some wordings
* You can now put configuration setting like variables into the URL. Like so:
   https://${host:-www.mulle-kybernetik.com}:foo.git. Define the host like
   a regular fetch setting. `echo "x.y.com" > .bootstrap/host`
* Fix help screen for refresh and update
* Don't complain if there are no dependencies generated


# 1.0

Version 1.0 breaks compatibility with the previous version. You should "clean"
everything.

* **change in the dependencies/ structure**
   it's now dependencies/Debug/lib for Debug and dependencies/lib for Release
* The default built is Release only
* mulle-bootstrap tag can now '-f' force tags and '-d' delete tags
* mulle-bootstrap no longer places headers into `dependencies/usr/local/include`
but just into `dependencies/include`
* the 'tag' command is now less powerful. It just tags the fetched repositories,
because that's mulle-bootstraps scope. The tag 'script facility' has been
eliminated.
* new clean target "install"
* removed convert-pre-0.10 and ibuild commands
* ConsoleMovies are gone, I am too lazy to maintain them.
* Improve generation of -F and -L flags in cmake and configure
* cmake and configure always add `/usr/local/include` and link with `/usr/local/lib`
(mostly due to brew installing dependencies there).
* redid the verbosity logging with -v, -vv , -vvv, -t
* clean before build is no longer the default

## 0.26

* Check library scripts version vs. executable version (paranoia)
* Skip Dirty Harry with -f flag.
* improve FAQ a little
* Reverse oder of repositories when updating, because this catches deep
  renames. Update now also fetches repositories, if they aren't there
  yet.
* Make the Dirty Harry check less foolproof, but also less annoying.


## 0.25

*  Remove python dependency
*  **bootstrap: refresh between fetch and build**


## 0.24

*  Fix releasenotes underscores
*  Fix xcodebuild path


## 0.23

*  Added -k options to build, to control cleaning before build.
   You can now specify the default configurations to build with -c.
   e.g. `mulle-bootstrap -c "Debug"
*  Improved library and frameworks searchpath generation.
*  You can pass build a `-j <cores>` flag, for cmake/make to parallelize
   the build.
*  Specify `ARCHS='${NATIVE_ARCH_ACTUAL}' mulle-bootstrap build`, when you
   want to override the ARCHS setting for an Xcode build. Kinda hackish.
*  xcodebuild routine does not overwrite `INSTALL_PATH` anymore.
*  `mulle-bootstrap clean` has **output** as the new default
*  Fix accidental IFS overwrite problem, resulting in git calls failing
*  Install brews first, since they might load prerequisites for shell scripts.
*  Allow user to specify `source_dir` build setting for projects, that do
   not have CMakeLists.txt or .xcodeproj or configure in the top level.
*  the Source Code Management system is no longer read from a .scm file, but
   instead specified in the fourth field of repositories. The default is still
   git and the only available alternative is still svn.
      url;name;branch;scm

*  Improve repository merge order again.
*  Fix cmake to not always compile with DEBUG options. Allow to supply
   cmake flags via "cmakeflags" root build setting.


## 0.22

*  Fix repository order when merging. You should know, that the
   repository order in `.bootstrap/repositories` needs to be in proper sorted
   order. Only than can mulle-bootstrap figure out the recursive dependencies
   correctly.
*  Allow clone of specific branches by changing the repository spec line to
   url;name;branch

      ```
      https://www.mulle-kybernetik.com/repositories/mulle-configuration;;MulleFoundation
      ```
      uses the default name, but fetches the MulleFoundation branch.
*  Huge change:  CMake (and configure) are now the prefered build systems even
   on OS X (if a `CMakeLists.txt` is available). xcodebuild becomes a fallback
   preference. The reasons are:
      1.  CMake + Make seem faster than xcodebuild
      2.  It forces me to keep up the CMakeLists.txt with the Xcode project
   If you don't like it change the build setting 'build_preferences'.
*  mulle-bootstrap recognizes that bare repositories need to be cloned more
   often now, if not always.
*  Make mulle-bootstrap more resilient against aborted fetches, added Dirty
   Harry quote.
*  Uses `CMAKE_EXE_LINKER_FLAGS` and `CMAKE_SHARED_LINKER_FLAGS` instead of
   `CMAKE_LD_FLAGS`.
*  Fix wrong --recursive for svn checkout.


## 0.21

*  Fix a bug when updating
*  When updating ignore symlinked repositories and do not update embedded
   repositories of said symlinks.
*  Fixed option handling, so now -y -v and -v -y are possible. It used to be
   that the order was -y -v.
*  Embeded repository settings do not get inherited, from other repos, which is
   just confusing.
*  Make the zombiefication code a bit more clever, when expected repos aren't
   there (yet).


## 0.20

*  Replace `CLONES_FETCH_SUBDIR` with `REPOS_DIR`.
*  mulle-bootstrap now uses the zombie repository detection to actually bury
   unused repositories. Check out "tests/refresh/refresh.sh" how this
   actually works. The upshot is, all changes in the repositories settings
   are now reflected on refresh.
*  Fix a bug in `combined_escaped_search_path`, which produced ugly and
   wrong search paths (that didn't matter).
*  Pass `DEPENDENCIES_DIR` via command line, which fixes some subtle problems
   with missing libraries, due to -force_load and friends.
*  Started mulle-bootstrap project. The general idea is to do also manage
   the project that contains the .bootstrap folder (at least a little bit). So
   `mulle-bootstrap clone` is now `mulle-bootstrap project clone
*  Better deep fetch and refresh avoids redoing repositories (could be
   better though still)
*  Don't append to log files, overwrite them.
*  script build shows better info on failure
*  Fix recursive repository agglomeration to not output duplicate lines
*  Grep those lines with an exact line match


## 0.19

*  Forgot a -f on a ln -s , which could result in an irritating output.
*  Now also refresh before fetching. mulle-bootstrap will now be able to
   pick up changes in recursive repositories. And fetch additional repos as
   needed, so you don't need to clean dist.
*  Produce more helpful output if cmake is missing.
*  Experimental support for "mulle-bootstrap clone", which will clone and build
   a remote repository.
*  Nicer markup for RELEASENOTES.md

## 0.18

*  Refixed: Fix old favorite bug build_ignore became a directory bug) again ...
*  Added refresh, which will be called before build and update automatically
   to rebuild .bootstrap.auto.

## 0.17

*  Fixed the broken inheritance. The "Always redo bootstrap.auto folder
   on fetch" fix in 0.15, was in the wrong position. So 0.15 and 0.16 are
   totally broken releases. Sorry.

## 0.16

*  Fixed misnamed exekutor.
*  Fix old favorite bug build_ignore became a directory bug) again ...

## 0.15

*  `tag` checks in all repositories, that a tag does not exist.
*  Remove some fluff from regular output.
*  Fix a bug involving settings copy  (build_ignore became a directory bug)
*  Executed commands are now prefixed with ==> for better readability.
*  Always redo bootstrap.auto folder on fetch, which means that you don't need
   to clean dist anymore after editing .bootstrap files.
*  Forgot to write-protect dependencies, when only partial builds were done.

## 0.14

*  Fix various uglies.
*  Make white terminals more happening with color choices.
*  -v circumvents building into a logfile, which is sometimes more convenient.

## 0.13

*  Fix colorization by using printf, instead of echo.

## 0.12

*  Run post-install.sh also on embedded repositories. Sometimes useful, when
   you need ./configure to produce some headers.
*  Add parameters to "Executing script" line.
*  Add "checkout" git flags, to fine tune the clone. But use --recursive
   per default.

## 0.11

*  Fixes another stale headers problem. Project is creeping towards a 1.0.

## 0.10

*  Fetch settings can be platform specific by using the `uname` as a file
   extension. e.g. repositories.Darwin. Other settings may follow, if the need
   arises. So far it hasn't.
*  Added `embedded_repositories` for those special moments, where you don't want
   to link another project, but just steal a few files. These gits are installed
   in your projects root and they are not built. You can not symlink them into
   your project, just clone them.
*  Because I needed ancient and dying svn for MulleScion,  you can now remap
   from the default git to svn, by creating a file `<reponame>.scm`. That contains
  the string "svn" then.
*  *** Renamed "gits" to "repositories" ***
*  Use mulle-bootstrap convert-pre.0.10 ~/src to convert all .bootstrap folders
  that `find` can find.
*  Do `mulle-bootstrap -n -v convert-pre-0.10 ${HOME}` to check what it's doing.
*  Install dummy dirs for xcodebuild too, to avoid boring compiler warnings.
*  Always overwrite headers, otherwise old and stale headers make life
   unnecessarily more complicated.

### 0.9.8

*  Brings more Linux fixes

### 0.9.7

*  Allow mulle-bootstrap version to work everywhere.

### 0.9.6

*  Figured out that some terminal windows have a white background (duh).
*  Fixed shifts for Ubuntu's hated dash.
*  Fixed some other Linux problems.

### 0.9.5

*  Messed up the tagging somewhat... 0.9.1 and 0.9.2 were the same and
*  0.9.3 doesn't even exist. So now 0.9.5 is the one.

*  Don't trace environment reads of `MULLE_BOOTSTRAP_ANSWER` and
*  `MULLE_BOOTSTRAP_VERBOSE`.
*  Fix xcodebuild log filename generation
*  Fix dry run some more.
*  Less output during dispensal, when not using -v.
*  Reduce usage output to 25 lines.

### 0.9.1

*  Fix cmake and configure build.

## 0.9

*  Specifying repos with `mulle-bootstrap build <repos>` was broken.
*  Added -y option, so everything is answered YES. I use this all the time.
*  Log xcodebuild command line into logfile.
*  Fix useless errors during dry run.
*  ** Changed the way custom "build.sh" scripts are executed. **
*  You can give a xcodeproj to mulle-bootstrap xcode directly, nice for
   sharing  dependencies with many subprojects.
*  Fixes the collection and dispensal of built frameworks.
*  Added logging to various 'cd' commands.
*  Collect and dispense symbolic links for directories too (not just for files)
*  Beautified output a little bit.
*  Respect the terse flag (-s) during mulle-bootstrap xcode add.
*  Add VENDOR_PREFIX to mulle-bootstrap-tag as third parameter.


### 0.8.1

*  And the fix, just minutes after the "release". warn scripts didn't
   find a function, and now I have cleaned this up properly, I think.
*  No more duplicate functions.

## 0.8

*  Added dist shortcut, because I always like to type "dist-clean".
*  Allow upper-case user input for yes/no questions.
*  Write protect dependencies folder, because I have a tendency to edit
   the headers.
*  Automatically append boring directories to .gitignore after fetch.
*  Inverted script default answer, because it pains me. Also it's not
   useful when using -a to just "breeze" through.
*  Redirect build logs to "build/.repos/.logs", because especially
   xcodebuild is just too verbose.

### 0.7.1

*  Fixed an internal error, when using mulle-bootstrap update.

## 0.7

*  Added version command

##  0.6

*  Improve scripts handling and add a some new phases to
   the proceedings. Actually the whole script stuff didn't work before...
*  Scripts in general aren't documented yet, because it's still very much
   in fluctuation.

*  More output during setting inheritance. Fix proper inheritance of
*  build_order and build_ignore.

*  Lots of en-passant bug fixes. Should be in general better than 0.5

*  Add -V option.

*  Added new did-install script phase. Depending on actual usage, I'll
   probably ditch some of the other phases again. This is all in flux.
