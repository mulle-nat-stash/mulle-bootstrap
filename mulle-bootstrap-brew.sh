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

fetch_brew_if_needed()
{
   local last_update
   local binary

   last_update="${HOME}/.mulle-bootstrap/brew-update"

   binary=`which brew`
   if [ "${binary}" = "" ]
   then
      user_say_yes "Brew isn't installed on this system.
Install brew now (Linux or OS X should work) ? "
      if [ $? -ne 0 ]
      then
         return 2
      fi

      if [ "`uname`" = 'Darwin' ]
      then
         log_info "Installing OS X brew"
         exekutor ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 1
      else
         log_info "Installing Linux brew"
         exekutor ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)" || exit 1
      fi

      log_fluff "Touching ${last_update}"
      exekutor mkdir_if_missing "`dirname -- "${last_update}"`"
      exekutor touch "${last_update}"
      return 1
   fi
   return 0
}


brew_update_if_needed()
{
   local stale
   local last_update
   local what

   what="$1"
   last_update="${HOME}/.mulle-bootstrap/brew-update"

   fetch_brew_if_needed
   if [ $? -eq 1 ]
  	then
	  	return 0  ## just fetched it
	fi

   if [ -f "${last_update}" ]
   then
      stale="`find "${last_update}" -mtime +1 -type f -exec echo '{}' \;`"
      if [ -f "${last_update}" -a "$stale" = "" ]
      then
         log_fluff "brew seems to be up to date"
         return 0
      fi
   fi

   user_say_yes "Should brew be updated before installing ${what} ?"

   if [ $? -eq 0 ]
   then
      log_fluff "Updating brew, this can take some time..."
   	exekutor brew update

	   mkdir_if_missing "`dirname -- "${last_update}"`"
   	exekutor touch "${last_update}"
   fi
}
