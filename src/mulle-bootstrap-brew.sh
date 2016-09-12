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
MULLE_BOOTSTRAP_BREW_SH="included"


#
# Install brew into "addictions" via git clone
# this has the following advantages:
#    When fetching libraries or binaries they will
#    automatically appear in addictions/bin and addictions/lib / addictionsinclude
#    It's all local (!) to the project. Due to it being a git clone
#    and dependencies being wiped occasionally, its better to have a second
#    directory
#

BREW="${ADDICTION_SUBDIR}/bin/brew"


touch_last_update()
{
   local last_update

   last_update="${ADDICTION_SUBDIR}/.last_update"
   log_fluff "Touching ${last_update}"
   exekutor touch "${last_update}"
}


fetch_brew_if_needed()
{
   if [ -x "${BREW}" ]
   then
      return
   fi

   case "${UNAME}" in
      darwin)
         log_info "Installing OS X brew"
         exekutor git clone https://github.com/Homebrew/brew.git "${ADDICTION_SUBDIR}"
         ;;

      linux)
         log_info "Installing Linux brew"
         exekutor git clone https://github.com/Linuxbrew/brew.git "${ADDICTION_SUBDIR}"
         ;;

      *)
         log_fail "Missing brew support for ${UNAME}"
         ;;
   esac

   touch_last_update
   return 1
}


brew_update_if_needed()
{
   local what

   what="$1"

   local flag
   local stale

   fetch_brew_if_needed
   flag=$?
   if [ ! -z $flag ]
  	then
	  	return $flag  ## just fetched it or not there
	fi

   if [ -f "${last_update}" ]
   then
      stale="`find "${last_update}" -mtime +1 -type f -exec echo '{}' \;`"
      if [ -f "${last_update}" -a "$stale" = "" ]
      then
         log_verbose "brew seems to be up to date"
         return 0
      fi
   fi

   user_say_yes "Should brew be updated before installing ${what} ?"

   if [ $? -eq 0 ]
   then
      log_fluff "Updating brew, this can take some time..."
   	exekutor "${BREW}" update

      touch_last_update
   fi
}


brew_initialize()
{
   log_fluff ":brew_initialize:"

   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
}

brew_initialize
