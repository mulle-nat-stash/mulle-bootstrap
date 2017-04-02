# mulle-brew, C/C++/Objective-C developer sandboxing with homebrew

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-bootstrap.svg)

[Homebrew](brew.sh) is the de facto standard package manager of OS X. Usually
it is used to install packages system-wide into '/usr/local/'. But you can
actually place homebrew anywhere. Then you can create your own playground
development environment of tools and libraries.

**mulle-brew** helps you set-up and share such playgrounds.

## Advantages

* Keep the runtime and your system clear off temporary downloads.
* Updating brew libraries for one project, doesn't neccessarily impact parallel projects
* An easy way to share the required build environments


## How does it work ?

In the simplest form, `mulle-brew` is just a simple loop over a
`.bootstrap/brews` file, that installs all the listed formulae. This list is
the playground specification, that can be easily shared.

Here is a sample `.bootstrap/brews` file that installs **autoconf** and
**libpng**:

```
mkdir .bootstrap 2> /dev/null
cat << EOF > .bootstrap/brews
autoconf
libpng
EOF
```

When you call `mulle-brew` this will setup a local brew installation in a folder
called `addictions`. The **autoconf** binaries will appear in `addictions/bin`
and the **libpng** library in `addictions/lib` and `addictions/include`.
`addictions` is your playground's '/usr/local' so to speak




## Various Playground configurations


### Pure playground, gcc/clang based

You install a complete set of custom tools and libraries. The easiest way then
is to pass `--sysroot` to your tool chain like f.e.

```
PATH=`mulle-brew paths -m path`
gcc --sysroot="`mulle-brew paths -m addictions`"
```

### Mixed playground, gcc/clang based

You use the Xcode supplied toolset, but you want the playground headers and
libraries to override the system files.

```
gcc `mulle-brew paths -m -q '' cflags`
```


### Sharing playgrounds with other projects

You might find that you have multiple projects with overlapping depencies on
brew formula and the duplication becomes tedious. You can create a "master"
playground in the common parent directory with:

```
mulle-bootstrap defer
```

And revert back to a private playground with

```
mulle-bootstrap emancipate
```

Here the use of `mulle-brew paths` comes in handy, as it adapts to the
new position of the `addictions` folder in the filesystem.


## Tips

### Keep a cache of homebrew locally

Cloning **brew** from GitHub can get tedious. You can use a local cache with:

```
mulle-brew config -g "clone_cache" "${HOME}/Library/Caches/mulle-brew"
```


## GitHub and Mulle kybernetiK

The development is done on [Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-bootstrap/master). Releases and bug-tracking are on [GitHub](https://github.com/mulle-nat/mulle-bootstrap).


