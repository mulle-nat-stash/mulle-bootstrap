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

#
# read local environment
# source this file
#
if [ "${BOOTSTRAP_SUBDIR}" = "" ]
then
   BOOTSTRAP_SUBDIR=.bootstrap
fi

if [ ! -d "${BOOTSTRAP_SUBDIR}" ]
then
   echo "there is no ${BOOTSTRAP_SUBDIR} here, can't continue" >&2
   exit 1
fi

. mulle-bootstrap-functions.sh

#
# consider . .. ~ or absolute paths as unsafe
# anything starting with a $ is probably also bad
# this just catches some obvious problems, not all
# when in the environment, clones_subdir may be ..
#


CLONES_SUBDIR_IS_CLEANABLE=`read_config_setting clean_repos_folder`
CLONES_SUBDIR=`read_sane_config_path_setting "repos_foldername" ".repos"`
if [ $? -eq 0 -a "${CLONES_SUBDIR_IS_CLEANABLE}" = "" ]
then
   CLONES_SUBDIR_IS_CLEANABLE="YES"
fi


CLONESBUILD_SUBDIR_IS_CLEANABLE=`read_config_setting clean_build_folder`
CLONESBUILD_SUBDIR=`read_sane_config_path_setting "build_foldername" "build/.repos"`
if [ $? -eq 0 -a "${CLONESBUILD_SUBDIR_IS_CLEANABLE}" = "" ]
then
   CLONESBUILD_SUBDIR_IS_CLEANABLE="YES"
fi

DEPENDENCY_SUBDIR_IS_DIST_CLEANABLE=`read_config_setting clean_output_folder`
DEPENDENCY_SUBDIR=`read_sane_config_path_setting "output_foldername" "dependencies"`
if [ $? -eq 0 -a "${DEPENDENCY_SUBDIR_IS_DIST_CLEANABLE}" = "" ]
then
   DEPENDENCY_SUBDIR_IS_DIST_CLEANABLE="YES"
fi


if [ "${CLONES_FETCH_SUBDIR}" = "" ]
then
   CLONES_FETCH_SUBDIR="${CLONES_SUBDIR}"
fi

#
#
#
if [ "${CLONESBUILD_RELATIVE}" = "" ]
then
   CLONESBUILD_RELATIVE=`compute_relative "${CLONESBUILD_SUBDIR}"`
fi

if [ "${CLONES_RELATIVE}" = "" ]
then
   CLONES_RELATIVE=`compute_relative "${CLONES_SUBDIR}"`
fi

#
# some checks
#
[ -z "${BOOTSTRAP_SUBDIR}" ]     && internal_fail "variable BOOTSTRAP_SUBDIR is empty"
[ -z "${CLONES_SUBDIR}" ]        && internal_fail "variable CLONES_SUBDIR is empty"
[ -z "${CLONESBUILD_SUBDIR}" ]   && internal_fail "variable CLONESBUILD_SUBDIR is empty"
[ -z "${DEPENDENCY_SUBDIR}" ]    && internal_fail "variable DEPENDENCY_SUBDIR is empty"
[ -z "${CLONES_RELATIVE}" ]      && internal_fail "variable CLONES_RELATIVE is empty"
[ -z "${CLONESBUILD_RELATIVE}" ] && internal_fail "CLONESBUILD_RELATIVE is empty"

