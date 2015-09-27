#! /bin/sh
#
# (c) 2015, coded by Nat!, Mulle KybernetiK
#

# Escape sequence and resets
C_RESET="\033[0m"

# Foreground colours
C_BLACK="\033[0;30m"   C_RED="\033[0;31m"    C_GREEN="\033[0;32m"
C_YELLOW="\033[0;33m"  C_BLUE="\033[0;34m"   C_MAGENTA="\033[0;35m"
C_CYAN="\033[0;36m"    C_WHITE="\033[0;37m"  C_BR_BLACK="\033[0;90m"

#
# restore colors if stuff gets wonky
#
trap 'echo "${C_RESET}"' TERM EXIT

#
# https://github.com/hoelzro/useful-scripts/blob/master/decolorize.pl
#

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

echo "${C_WHITE}"

for i in mulle*bootstrap
do
   mkdir -p "${bin}" 2> /dev/null
   sed "s|/usr/local/libexec/mulle-bootstrap|${libexec}|g" < "${i}" > "${bin}/$i" || exit 1
   chmod "${mode}" "${bin}/${i}" || exit 1
   echo "install: ${C_MAGENTA}$bin/$i${C_WHITE}" >&2
done


for i in mulle*.sh
do
   mkdir -p "${libexec}" 2> /dev/null
   install -v -m "${mode}" "$i" "${libexec}" || exit 1
done

if [ -d "test" ]
then
   # use attractive colors :)
   echo "${C_GREEN}If you are new to mulle-bootstrap I would suggest checking out" >&2
   echo "the ${C_YELLOW}README.md${C_GREEN} in ${C_CYAN}./test${C_GREEN} and doing the examples." >&2
fi

# for people who source us
PATH="${libexec}:$PATH"
