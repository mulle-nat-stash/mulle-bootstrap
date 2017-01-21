#! /bin/sh


copy_files_with_extension()
{
   local srcdir
   local dstdir
   local ext

   srcdir="$1"
   shift
   dstdir="$1"
   shift
   ext="$1"
   shift

   make_directory_if_missing "${dstdir}"

   local owd

   # can't getmyself to use pushd...

   owd="`pwd -P`"
      cd "${srcdir}" || internal_fail "could not cd to ${srcdir}"

      # copy over files
      find . -name "*.${ext}" -exec tar -cf - {} \; | ( cd "${dstdir}" ; tar xf "$@" -)

   cd "${owd}"
}


make_files_with_extension_extensionless()
{
   local directory
   local ext

   directory="$1"
   shift
   ext="$1"
   shift

   # copy over files
   IFS="
"
   for path in `find "${directory}" -name "*.${ext}"`
   do
      dstname="`basename -- "${path}" "${ext}"`"
      dstpath="`dirname -- "${path}" "${dstname}"`"

      if mv "$@" "${path}" "${dstpath}"
      then
         rm "${path}"
      fi
   done
}


override_files_with_files_with_extension()
{
   make_files_with_extension_extensionless "$@"
}


inherit_files_with_files_with_extension()
{
   make_files_with_extension_extensionless "$@" "-n"
}
