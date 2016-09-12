#! /bin/sh
#
#   Copyright (c) 2016 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
VERSION=0.0

PATH="/usr/local/libexec/mulle-bootstrap:/usr/bin:$PATH"
export PATH

INDENT="${INDENT:-"   "}"
DATA="${DATA:-"DATA"}"


usage()
{
   echo "failed" >&2
   exit 1
}


#
# search path delimited by LF
#
find_library_in_directories()
{
   local filename
   local directories

   filename="$1"
   directories="$2"

   local old

   old="${IFS}"
   IFS="
"
   local directory
   local path

   for directory in ${directories}
   do
      path="${directory}/${filename}"

      if [ -f "${path}" ]
      then
         echo "${path}"
         break
      fi
   done

   IFS="${old}"
}


find_library()
{
   local filename

   filename="$1"

   if [ -f "${filename}" ]
   then
      echo "${filename}"
      return
   fi

   case "${filename}" in
      ?:/*)
         filename="`echo "/${filename}" | sed 's|\\|/|g' | sed 's|:|/|'`"
         find_library "${filename}"
      ;;

      ~*|.*|/*|"")
         :
      ;;

      *)
         find_library_in_directories "${filename}" "${SEARCH_PATH}"
      ;;
   esac
}


dump_function_exports()
{
   local filename

   filename="$1"
   dumpbin.exe -symbols "${filename}" | egrep '^[^|]* \(\) [^|]*\|' | fgrep ' External ' | fgrep -v ' UNDEF ' | sed 's/^[^|]*| *\([^ (]*\).*$/\1/' | sed 's/^_//' | sort
}


dump_data_exports()
{
   local filename

   filename="$1"
   dumpbin.exe -symbols "${filename}" | egrep -v '^[^|]* \(\) [^|]*\|' | fgrep ' External ' | fgrep -v ' UNDEF ' | sed "s/^[^|]*| *\\([^ (]*\\).*\$/\\1   ${DATA}/" | sed 's/^_//' | sort
}


dump_exports()
{
   local filename

   filename="$1"

   local functions
   local data

   functions="`dump_function_exports "${filename}"`"
   data="`dump_data_exports "${filename}"`"

   cat <<EOF
${functions}

${data}
EOF
}


dump_library()
{
   local prefixes
   local filename

   prefixes="$1"
   shift

   libraryname="$1"
   shift

   [ -z "${libraryname}" ] && echo "empty libraryname" >&2 && exit 1

   local filename

   filename="`find_library ${libraryname}`"
   if [ -z "${filename}" ]
   then
      filename="`find_library ${libraryname}.lib`"
      if [ -z "${filename}" ]
      then
         echo "${libraryname} ($PWD) not found" >&2 && exit 1
      fi
   fi

   if [ ! -z "${prefixes}" ]
   then
      if [ ! -z "${VERBOSE}" ]
      then
         echo "Dumping `basename -- ${filename}` symbols with prefixes ${prefixes}" >&2
      fi
      dump_exports "${filename}" | egrep "${prefixes}"
   else
      if [ ! -z "${VERBOSE}" ]
      then
         echo "Dumping all `basename -- ${filename}` symbols" >&2
      fi
      dump_exports "${filename}"
   fi
}


dump_libraries()
{
   local name
   local prefixes

   name="$1"
   shift
   prefixes="$1"
   shift

   if [ $# -eq 0 ]
   then
      echo "no files to dump" >&2
      exit 1
   fi

   if [ -z "${SUPPRESS_HEADER}" ]
   then
      if [ ! -z "${name}" ]
      then
         echo "LIBRARY ${name}"
      fi
      echo "EXPORTS"
   fi

   while [ $# -ne 0 ]
   do
      dump_library "${prefixes}" "$1" | sed "s/^\\(.*\\)\$/${INDENT}\\1/"
      shift
   done
}


main()
{
   local outfile
   local prefixes
   local cpp_stringprefix
   local name

   name=
   prefixes=
   outfile=
   SEARCH_PATH="."
   cpp_stringprefix=

   while [ $# -ne 0 ]
   do
      case "$1" in
         -o|--output)
            shift
            outfile="$1"
         ;;

         -d|--directory)
            shift
            SEARCH_PATH="$1
${SEARCH_PATH}"
         ;;

         --cpp-strings)
            cpp_stringprefix='^\?\?_C|'
         ;;

         --suppress_header)
            SUPPRESS_HEADER=YES
         ;;

         -n|--name)
            shift
            name="$1"
         ;;

         -p|--prefix)
            shift
            if [ -z "${prefixes}" ]
            then
               prefixes="${cpp_stringprefix}^_*$1"
            else
               prefixes="${prefixes}|^_*$1"
            fi
         ;;

         -sp|--strict-prefix)
            shift
            if [ -z "${prefixes}" ]
            then
               prefixes="^$1"
            else
               prefixes="${prefixes}|^$1"
            fi
         ;;

         --version)
            echo "$VERSION"
            exit 0
         ;;

         -v|--verbose)
            VERBOSE=YES
         ;;

         -*)
            echo "unknown option $1" >&2
            usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local libname

   if [ ! -z "${name}" ]
   then
      libname="`basename "${name:-$1}"`"
      libname="`echo "${libname}" | sed 's/^\([^.]*\)*\\..*$/\1/'`"

      [ -z "${libname}" ] && echo "could not figure out library name from \"${name:-$1}\"" >&2 && exit 1
   fi

   if [ ! -z "${outfile}" ]
   then
      trap "rm ${outfile}" INT TERM

      dump_libraries "${libname}" "${prefixes}" "$@"  | unix2dos > "${outfile}"
      if [ ! -z "${VERBOSE}" ]
      then
         echo "Dumped to ${outfile}" >&2
      fi
   else
      dump_libraries "${libname}" "${prefixes}" "$@"
   fi
}

main "$@"
