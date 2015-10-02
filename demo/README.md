# Demo

This demo shows an already created `.bootstrap` folder in action.
**mulle-bootstrap** clones and builds a xcodebuild based project, a cmake make
based project and a configure based project.

Just run mulle-bootstrap in here and examine the created output in the folder
`dependencies`:

```console
$ mulle-bootstrap
$ ls -R dependencies
```

### What is in .bootstrap ?

There is very little configuration needed to get this result. The
.bootstrap folder contains:

Folder                     | Files                 | Folders
---------------------------|-----------------------|---------------
.bootstrap						| gits                  | settings/
.bootstrap/settings			|                       | Finch/	zlib/
.bootstrap/settings/Finch	| xcode_public_headers  |
.bootstrap/settings/zlib	| dispense_headers_path |


`.bootstrap/gits` defines the repositories to fetch
```
# A configure project
git://git.savannah.gnu.org/readline.git
# A cmake project
https://github.com/madler/zlib
# An Xcode project
git@github.com:mulle-nat/Finch.git
```

`.bootstrap/settings/Finch/xcode_public_headers` contains a mapping for the
public header output of Finch, (which is currently broken in that repository).

```
/usr/local/include/Finch
```

Usually zlib places it's headers into "/usr/local/include", for demo purposes
we want it to be in "/usr/local/include/zlib". As this is not an Xcode project
we use an alternative method `.bootstrap/settings/zlib/dispense_headers_path`

```
/usr/local/include/zlib
```

Notice that the settings are specified on a per repository, which usually makes
the most sense.


Finally lets get rid of the download repositories and all build products with:

```console
$ mulle-bootstrap clean dist
```
