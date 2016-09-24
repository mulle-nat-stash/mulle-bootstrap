2.1
===

This version has some additions, that enable a more flexible use of
embedded repositories to "compose" source trees. It also now contains
better fecth and build code, so that dependencies, that are installed in
/usr/local already need not be fetched again. This can be helpful, when used
to build brew packages (for example).


**The changes should be transparent, but to be safe `mulle-bootstrap dist clean`
your projects**

* fixed a problem in the parsing of the repositories file
* embedded repositories can now be placed at an arbitrary position within your
project tree
* changes in deeply embedded repositories are now better tracked
* fixed some as of yet unknown bugs, by improving some path functions
* new -c switch to enable checking /usr/local/include for dependency libraries
conveniently from the command line. Fix build to add /usr/local/include to
build, if check_usr_local_include is YES.
* allow build and fetch options to be passed to `bootstrap`


2.0.1
===

Fixes two bugs

* fix problem in refresh using '==' instead of '='
* fix cut not using -s for extra parameters


2.0
===

### YOUR OLD STUFF MAY NOT RUN ANYMORE

Do a `mulle-bootstrap dist clean`.


### YOUR OLD SETTINGS MAY NOT WORK ANYMORE!

Move all repo specific setting directories from

`.bootstrap/settings/<reponame> `

to

`.bootstrap/<reponame>`

### YOUR OLD SCRIPTS MAY NOT WORK ANYMORE!

* Fetch script names have changed. *-install.sh is now *-fetch.sh.


## Changes

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


1.1
===

* Fix tar install, which was broken
* Fix some wordings
* You can now put configuration setting like variables into the URL. Like so:
   https://${host:-www.mulle-kybernetik.com}:foo.git. Define the host like
   a regular fetch setting. `echo "x.y.com" > .bootstrap/host`
* Fix help screen for refresh and update
* Don't complain if there are no dependencies generated


1.0
===

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


0.26
===

* Check library scripts version vs. executable version (paranoia)
* Skip Dirty Harry with -f flag.
* improve FAQ a little
* Reverse oder of repositories when updating, because this catches deep
  renames. Update now also fetches repositories, if they aren't there
  yet.
* Make the Dirty Harry check less foolproof, but also less annoying.


0.25
===

*  Remove python dependency
*  **bootstrap: refresh between fetch and build**


0.24
===

*  Fix releasenotes underscores
*  Fix xcodebuild path


