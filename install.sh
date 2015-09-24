#! /bin/sh
#
# (c) 2015, coded by Nat!, Mulle KybernetiK
#

#
# restore colors if stuff gets wonky
#
trap 'echo "\033[0m"' TERM EXIT

prefix=${1:-"/usr/local"}
shift
mode=${1:-755}
shift
bin=${1:-"${prefix}/bin"}
shift
libexec=${1:-"${prefix}/libexec/mulle-bootstrap"}
shift

if [ "$prefix" = "" ] || [ "$bin" = "" ] || [ "$libexec" = "" ] || [ "$mode" = "" ]
then
   echo "usage: install.sh [prefix] [mode] [binpath] [libexecpath]"
   exit 1
fi

echo "\033[0;37m"

for i in mulle*bootstrap
do
   mkdir -p "${bin}" 2> /dev/null
   sed "s|/usr/local/libexec/mulle-bootstrap|${libexec}|g" < "${i}" > "${bin}/$i" || exit 1
   chmod "${mode}" "${bin}/${i}" || exit 1
   echo "installed $bin/$i" >&2
done


for i in mulle*.sh
do
   mkdir -p "${libexec}" 2> /dev/null
   install -v -m "${mode}" "$i" "${libexec}" || exit 1
done

if [ -d "test" ]
then
   # use attractive colors :)
   echo "\033[0;32mIf you are new to mulle-bootstrap I would suggest checking out" >&2
   echo "the \033[0;33mREADME.md\033[0;32m in \033[0;36m`pwd`/test\033[0;32m and doing the examples." >&2
fi

# for people who source us
PATH="${libexec}:$PATH"
