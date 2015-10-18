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
#

git_checkout_tag()
{
   local dst
   local tag

   dst="$1"
   tag="$2"

   log_info "Checking out ${C_MAGENTA}${tag}${C_INFO} ..."
   ( exekutor cd "${dst}" ; exekutor git checkout ${GITFLAGS} "${tag}" )

   if [ $? -ne 0 ]
   then
      log_error "Checkout failed, moving ${C_CYAN}${dst}${C_ERROR} to {C_CYAN}${dst}.failed${C_ERROR}"
      log_error "You need to fix this manually and then move it back."
      log_info "Hint: check ${BOOTSTRAP_SUBDIR}/`basename "${dst}"`/TAG" >&2

      rmdir_safer "${dst}.failed"
      exekutor mv "${dst}" "${dst}.failed"
      exit 1
   fi
}


git_clone()
{
   local src
   local dst
   local tag

   src="$1"
   dst="$2"
   tag="$3"

   [ ! -z "$src" ] || internal_fail "src is empty"
   [ ! -z "$dst" ] || internal_fail "dst is empty"

   log_info "Cloning ${C_MAGENTA}${src}${C_INFO} ..."
   exekutor git clone ${GITFLAGS} "${src}" "${dst}" || fail "git clone of \"${src}\" into \"${dst}\" failed"

   if [ "${tag}" != "" ]
   then
      git_checkout_tag "${dst}" "${tag}"
   fi
}


git_pull()
{
   local dst
   local tag

   dst="$1"
   tag="$2"

   [ ! -z "$dst" ] || internal_fail "dst is empty"

   log_info "Updating ${C_MAGENTA}${dst}${C_INFO} ..."
   ( exekutor cd "${dst}" ; exekutor git pull ${GITFLAGS} ) || fail "git pull of \"${dst}\" failed"

   if [ "${tag}" != "" ]
   then
      git_checkout_tag "${dst}" "${tag}"
   fi
}



svn_checkout()
{
   local src
   local dst
   local tag

   src="$1"
   dst="$2"
   tag="$3"

   [ ! -z "$src" ] || internal_fail "src is empty"
   [ ! -z "$dst" ] || internal_fail "dst is empty"

   log_info "SVN checkout ${C_MAGENTA}${src}${C_INFO} ..."

   local flags

   flags="${SVNFLAGS}"
   if [ ! -z "${tag}" ]
   then
      flags="-r ${tag} ${flags}"
   fi
   exekutor svn checkout ${flags} "${src}" "${dst}" || fail "svn clone of \"${src}\" into \"${dst}\" failed"
}


svn_update()
{
   local dst
   local tag

   dst="$1"
   tag="$2"

   [ ! -z "$dst" ] || internal_fail "dst is empty"

   log_info "SVN updating ${C_MAGENTA}${dst}${C_INFO} ..."

   local flags

   flags="${SVNFLAGS}"
   if [ ! -z "$tag" ]
   then
      flags="-r ${tag} ${flags}"
   fi

   ( exekutor cd "${dst}" ; exekutor svn update ${flags} ) || fail "svn update of \"${dst}\" failed"
}
