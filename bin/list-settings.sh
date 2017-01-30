#! /bin/sh
#
#
if [ $# -lt 1 ]
then
  echo "specify some files" >&2
  exit 1
fi

egrep -h '[^_]read_[a-z0-9_]*setting \"' "$@" | \
   sed 's/^[^`]*`\(.*\)$/\1/' | \
   sed 's/^[ \t]*\(.*\)/\1/'  | \
   sort | \
   sort -u