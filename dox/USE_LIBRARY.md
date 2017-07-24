# How to use the mulle-bootstrap bash function libraries in your code

```
main()
{
   local MULLE_FLAG_EXEKUTOR_DRY_RUN="NO"
   local MULLE_FLAG_LOG_DEBUG="NO"
   local MULLE_FLAG_LOG_EXEKUTOR="NO"
   local MULLE_FLAG_LOG_TERSE="NO"
   local MULLE_TRACE
   local MULLE_TRACE_POSTPONE="NO"

   while [ $# -ne 0 ]
   do
      if core_technical_flags "$1"
      then
         shift
         continue
      fi

      # your option handling
      case "$1" in
         -*)
            fail "unknown option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   core_setup_trace "${MULLE_TRACE}"

   #####
   ####
   ### your code follows here
   ##
   #
}


_init()
{
   libexecpath="`mulle-bootstrap library-path 2> /dev/null`"
   if [ -z "${libexecpath}" ]
   then
      echo "Fatal Error: Could not find mulle-bootstrap library for ${MULLE_EXECUTABLE}" >&2
      exit 1
   fi

   . ${libexecpath}/mulle-bootstrap-logging.sh
   . ${libexecpath}/mulle-bootstrap-functions.sh
   . ${libexecpath}/mulle-bootstrap-core-options.sh
}


MULLE_EXECUTABLE="`basename -- "$0"`"
MULLE_ARGUMENTS="$@"
MULLE_EXECUTABLE_FAIL_PREFIX="${MULLE_EXECUTABLE}"
MULLE_EXECUTABLE_PID="$$"

MULLE_EXECUTABLE_FUNCTIONS_MIN="3.9"
MULLE_EXECUTABLE_FUNCTIONS_MAX="4"


_init "$@"

main "$@"
```
