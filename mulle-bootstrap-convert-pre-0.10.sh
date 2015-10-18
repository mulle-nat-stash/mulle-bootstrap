#! /bin/sh
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
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

. mulle-bootstrap-local-environment.sh


move_it()
{
   local dir
   local src
   local dst

   dir="$1"
   src="$2"
   dst="$3"

   ( cd "${dir}" ; git ls-files "$src" --error-unmatch 2> /dev/null 1>&2 )

   if [ $? -eq 0 ]
   then
       ( exekutor cd "${dir}" ;  exekutor git mv "$src" "$dst" )
   else
       ( exekutor cd "${dir}" ; exekutor mv "$src" "$dst" )
   fi
}


main()
{
   local dir

   find "$@" -name "${BOOTSTRAP_SUBDIR}" -type d -print | while read -r dir
   do
      if [ -f "${dir}/gits" ]
      then
         move_it "${dir}" gits repositories
      fi

      if [ -f "${dir}/subgits" ]
      then
         move_it "${dir}" subgits embedded_repositories
      fi
   done
}


if [ $# -eq 0 ]
then
   main "."
else
   main "$@"
fi
