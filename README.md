# mulle-bootstrap, yet another dependency manager for developers

* checkout [git]](//enux.pl/article/en/2014-01-21/why-git-sucks) repositories
(called here the "dependents"). In times of need, it can also checkout [svn](//andreasjacobsen.com/2008/10/26/subversion-sucks-get-over-it/).
* can deal with [cmake](//blog.cppcms.com/post/54),
[xcodebuild](//devcodehack.com/xcode-sucks-and-heres-why/) and
[configure](//quetzalcoatal.blogspot.de/2011/06/why-autoconf-sucks.html)
projects
* instead of installing headers and libraries to `/usr/local`, mulle-bootstrap
installs to `./dependencies`
* can tag your repository and all dependents. dependents get a vendor tag
* installs brew taps and formulae
* installs gems and pips
* compiles dependents using the output of previous dependents
* written in portable shell script, runs also on Linux


## How to install (OS X)

```console
brew tap mulle-kybernetik/software
brew install mulle-bootstrap
```

> If that doesn't work for some reason, try to
> `brew untap mulle-kybernetik/software` and then retry.


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

**mulle-bootstrap** will check them out into a common directory `.repos`. If
there is a local clone of the repository **MulleScion** in the parent directory
of the project, then mulle-bootstrap can clone (or even symlink) from there,
if you want.

After cloning **mulle-bootstrap** does a simple security check with respect to
`.bootstrap` shell scripts and Xcode script phases. Finally it looks for a
`.bootstrap` folder in the freshly checked out repositories! They might have
dependencies too, if they do, those dependencies are added to the source
repositories dependencies.

Everything you need should be present at this time. so **mulle-bootstrap** will
now build a **Debug** and a **Release** version for each library, and place
the headers and the produced libraries into  the "./dependencies" folder.

Your Xcode project can be optionally massaged by
**mulle-bootstrap xcode add** to have the "./dependencies" folder in its
search paths.


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
be installed. These will be installed into `/usr/local` as usual though.

```console
zlib
openssl
```


#### mulle-bootstrap setup-xcode

Prepares a Xcode project to use the libraries that are compiled into the
`./dependencies` folder. You still need to add the libraries to your targets
though.


#### mulle-bootstrap tag

Tag your project and all fetched repositories, with a tag.

