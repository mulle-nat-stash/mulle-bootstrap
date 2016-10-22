#! /bin/sh

main()
{
   local i

   for i in *
   do
      if [ -x "$i/run-test.sh" ]
      then
         "./$i/run-test.sh" "$@" || exit 1
      fi
   done
}

main "$@"