0.23
===
*  Added -k options to build, to control cleaning before build.
   You can now specify the default configurations to build with -c.
   e.g. `mulle-bootstrap -c "Debug"
*  Improved library and frameworks searchpath generation.
*  You can pass build a "-j <cores>" flag, for cmake/make to parallelize
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


0.22
===
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

0.21
===

*  Fix a bug when updating
*  When updating ignore symlinked repositories and do not update embedded
   repositories of said symlinks.
*  Fixed option handling, so now -y -v and -v -y are possible. It used to be
   that the order was -y -v.
*  Embeded repository settings do not get inherited, from other repos, which is
   just confusing.
*  Make the zombiefication code a bit more clever, when expected repos aren't
   there (yet).


0.20
===

*  Replace `CLONES_FETCH_SUBDIR` with `CLONESFETCH_SUBDIR`.
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


0.19
===
*  Forgot a -f on a ln -s , which could result in an irritating output.
*  Now also refresh before fetching. mulle-bootstrap will now be able to
   pick up changes in recursive repositories. And fetch additional repos as
   needed, so you don't need to clean dist.
*  Produce more helpful output if cmake is missing.
*  Experimental support for "mulle-bootstrap clone", which will clone and build
   a remote repository.
*  Nicer markup for RELEASENOTES.md

0.18
===
*  Refixed: Fix old favorite bug build_ignore became a directory bug) again ...
*  Added refresh, which will be called before build and update automatically
   to rebuild .bootstrap.auto.

0.17
===
*  Fixed the broken inheritance. The "Always redo bootstrap.auto folder
   on fetch" fix in 0.15, was in the wrong position. So 0.15 and 0.16 are
   totally broken releases. Sorry.

0.16
===
*  Fixed misnamed exekutor.
*  Fix old favorite bug build_ignore became a directory bug) again ...

0.15
===
*  `tag` checks in all repositories, that a tag does not exist.
*  Remove some fluff from regular output.
*  Fix a bug involving settings copy  (build_ignore became a directory bug)
*  Executed commands are now prefixed with ==> for better readability.
*  Always redo bootstrap.auto folder on fetch, which means that you don't need
   to clean dist anymore after editing .bootstrap files.
*  Forgot to write-protect dependencies, when only partial builds were done.

0.14
===
*  Fix various uglies.
*  Make white terminals more happening with color choices.
*  -v circumvents building into a logfile, which is sometimes more convenient.

0.13
===
*  Fix colorization by using printf, instead of echo.

0.12
===
*  Run post-install.sh also on embedded repositories. Sometimes useful, when
   you need ./configure to produce some headers.
*  Add parameters to "Executing script" line.
*  Add "checkout" git flags, to fine tune the clone. But use --recursive
   per default.

0.11
===
*  Fixes another stale headers problem. Project is creeping towards a 1.0.

0.10
===
*  Fetch settings can be platform specific by using the `uname` as a file
   extension. e.g. repositories.Darwin. Other settings may follow, if the need
   arises. So far it hasn't.
*  Added `embedded_repositories`` for those special moments, where you don't want
   to link another project, but just steal a few files. These gits are installed
   in your projects root and they are not built. You can not symlink them into
   your project, just clone them.
*  Because I needed ancient and dying svn for MulleScion,  you can now remap
   from the default git to svn, by creating a file <reponame>.scm. That contains
  the string "svn" then.
*  *** Renamed "gits" to "repositories" ***
*  Use mulle-bootstrap convert-pre.0.10 ~/src to convert all .bootstrap folders
  that `find` can find.
*  Do `mulle-bootstrap -n -v convert-pre-0.10 ${HOME}` to check what it's doing.
*  Install dummy dirs for xcodebuild too, to avoid boring compiler warnings.
*  Always overwrite headers, otherwise old and stale headers make life
   unnecessarily more complicated.

0.9.8
===
*  Brings more Linux fixes

0.9.7
===
*  Allow mulle-bootstrap version to work everywhere.

0.9.6
===
*  Figured out that some terminal windows have a white background (duh).
*  Fixed shifts for Ubuntu's hated dash.
*  Fixed some other Linux problems.

0.9.5
===
*  Messed up the tagging somewhat... 0.9.1 and 0.9.2 were the same and
*  0.9.3 doesn't even exist. So now 0.9.5 is the one.

*  Don't trace environment reads of `MULLE_BOOTSTRAP_ANSWER` and
*  `MULLE_BOOTSTRAP_VERBOSE`.
*  Fix xcodebuild log filename generation
*  Fix dry run some more.
*  Less output during dispensal, when not using -v.
*  Reduce usage output to 25 lines.

0.9.1
===
*  Fix cmake and configure build.

0.9
===
*  Specifying repos with mulle-bootstrap build <repos> was broken.
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


0.8.1
===
*  And the fix, just minutes after the "release". warn scripts didn't
   find a function, and now I have cleaned this up properly, I think.
*  No more duplicate functions.

0.8
===
*  Added dist shortcut, because I always like to type "dist-clean".
*  Allow upper-case user input for yes/no questions.
*  Write protect dependencies folder, because I have a tendency to edit
   the headers.
*  Automatically append boring directories to .gitignore after fetch.
*  Inverted script default answer, because it pains me. Also it's not
   useful when using -a to just "breeze" through.
*  Redirect build logs to "build/.repos/.logs", because especially
   xcodebuild is just too verbose.

0.7.1
===
*  Fixed an internal error, when using mulle-bootstrap update.

0.7
===
*  Added version command

0.6
===
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