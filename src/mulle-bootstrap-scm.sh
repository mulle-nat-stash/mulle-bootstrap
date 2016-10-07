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
MULLE_BOOTSTRAP_SCM_SH="included"


git_is_bare_repository()
{
   local is_bare

       # if bare repo, we can only clone anyway
    is_bare=`( cd "$1"; git rev-parse --is-bare-repository 2> /dev/null )`
    [ "${is_bare}" = "true" ]
}


git_get_branch()
{
   ( cd "$1" ; git rev-parse --abbrev-ref HEAD 2> /dev/null )
}


git_checkout_tag()
{
   local dst
   local tag

   dst="$1"
   tag="$2"

   local flags

   # checkout don't know -v
   flags="${GITFLAGS}"
   if [ "${flags}" = "-v" ]
   then
      flags=""
   fi

   local branch

   branch="`git_get_branch "${dst}"`"

   if [ "${branch}" != "${tag}" ]
   then
      log_info "Checking out version ${C_WHITE}${C_BOLD}${tag}${C_INFO} of ${C_MAGENTA}${C_BOLD}${dst}${C_INFO} ..."
      ( exekutor cd "${dst}" ; exekutor git checkout ${flags} "${tag}" )

      if [ $? -ne 0 ]
      then
         log_error "Checkout failed, moving ${C_CYAN}${C_BOLD}${dst}${C_ERROR} to ${C_CYAN}${C_BOLD}${dst}.failed${C_ERROR}"
         log_error "You need to fix this manually and then move it back."
         log_info "Hint: check ${BOOTSTRAP_SUBDIR}/`basename -- "${dst}"`/TAG" >&2

         rmdir_safer "${dst}.failed"
         exekutor mv "${dst}" "${dst}.failed"
         exit 1
      fi
   else
      log_fluff "Already on proper branch \"${branch}\""
   fi
}


git_clone()
{
   local src
   local dst
   local branch
   local tag
   local flags

   src="$1"
   dst="$2"
   branch="$3"
   tag="$4"
   flags="$5"

   [ ! -z "${src}" ] || internal_fail "src is empty"
   [ ! -z "${dst}" ] || internal_fail "dst is empty"

   if [ ! -z "${branch}" ]
   then
      log_info "Cloning branch ${C_RESET_BOLD}$branch${C_INFO} of ${C_MAGENTA}${C_BOLD}${src}${C_INFO} ..."
      flags="${flags} -b ${branch}"
   else
      log_info "Cloning ${C_MAGENTA}${C_BOLD}${src}${C_INFO} ..."
   fi

   exekutor git clone ${flags} ${GITFLAGS} "${src}" "${dst}" || fail "git clone of \"${src}\" into \"${dst}\" failed"

   if [ "${tag}" != "" ]
   then
      git_checkout_tag "${dst}" "${tag}"
   fi
}


git_pull()
{
   local dst
   local branch
   local tag
   local flags

   dst="$1"
   branch="$2"
   tag="$3"
   tag="$4"

   [ ! -z "$dst" ] || internal_fail "dst is empty"

   log_info "Updating ${C_MAGENTA}${C_BOLD}${dst}${C_INFO} ..."

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
   local branch
   local flags

   src="$1"
   dst="$2"
   branch="$3"
   tag="$4"
   flags="$5"

   [ ! -z "$src" ] || internal_fail "src is empty"
   [ ! -z "$dst" ] || internal_fail "dst is empty"


   if [ ! -z "${branch}" ]
   then
      log_info "SVN checkout ${C_RESET_BOLD}${branch}${C_INFO} of ${C_MAGENTA}${C_BOLD}${src}${C_INFO} ..."
      flags="${flags} -r ${branch}"
   else
      if [ ! -z "${tag}" ]
      then
         log_info "SVN checkout ${C_RESET_BOLD}${tag}${C_INFO} of ${C_MAGENTA}${C_BOLD}${src}${C_INFO} ..."
         flags="${flags} -r ${tag}"
      else
         log_info "SVN checkout ${C_MAGENTA}${C_BOLD}${src}${C_INFO} ..."
      fi
   fi


   exekutor svn checkout ${flags} ${SVNFLAGS} "${src}" "${dst}" || fail "svn clone of \"${src}\" into \"${dst}\" failed"
}


svn_update()
{
   local dst
   local branch
   local tag
   local flags

   dst="$1"
   branch="$2"
   tag="$3"
   flags="$4"

   [ ! -z "$dst" ] || internal_fail "dst is empty"

   log_info "SVN updating ${C_MAGENTA}${C_BOLD}${dst}${C_INFO} ..."


   if [ ! -z "$branch" ]
   then
      flags="-r ${branch} ${flags}"
   else
      if [ ! -z "$tag" ]
      then
         flags="-r ${tag} ${flags}"
      fi
   fi

   ( exekutor cd "${dst}" ; exekutor svn update ${flags} ${SVNFLAGS} ) || fail "svn update of \"${dst}\" failed"
}


run_git()
{
   local clonesdir

   clonesdir="$1"
   [ $# -eq 0 ] || shift

   local i

   for i in "${clonesdir}"/*
   do
      if [ -d "$i" ]
      then
         if [ -d "${i}/.git" -o -d "${i}/refs" ]
         then
            log_info "### $i:"
            (cd "$i" ; exekutor git ${GITFLAGS} "$@" ) || fail "git failed"
            log_info
         fi
      fi
   done

}


git_main()
{
   log_fluff "::: git :::"

   [ -z "${MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH}" ] && . mulle-bootstrap-local-environment.sh
   [ -z "${MULLE_BOOTSTRAP_SCRIPTS_SH}" ] && . mulle-bootstrap-scripts.sh


   while :
   do
      if [ "$1" = "-h" -o "$1" = "--help" ]
      then
         git_usage
      fi

      break
   done

   if dir_has_files "${CLONES_SUBDIR}"
   then
      log_fluff "Will git $* clones " >&2
   else
      log_info "There is nothing to run git over."
      return 0
   fi

   run_git "${CLONES_SUBDIR}" "$@"
}


scm_initialize()
{
   log_fluff ":scm_initialize:"
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
}

scm_initialize
