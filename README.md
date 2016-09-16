# mulle-bootstrap, cross platform dependency manager using bash and cmake

... for Linux, OS X, FreeBSD, Windows

... for C, C++, Objective-C

... certainly not a "minimal" or "lightweight" project with ca. 10000 lines of
  shell script code

## Why you may want it

* You program in C, C++ or in Objective-C, **mulle-bootstrap** is written for you
* If you need to link against a library, that clashes with an installed
library,  **mulle-bootstrap** could break this quandary
* If you feel that `apt-get install` pollutes your system with too many libraries,  **mulle-bootstrap** may be the solution
* If you don't like developing in virtual machines, **mulle-bootstrap** may
tickle your fancy
* If you like to decompose huge projects into reusable libraries,
**mulle-bootstrap** may enable you to do so
* If you do cross-platform development, **mulle-bootstrap** may be your best bet for a dependency manager


## Core principles

* Nothing gets installed outside of the project folder
* **mulle-bootstrap** manages your dependencies, it does not manage your
project
* It should be adaptable to a wide ranges of project styles. Almost anything
can be done with configuration settings or additional shell scripts.
* It should be scrutable. If things go wrong, it should be easy to figure
out what the problem is. It has extensive logging and tracing support built in.
* It should run everywhere. **mulle-bootstrap** is a collection of
shell scripts. If your system can run the bash, it can run **mulle-bootstrap**.


## What it does technically


* fetches [git](//enux.pl/article/en/2014-01-21/why-git-sucks) repositories.
In times of need, it can also checkout [svn](//andreasjacobsen.com/2008/10/26/subversion-sucks-get-over-it/).
* builds [cmake](//blog.cppcms.com/post/54),
[xcodebuild](//devcodehack.com/xcode-sucks-and-heres-why/) and
[configure](//quetzalcoatal.blogspot.de/2011/06/why-autoconf-sucks.html)
projects and installs their output into a "dependencies" folder.
* installs [brew](//dzone.com/articles/why-osx-sucks-and-you-should) binaries and
libraries into an "addictions" folder (on participating platforms)
* alerts to the presence of shell scripts in fetched dependencies


## A first use

So you need a bunch of third party projects to build your own
project ? No problem. Use **mulle-bootstrap init** to do the initial setup of
a `.bootstrap` folder in your project directory. Then put the git repository
URLs in a file called `./bootstrap/repositories`:

```
mkdir .bootstrap
echo "# a comment
https://github.com/madler/zlib.git
https://github.com/coapp-packages/expat.git" > .bootstrap/repositories
mulle-bootstrap
```

**mulle-bootstrap** will check them out into a common directory `.repos`.

After cloning **mulle-bootstrap** looks for a `.bootstrap` folder in the freshly
checked out repositories. They might have dependencies too, if they do, those
dependencies are added and also fetched.

Everything should now be in place so **mulle-bootstrap** that can now build the
dependencies with **cmake**. It will place the headers and the produced
libraries into the `dependencies/lib`  and `dependencies/include` folders.


## Tell me more

* [How to install](INSTALL.md)
* [What has changed ?](RELEASENOTES.md)

* [mulle-bootstrap: A dependency management tool](https://www.mulle-kybernetik.com/weblog/2015/mulle_bootstrap_work_in_progr.html)
* [mulle-bootstrap: Understanding mulle-bootstrap (I)](https://www.mulle-kybernetik.com/weblog/2016/mulle_bootstrap_how_it_works.html)
* [mulle-bootstrap: Understanding mulle-bootstrap (II), Recursion](https://www.mulle-kybernetik.com/weblog/2016/mulle_bootstrap_recursion.html)


## GitHub and Mulle kybernetiK

The development is done on [Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-bootstrap/master). Releases and bug-tracking are on [GitHub](https://github.com/mulle-nat/mulle-bootstrap).


