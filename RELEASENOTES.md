0.12
===
   Run post-install.sh also on embedded repositories. Sometimes useful, when
   you need ./configure to produce some headers.
   Add parameters to "Executing script" line.
   Add "checkout" git flags, to fine tune the clone. But use --recursive
   per default.

0.11
===
   Fixes another stale headers problem. Project is creeping towards a 1.0.


0.10
===
   Fetch settings can be platform specific by using the `uname` as a file
   extension. e.g. repositories.Darwin. Other settings may follow, if the need arises.
   So far it hasn't.

   Added "embedded_repositories" for those special moments, where you don't want
   to link another project, but just steal a few files. These gits are installed
   in your projects root and they are not built. You can not symlink them into
   your project, just clone them.

   Because I needed ancient and dying svn for MulleScion,  you can now remap
   from the default git to svn, by creating a file <reponame>.scm. That contains
   the string "svn" then.

   *** Renamed "gits" to "repositories" ***

   Use mulle-bootstrap convert-pre.0.10 ~/src to convert all .bootstrap folders
   that `find` can find.

   Do `mulle-bootstrap -n -v convert-pre-0.10 ${HOME}` to check what it's doing.

   Install dummy dirs for xcodebuild too, to avoid boring compiler warnings.

   Always overwrite headers, otherwise old and stale headers make life
   unnecessarily more complicated.

0.9.8
===
   Brings more Linux fixes

0.9.7
===
   Allow mulle-bootstrap version to work everywhere.

0.9.6
===
   Figured out that some terminal windows have a white background (duh).
   Fixed shifts for Ubuntu's hated dash.
   Fixed some other Linux problems.

0.9.5
===
   Messed up the tagging somewhat... 0.9.1 and 0.9.2 were the same and
   0.9.3 doesn't even exist. So now 0.9.5 is the one.

   Don't trace environment reads of MULLE_BOOTSTRAP_ANSWER and
   MULLE_BOOTSTRAP_VERBOSE.
   Fix xcodebuild log filename generation
   Fix dry run some more.
   Less output during dispensal, when not using -v.
   Reduce usage output to 25 lines.

0.9.1
===
   Fix cmake and configure build.

0.9
===
   Specifying repos with mulle-bootstrap build <repos> was broken.
   Added -y option, so everything is answered YES. I use this all the time.
   Log xcodebuild command line into logfile.
   Fix useless errors during dry run.
   ** Changed the way custom "build.sh" scripts are executed. **
   You can give a xcodeproj to mulle-bootstrap xcode directly, nice for
   sharing  dependencies with many subprojects.
   Fixes the collection and dispensal of built frameworks.
   Added logging to various 'cd' commands.
   Collect and dispense symbolic links for directories too (not just for files)
   Beautified output a little bit.
   Respect the terse flag (-s) during mulle-bootstrap xcode add.
   Add VENDOR_PREFIX to mulle-bootstrap-tag as third parameter.


0.8.1
===
   And the fix, just minutes after the "release". warn scripts didn't
   find a function, and now I have cleaned this up properly, I think.
   No more duplicate functions.

0.8
===
   Added dist shortcut, because I always like to type "dist-clean".
   Allow upper-case user input for yes/no questions.
   Write protect dependencies folder, because I have a tendency to edit
   the headers.
   Automatically append boring directories to .gitignore after fetch.
   Inverted script default answer, because it pains me. Also it's not
   useful when using -a to just "breeze" through.
   Redirect build logs to "build/.repos/.logs", because especially
   xcodebuild is just too verbose.

0.7.1
===
   Fixed an internal error, when using mulle-bootstrap update.

0.7
===
   Added version command

0.6
===
   Improve scripts handling and add a some new phases to
   the proceedings. Actually the whole script stuff didn't work before...
   Scripts in general aren't documented yet, because it's still very much
   in fluctuation.

   More output during setting inheritance. Fix proper inheritance of
   build_order and build_ignore.

   Lots of en-passant bug fixes. Should be in general better than 0.5

   Add -V option.

   Added new did-install script phase. Depending on actual usage, I'll
   probably ditch some of the other phases again. This is all in flux.