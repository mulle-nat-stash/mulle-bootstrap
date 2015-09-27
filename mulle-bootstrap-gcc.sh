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

gcc_sdk_parameter()
{
   local sdk
   local sdkpath

   sdk="$1"

   if [ "`uname`" = "Darwin" ]
   then
      if [ "${sdk}" != "Default" ]
      then
         sdkpath=`xcrun --sdk macosx --show-sdk-path`
         if [ "${sdkpath}" = "" ]
         then
            fail "SDK \"${sdk}\" is not installed"
         fi
         echo "${sdkpath}"
      fi
   fi
}


# Mash some known settings from xcodebuild together for regular
# OTHER_CFLAGS
# WARNING_CFLAGS
# GCC_PREPROCESSOR_DEFINITIONS

gcc_cflags_value()
{
   local value
   local result
   local name
   local i

   name="${1}"

   result=`get_build_setting "${name}" "OTHER_CFLAGS"`
   value=`get_build_setting "${name}"  "WARNING_CFLAGS"`
   result=`concat "$result" "$value"`
   for i in `get_build_setting "${name}" "GCC_PREPROCESSOR_DEFINITIONS"`
   do
      result=`concat "$result" "-D${i}"`
   done

   echo "${result}"
}


gcc_cppflags_value()
{
   local value
   local result
   local name

   name="${1}"

   result=`get_build_setting "${name}" "OTHER_CPPFLAGS"`
   value=`gcc_cflags_value "${name}"`
   result=`concat "$result" "$value"`

   echo "${result}"
}


gcc_ldflags_value()
{
   local result
   local name

   name="${1}"
   result=`get_build_setting "${name}" "OTHER_LDFLAGS"`

   echo "${result}"
}


