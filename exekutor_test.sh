#! /bin/sh


emit()
{
   while [ $# -gt 0 ]
   do
      echo "$1"
      shift
   done
}


exekutor()
{
   local arrow

   arrow="==>"
   if [ "$$" -ne "${MULLE_EXECUTABLE_PID}" ]
   then
      arrow="=[$$]=>"
   fi

   echo "${arrow}" "$@" >&2
   "$@"
}

exekutor emit -G "Unix Makefiles" hein
