> Work in progress

## Commands for a project user

#### mulle-bootstrap

Download a project which is mulle-bootstrap enabled. Execute mulle-bootstrap
in it and you are all set:

```console
mulle-bootstrap
mulle-bootstrap shell
```

`mulle-bootstrap` is the shortened command of `mulle-bootstrap bootstrap`, which
in turn executes

1. `mulle-bootstrap fetch` to download all required dependencies.
2. `mulle-bootstrap build` to install those dependencies into `./dependencies`.


#### mulle-bootstrap upgrade

Upgrade all dependencies. You need to build afterwards again.


#### mulle-bootstrap shell

Start a shell with the environment set up, asto execute binaries from
`dependencies/bin`.


#### mulle-bootstrap clean dist

If mulle-bootstrap painted itself in the corner and produces errors, you can't
fix doing `mulle-bootstrap clean dist ; mulle-bootstrap` more often than not
gets you back on track.


## Commands for a project maintainer

#### mulle-bootstrap init

This is the first action. It sets up a `.bootstrap` folder in your project
directory root (e.g. alongside .git). At this point you should edit
`.bootstrap/repositories` to add git projects dependencies.

For each repository add a line like

`./bootstrap/repositories`:

```console
git@github.com:mulle-nat/MulleScion.git
```

In the file `.bootstrap/brews` you can specify homebrew projects that need to
be installed. These will be installed into `./addictions`.

`./bootstrap/brews`:

```console
zlib
openssl
```

#### mulle-bootstrap tag

Tag all fetched repositories.

