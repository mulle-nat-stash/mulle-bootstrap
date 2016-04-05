Use different build dir than just build.
Write "doctor" command to find common problems.
XCodebuild somehow resolves the symbolic link, which makes it use the wrong
dependency library. MUST use absolute paths.
Changes in .repositories should not need to make clean.