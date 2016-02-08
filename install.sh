#! /bin/sh
#
# (c) 2015, coded by Nat!, Mulle KybernetiK
#

if [ "${MULLE_BOOTSTRAP_NO_COLOR}" != "YES" ]
then
   case `uname` in
      Darwin|Linux|FreeBSD)
         # Escape sequence and resets
         C_RESET="\033[0m"

         # Useable Foreground colours, for black/white white/black
         C_RED="\033[0;31m"     C_GREEN="\033[0;32m"
         C_BLUE="\033[0;34m"    C_MAGENTA="\033[0;35m"
         C_CYAN="\033[0;36m"

         C_BR_RED="\033[0;91m"
         C_BOLD="\033[1m"

         #
         # restore colors if stuff gets wonky
         #
         trap 'printf "${C_RESET}"' TERM EXIT
         ;;
   esac
fi

#
# https://github.com/hoelzro/useful-scripts/blob/master/decolorize.pl
#

prefix=${1:-"/usr/local"}
[ $# -eq 0 ] || shift
mode=${1:-755}
[ $# -eq 0 ] || shift
bin=${1:-"${prefix}/bin"}
[ $# -eq 0 ] || shift
libexec=${1:-"${prefix}/libexec/mulle-bootstrap"}
[ $# -eq 0 ] || shift

if [ "$prefix" = "" ] || [ "$bin" = "" ] || [ "$libexec" = "" ] || [ "$mode" = "" ]
then
   echo "usage: install.sh [prefix] [mode] [binpath] [libexecpath]"
   exit 1
fi


for i in mulle*bootstrap
do
   mkdir -p "${bin}" 2> /dev/null
   sed "s|/usr/local/libexec/mulle-bootstrap|${libexec}|g" < "${i}" > "${bin}/$i" || exit 1
   chmod "${mode}" "${bin}/${i}" || exit 1
   printf "install: ${C_MAGENTA}${C_BOLD}%s${C_RESET}\n" "$bin/$i" >&2
done


for i in mulle*.sh
do
   mkdir -p "${libexec}" 2> /dev/null
   install -v -m "${mode}" "$i" "${libexec}" || exit 1
done

if [ -d "test" ]
then
   # use attractive colors :)
   printf "${C_GREEN}If you are new to mulle-bootstrap I would suggest checking out\n" >&2
   printf "the ${C_YELLOW}README.md${C_GREEN} in ${C_CYAN}./test${C_GREEN} and doing the examples.\n" >&2
fi

# for people who source us
PATH="${libexec}:$PATH"
