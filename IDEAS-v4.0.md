# mulle-bashlib-[version]

have versionized functions in `share/mulle-bashlib-3/` or so

mulle-bootstrap-array.sh
mulle-bootstrap-logging.sh
mulle-bootstrap-functions.sh
mulle-bootstrap-snip.sh
mulle-local-environment.sh  # teilweise
mulle-bootstrap-core-options.sh

## mulle-fetch

Get as a URL, branch, version. Fetches it and unpacks it. Possibly
caches it Nothing more,

## mulle-make

Gets a file or folder <makeinfo>, which contains all the CC, CMAKEFLAGS etc.
builds it using various tools. Nothing else.


## mulle-config

Keep configuration settings on a per project basis separate from
mulle-bootstrap. These are NOT buildinfos.


## mulle-makeinfo

Acquire makeinfos from WWW. Merge makeinfos together. Do the platform dependent
merge stuff. This is what mulle-bootstrap auto used to do.


## mulle-bootstrap

Uses mulle-make and mulle-fetch but not mulle-build. Does .bootstrap.auto
and all this stuff.


## mulle-build

Use mulle-make to build current directory. Does systeminstall and the other
stuff. May use mulle-bootstrap. Could be part of mulle-sde then...


## mulle-sde





