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
MULLE_BOOTSTRAP_MINGW_SH="included"


find_msvc_linker()
{
   local exe

   exe="${1:-link.exe}"

   local path
   local old
   local linker

   old="${IFS}"
   IFS=":"

   for path in $PATH
   do
      case "${path}" in
         /usr/*|/bin)
            continue;
         ;;

         *)
            linker="${path}/${exe}"
            if [ -x "${linker}" ]
            then
               log_verbose "MSVC linker found as ${C_RESET}${linker}"
               echo "${linker}"
               break
            fi
         ;;
      esac
   done

   IFS="${old}"
}


#
# fix path fckup
#
setup_mingw_environment()
{
	local linker

   if [ -z "${LIBPATH}" -o  -z "${INCLUDE}" ] && [ -z "${DONT_USE_VS}" ]
   then
      fail "environment variables INCLUDE and LIBPATH not set, start MINGW inside IDE environment"
   fi

	linker="`find_msvc_linker`"
	if [ ! -z "${linker}" ]
	then
		#LD="${linker}"
		#export LD
		# log_fluff "Environment ${C_INFO}LD${C_FLUFF} variable set to ${C_RESET}${LD}"
		:
	fi
}

