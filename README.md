# mulle-bootstrap, cross platform dependency manager for Linux, OS X, FreeBSD

Everything `mulle-bootstrap` installs is relative to your project root.
Downloaded packages and binaries don't "pollute" your system.

* fetches [git](//enux.pl/article/en/2014-01-21/why-git-sucks) repositories
(called here the "dependents"). In times of need, it can also checkout [svn](//andreasjacobsen.com/2008/10/26/subversion-sucks-get-over-it/).
* builds [cmake](//blog.cppcms.com/post/54),
[xcodebuild](//devcodehack.com/xcode-sucks-and-heres-why/) and
[configure](//quetzalcoatal.blogspot.de/2011/06/why-autoconf-sucks.html)
projects
* compiles dependents using the output of previous dependents into a project
local "dependencies" folder
* installs [brew](//dzone.com/articles/why-osx-sucks-and-you-should) binaries and
libraries locally into an "addictions" folder
* written in portable shell script, runs on OS X, FreeBSD (without brew), Linux

## Tell me more

* [How to install](INSTALL.md)
* [What has changed ?](RELEASENOTES.md)

* [mulle-bootstrap: A dependency management tool](https://www.mulle-kybernetik.com/weblog/2015/mulle_bootstrap_work_in_progr.html)
* [mulle-bootstrap: Understanding mulle-bootstrap (I)](https://www.mulle-kybernetik.com/weblog/2016/mulle_bootstrap_how_it_works.html)
* [mulle-bootstrap: Understanding mulle-bootstrap (II), Recursion](https://www.mulle-kybernetik.com/weblog/2016/mulle_bootstrap_recursion.html)


## What mulle-bootstrap can do for you

So you need a bunch of first and third party repositories to build your own
project ? **mulle-bootstrap init** does the initial setup of the `.bootstrap`
folder. Lets put the git repository URLs in a file called `.bootstrap/repositories`.

```console
cat > .bootstrap/repositories
git@github.com:mulle-nat/MulleScion.git
git@github.com:mulle-nat/UISS.git
git@github.com:mulle-nat/Finch.git
```

**mulle-bootstrap** will check them out into a common directory `.repos`.

After cloning **mulle-bootstrap** does a simple security check of `.bootstrap`
shell scripts. Finally it looks for a `.bootstrap` folder in the freshly
checked out repositories! They might have dependencies too, if they do, those
dependencies are added and also fetched.

Everything should now be in place so **mulle-bootstrap** that can now build the
dependencies with **cmake**. It will place the headers and the produced libraries
into the `dependencies` folder.


## Commands for a project user

#### mulle-bootstrap

Download a project which is mulle-bootstrap enabled. Execute mulle-bootstrap
in it and you are all set:

```console
mulle-bootstrap
```
`mulle-bootstrap` is a the shortened command of `mulle-bootstrap bootstrap`, which
in turn executes:


#### mulle-bootstrap fetch

Downloads all required libraries into a `.repos` folder.


#### mulle-bootstrap build

Compiles the required libraries contained in the `.repos` folder into
`./dependencies`. It compiles each project once for Release and once for Debug
(and given a file `.bootstrap/sdks` multiplied by the number of sdks needed)




## Commands for a project maintainer

#### mulle-bootstrap init

This is the first action. It sets up a `.bootstrap` folder in your project
directory root (e.g. alongside .git). At this point you should edit
`.bootstrap/repositories` to add git projects dependencies.

For each repository add a line like

```console
git@github.com:mulle-nat/MulleScion.git
```

In the file `.bootstrap/brews` you can specify homebrew projects that need to
be installed. These will be installed into `addictions`.

```console
zlib
openssl
```


#### mulle-bootstrap tag

Tag all fetched repositories.

