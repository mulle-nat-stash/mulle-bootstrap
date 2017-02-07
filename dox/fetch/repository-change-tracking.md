# Changes in repositories

What can mulle-bootstrap deduce from changes in `repositories` ?


## Possible actions

Change     | Action               | Description
-----------|----------------------|----------------------------------
`url`      | **set-remote**       | If `name` stays the same, `git remote set url`
`name`     | **fetch**            | new name repository
`scm`      | **remove**,**fetch** | the repository is invalid and needs to be replaced
`stashdir` | **move**             | the repository
`branch`   | **fetch**            | with new branch and check out (with tag)
`tag`      | **checkout**         | check out with tag

>
> The old clone line is remembered in the .bootstrap.repos. It is indexed
> by name. The name is derived from the URL. If the name changes, we can't
> match up with old information. The old repository will become a
> zombie.
>

