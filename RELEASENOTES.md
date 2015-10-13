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