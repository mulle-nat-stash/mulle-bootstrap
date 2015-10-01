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

#
# this script creates a .bootstrap folder with some
# demo files.
#
if [ "$1" = "-h" -o "$1" = "--help" ]
then
   echo "usage: init" >&2
   exit 1
fi

BOOTSTRAP_SUBDIR=.bootstrap

NO_DEFAULT_FILES=${1:-""}
shift
NO_EXAMPLE_FILES=${1:-""}
shift
DONT_OPEN_GITS=${1:-""}
shift


if [ -d "${BOOTSTRAP_SUBDIR}" ]
then
   echo "${BOOTSTRAP_SUBDIR} already exists" >&2
   exit 1
fi

main()
{
   project=""
   for i in *.xcodeproj/project.pbxproj
   do
      if [ -f "$i" ]
      then
        if [ "$project" != "" ]
        then
           echo "more than one xcodeproj found, cant' deal with it" >&1
           exit 1
        fi
        project="$i"
      fi
   done


   mkdir -p "${BOOTSTRAP_SUBDIR}" || exit 1

   if [ "${NO_DEFAULT_FILES}" = "" ]
   then
      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/brews"
# add projects that should be installed by brew
# e.g.
# zlib
EOF

#cat <<EOF > "${BOOTSTRAP_SUBDIR}/pips"
# add projects that should be installed by pip
# try to avoid it, since it needs sudo (uncool)
# mod-pbxproj
#EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/gits"
# add projects that should be cloned with git in order
# of their inter-dependencies
#
# possible types of repository URIs:
# http://www.mulle-kybernetik.com/repositories/MulleScion
# git@github.com:mulle-nat/MulleScion.git
# ../MulleScion
# /Volumes/Source/srcM/MulleScion
#
EOF
   fi

   if [ "${NO_EXAMPLE_FILES}" = "" ]
   then
      mkdir -p "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/bin" || exit 1

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/tag"
# specify a tag or branch for a project named MulleScion
# leave commented out or delete file for default branch (usually master)
# v1848.5.p3
EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/Release.map"
# map configuration Release in project MulleScion to DebugRelease
# leave commented out or delete file for no mapping
# DebugRelease
EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/project"
# Specify a xcodeproj to compile in project MulleScion instead of default
# leave commented out or delete file for default project
# mulle-scion
EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/scheme"
# Specify a scheme to compile in project MulleScion instead of default
# Might bite itself with TARGET, so only specify one.
# leave commented out or delete file for default scheme
# mulle-scion
EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/target"
# Specify a target to compile in project MulleScion instead of default.
# Might bite itself with SCHEME, so only specify one.
# leave commented out or delete file for default scheme
# mulle-scion
EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/bin/post-install.sh"
# Run some commands after installing project MulleScion
# leave commented out or delete file for no action
# chmod 755 ${BOOTSTRAP_SUBDIR}/MulleScion.example/bin/post-install.sh
# to make it work
# echo "1848"
EOF
#chmod 755 "${BOOTSTRAP_SUBDIR}/MulleScion.example/bin/post-install.sh"

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/bin/post-update.sh"
# Run some commands after upgrading project MulleScion
# leave commented out or delete file for no action
# chmod 755 ${BOOTSTRAP_SUBDIR}/MulleScion.example/bin/post-update.sh
# to make it work
# echo "1848"
EOF
#chmod 755 "${BOOTSTRAP_SUBDIR}/MulleScion.example/bin/post-upgrade.sh"

   fi

   echo "${BOOTSTRAP_SUBDIR} folder has been set up. Now add your gits to ${BOOTSTRAP_SUBDIR}/gits"

   if [ "${DONT_OPEN_GITS}" = "" -a "${NO_DEFAULT_FILES}" = "" ]
   then
       exekutor open -e "${BOOTSTRAP_SUBDIR}/gits"
   fi
}

main "$@"