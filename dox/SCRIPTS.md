# Writing a build script for mulle-bootstrap


Assume you want to create a custom build script for a dependency "foo".
In the simplest case "foo" contains an \"install.sh\" script:


```
mkdir -p .bootstrap/foo.build/bin
cat <<EOF > .bootstrap/foo.build/bin/build.sh
#! /bin/sh

configuration="$1"  # usually either Release or Debug, default Release
stashdir="$2"       # same as ${PWD}
builddir="$3"       # a place to put intermediate files
dstdir="$4"         # where to install to (e.g. /usr/local)
name="$5"           # "foo"
sdk="$6"            # Usually "Default"


./install.sh "$3"
EOF
chmod 755 .bootstrap/foo.build/bin/build.sh
```


## Getting logging support from mulle-bootstrap

Spice up your script with mulle-bootstrap logging functionality:


```
. mulle-bootstrap-logging.sh

log_info "Info"
log_warning "Warning"
log_verbose "Verbose"
log_fluff "Fluff"
fail "Failed"
```
