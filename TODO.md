* cmake use local mulle-configuration of subrepo. WRONG!
* Use different build dir than just build.
* Write "doctor" command to find common problems.
* XCodebuild somehow resolves the symbolic link, which makes it use the wrong
  dependency library. MUST use absolute paths.
