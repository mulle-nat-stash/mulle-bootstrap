> Work in progress

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

`./bootstrap/repositories`:

```console
git@github.com:mulle-nat/MulleScion.git
```

In the file `.bootstrap/brews` you can specify homebrew projects that need to
be installed. These will be installed into `addictions`.

`./bootstrap/brews`:

```console
zlib
openssl
```

#### mulle-bootstrap tag

Tag all fetched repositories.

