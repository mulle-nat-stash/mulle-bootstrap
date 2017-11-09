fgrep '="`' src/*.sh | sort | fgrep -v 'exit 1' | egrep -v '`assoc_array_|`array_|`dependency_add|`concat|`pwd|`escaped_|`basename|`dirname|`echo|`symlink|`_chosen_bootstrapdir|`stash_of_repository|`clone_of_repository|`sed|`absolutepath|`readlink' | egrep -v '_setting'

