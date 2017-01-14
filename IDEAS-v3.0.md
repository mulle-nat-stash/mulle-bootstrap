---
layout: post
author: Nat!
title:
open_comments: true
date: 2017-01-13 12:07
---
# mulle-bootstrap 3.0

What I want is to share fetched repositories and builds, especially
dependencies and addictions with multiple repositories.

mulle-bootstrap 2.0 does this already, though it's not convenient.

### How does 2.0 do it ?

Just create a new .bootstrap in top level and build
constituents. The merge algorithm uniques fetches and builds.

### Why is it not convenient ?

1. repositories are hidden inside .repos
2. repositories have to be part of .bootstrap/repositories of master

### How it would be ideal for me

```console
$ mulle-bootstrap seize /Volumes/Source/srcM/slave
#
# link up a slave to a master, updating  .bootstrap.local/repositories
# bail if we are not a master. How do we know we are a master ? It has
# no .bootstrap just a .bootstrap.local
#
$ mulle-bootstrap fetch
# defer to master... master will fetch my embedded repositories and
# my dependencies and addictions
$ mulle-bootstrap status
This is a minion to master /Volumes/Source/srcM
Master needs to a rebuild
```

```
$ CFLAGS=`mulle-bootstrap config --cflags`
$ CXXLAGS=`mulle-bootstrap config --cxxflags`
$ LDFLAGS=`mulle-bootstrap config --ldflags`
```


## Problems

* Need an unseize command
* Need an info command to show if linked or not
* Rememeber the golden rule, nothing gets produced "outside" the project


## Thoughts

* We still need a .repos folder inside a local mulle-bootstrap for embedded
repositories. but it is managed by the master
* Call it .bootstrap.repos ? Nah.


## Solutions

### .bootstrap.local/minion

* minion defers to parent to build
* parent merges contents of minion (how is this different from .repos)
* parent detects presence of minion and adds it to .repos with a symlink. Then
marks it with .bootstrap.local minion


### .repos becomes .

* problems adding repositories to .gitignore
* problems rm -rf .repos


### .repos/<repos> get symlinked to .

* problems removing symlinks

