#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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

MULLE_BOOTSTRAP_SNIP_SH="included"


snip_start_upto()
{
   local escaped

   escaped="`escaped_sed_pattern "$1"`"

   sed -n -e "/^${escaped}\$/q;p"
}


snip_end_from()
{
   local escaped

   escaped="`escaped_sed_pattern "$1"`"
   sed -e "1,/^${escaped}\$/d"
}


snip_end_from_excluding()
{
   local escaped

   escaped="`escaped_sed_pattern "$1"`"
   sed -n -e "/^${escaped}\$/,\$p"
}


_snip_middle_of_file()
{
   local from="$1"
   local to="$2"

   if [ ! -z "${from}" ]
   then
      snip_start_upto "${from}"
   else
      if [ -z "${to}" ]
      then
         cat
         return
      fi
   fi

   if [ ! -z "${to}" ]
   then
      snip_end_from_excluding "${to}"
   fi

}

snip_middle_of_file()
{
   local from="$1"
   local to="$2"
   local filename="$3"

   if ! [ -z "${filename}" ]
   then
      _snip_middle_of_file "${from}" "${to}" < "${filename}"
   else
      _snip_middle_of_file "${from}" "${to}"
   fi
}


_snip_from_to_file()
{
   local from="$1"
   local to="$2"

   if [ ! -z "${from}" ]
   then
      snip_start_upto "${from}"
   else
      if [ -z "${to}" ]
      then
         cat
         return
      fi
   fi

   if [ ! -z "${to}" ]
   then
      snip_end_from "${to}"
   fi

}


snip_from_to_file()
{
   local from="$1"
   local to="$2"
   local filename="$3"

   if ! [ -z "${filename}" ]
   then
      _snip_from_to_file "${from}" "${to}" < "${filename}"
   else
      _snip_from_to_file "${from}" "${to}"
   fi
}


# keep until "to" but excluding it
# cut stuff until "to"
# keep "to" and keep rest

force_rebuild()
{
   log_debug "force_rebuild" "$*"

   local from="$1"
   local to="$2"

   remove_file_if_present "${REPOS_DIR}/.build_started"

   # if nothing's build yet, fine with us
   if [ ! -f "${REPOS_DIR}/.build_done" ]
   then
      log_fluff "Nothing has been built yet"
      return
   fi

   if [ -z "${from}" -a -z "${to}" ]
   then
      remove_file_if_present "${REPOS_DIR}/.build_done"
      return
   fi

   #
   # keep entries above parameter
   # os x doesn't have 'Q'
   # also q and i doesn't work on OS X <sigh>
   #
   local tmpfile

   tmpfile="`make_tmp_file "bootstrap"`" || exit 1

   redirect_exekutor "${tmpfile}" snip_from_to_file "${from}" "${to}" "${REPOS_DIR}/.build_done"
   exekutor mv "${tmpfile}" "${REPOS_DIR}/.build_done"

   log_debug ".build_done=`cat "${REPOS_DIR}/.build_done"`"
}



snip_initialize()
{
   log_debug ":snip_initialize:"

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
   :
}

snip_initialize

