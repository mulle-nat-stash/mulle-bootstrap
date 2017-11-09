Q: Your tool is running downloaded shell scripts ? That is not very secure is it ?
A: It's a developer tool, that should be pretty normal.

Q: Ha! I never run foreign scripts without checking them first.
A: I have a hard time believing this. Do you always check out the configure script, Xcode build phases, Makefile, CMakeLists.txt before compiling ?

Q: Well, yes I do.
A: That's very conscientious and mulle-bootstrap is here to help. When you clone a repository and it contains shellscripts, mulle-bootstrap will alert you to fact (doesn't work for Makefiles and autoconf yet though.)

Q: Yeah and then you run it with `mulle-bootstrap -y' all the time, and the checks are automatically answered.
A: Well at least you see some warnings. If you split your fetch and build phases it's safe. At least you have options here.

Q: Or you might miss them.
A: OK how about this. The script facility for downloaded repositories can be turned off by default. `mulle-bootstrap config copy_inherited_scripts NO`. There aren't to many libraries that need scripts tweaks anyway.

Q: Can this be the default ?
A: No.


***

Q: I made some changes to a third party library and added a .bootstrap folder. They won't take my pull request though. Do I have to live with a thousand forks ?
A: There is actually another facility in mulle-bootstrap to share build folders. If you have folder with ".build" folder and 
point the configuration variable `shared_buildinfo_path`to it, then build informations will be picked up this from this folder.

Q: This is actually quite a bit like brew with formula repositories ?
A: Coming to think of it, yes it is. You can make it a git repository with submodules. Every submodule is a tap. It should work out of the box.

Q: Wouldn't it then make sense to turn off `copy_inherited_scripts` if you have "formulas" ?
A: Maybe so, maybe not so

