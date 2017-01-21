#! /bin/sh


for i in *.dot
do
  svg="`basename "$i" .dot`.svg"
  echo "$i" >&2
  dot -Tsvg "$i" > "$svg"
done
