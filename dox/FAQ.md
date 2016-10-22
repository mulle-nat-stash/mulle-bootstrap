# FAQ

## Is mulle-bootstrap a package manager ?

No it's a dependency manager.


## Where is what ?

* `.bootstrap` is the bootstrap configuration of the repository.
* `.bootstrap.auto` is autogenerated by mulle-bootstrap, it contains
information recursively collected from dependent repostiories, that have their
own .bootstrap folder. Do not edit it, your changes will be lost.
* `.bootstrap.local` contains local settings you can use to override settings
in `.bootstrap` and `.bootstrap.auto`. You create it manually when the need
arises.
* `~/.mulle-bootstrap` contains some global customizations. It can be
autogenerated when using brew stuff.
* `build/.repos` contains intermediate files generated by the build, which can
be safely thrown away at any time.
* `dependencies` contains the produced headers, libraries and frameworks
* `addictions` contains **brew** installed headers, libraries and frameworks
* `/usr/local/libexec/mulle-bootstrap` contains scripts for mulle-bootstrap


### Where is what in .bootstrap ?

Check SETTTINGS.md

### I need debug variants of the dependencies

For a one shot:

```
mulle-bootstrap clean output
mulle-bootstrap build -c "Debug"
```

Or when you want to have both:

```
mkdir -p .bootstrap.local/settings 2> /dev/null
echo "Debug
Release" > .bootstrap.local/settings/configurations
mulle-bootstrap clean output
mulle-bootstrap build
```


### How are multiple value settings separated ?

Separation is done by newline, not by space.

```console
mkdir -p  ".bootstrap/settings" 2> /dev/null
echo "Debug Release" > .bootstrap/settings/configurations # WRONG
echo "Debug
Release" > .bootstrap/settings/configurations # RIGHT
```


### Can I change the build folder from `build/.repos`to something else  ?

Better not. You can set it with "build_foldername".
But beware:

><font color=red>mulle-bootstrap assumes that it can **rm -rf** the folder,
so choosing `~` or `/tmp` as a build folder is not a great idea.</font>

```console
echo "you_have/been_warned" > ~/.bootstrap.local/build_foldername
```


### I changed something in .bootstrap but nothing happens ?

This shouldn't really happen. Say `mulle-bootstrap clean dist` and try again.


### What should be put into git ?

Add the `.bootstrap` folder to git:

```
git add .bootstrap
```

Ignore all the other mulle-bootstrap related directories. This is done for
you automatically during fetching.

```
cat <<EOF >> .gitignore
.bootstrap.local/
.bootstrap.auto/
.repos/
dependencies/
build/.repos/
```


### mulle-bootstrap does not do what I want  ?

Check out the SETTINGS.md file for help about tweaking mulle-bootstrap.

As an example, here is how to specify what target to build for Xcode.

Put the target name into `.bootstrap/{reponame}/targets`

```console
mkdir -p  ".bootstrap/Finch" 2> /dev/null
echo "Finch Demo" > .bootstrap/Finch/targets
```

If it's not working as expected, try to use some of the debug facilities,
that are options to **mulle-bootstrap**

Option          | Description
----------------|-------------------------------
-v              | Make output more entertaining
-vv             | Explain what mulle-bootstrap is doing
-vvv            | Trace command execution too
-t              | Trace shell script execution
-ts             | Trace setting value resolution
-tm             | Trace repositories content merging (dependency resolution)
-te             | Trace execution of shell commands
-V              | Tell make to build verbosely



### I want to only build with cmake just once

Any setting can be overriden by the environment:

```
MULLE_BOOTSTRAP_BUILD_PREFERENCES=cmake mulle-bootstrap build
```

### My embedded_repoisitories .bootstrap folder is ignored ?

Yes, this is by design. Embedded repositories are not built and therefore
(should) have no dependencies.


### Is the order of the repositories important ?

Usually not. But in case you have implicit dependencies the order of the
repositories may be important.

Say you are dependent on a and b, and a is dependent on b (but a is not a
.bootstrap project), then keep a ahead of b in the repositories file.


### Is it a problem if a repository appears twice ?

No, if the repository entries match. If they doen't match, it can be a problem.




## Xcode problems


### I have a depencency on another library in the same project.

But the headers of the dependency library are in `dependencies/usr/local/include`.
What now ?

**mulle-bootstrap*+ can't manage xcodebuild dependencies, so you have to help
it. Specify the targets you want to build or set the proper dependencies in the
xcode project.


### My Xcode project's headers do not show up ?

Check that your Xcode project has a **Header Phase** and that the header files
are in "public".



### I specified SKIP_INSTALL=YES in my Xcode project, but stuff gets installed nonetheless ?

Because this SKIP_INSTALL=YES is the default unfortunately and lots of project
maintainers forget to turn it off, **mulle-bootstrap** sets this flag to NO at
compile time. If you know that SKIP_INSTALL is correctly set, set
"xcode_proper_skip_install" to "YES".

```console
mkdir -p  ".bootstrap/{reponame}" 2> /dev/null
echo "YES" > .bootstrap/{reponame}/proper_skip_install
```


### I build an aggregate target and the headers end up in the wrong place

mulle_bootstrap has problems with aggregate targets. Built the subtargets
individually by enumerating them in ".bootstrap/{reponame}/targets"


```console
mkdir -p  ".bootstrap/MulleScion" 2> /dev/null
echo "MulleScion (iOS Library)
MulleScion (iOS Framework)" > .bootstrap/MulleScion/targets"
```

