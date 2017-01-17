#!/bin/bash

__another='0'
__reset='0'
__current='0'
__permanent='0'
__new='0'
__list='0'
__update='0'
__interface=''

__oui_source='http://linuxnet.ca/ieee/oui/nmap-mac-prefixes'
__store='/usr/share/mactool'
__oui_name='nmap-mac-prefixes'
__oui_file="${__store}/${__oui_name}"

__usage () {
echo "${0} <OPTIONS> <INTERFACE>

Changes or reads the specified interfaces mac address

Options:
  -h  -? --help         This help message
  -a  --another         Change to another mac address
  -r  --reset           Reset to original mac address
  -c  --current         Print the current mac address
  -p  --permanent       Print the permanent mac address
  -n  --new             Print a new mac address
  -l  --list            List available interfaces
  -u  --update          Fetch fresh oui list\
"
}

if ! [ "${#}" = 0 ]; then
    while ! [ "${#}" = '0' ]; do
        case "${1}" in
            "-h" | "--help" | "-?")
                __usage
                exit 0
                ;;

            "-a" | "--another")
                __another='1'
                ;;

            "-r" | "--reset")
                __reset='1'
                ;;

            "-c" | "--current")
                __current='1'
                ;;

            "-p" | "--permanent")
                __permanent='1'
                ;;

            "-n" | "--new")
                __new='1'
                ;;

            "-l" | "--list")
                __list='1'
                ;;

            "-u" | "--update")
                __update='1'
                ;;

            "-"*)
                echo "Error: Invalid option '${1}' given"
                exit 2
                ;;

            *)
                if [ -z "${__interface}" ]; then
                    if ! ifconfig "${1}" &> /dev/null; then
                        echo "Error: Network interface '${1}' does not exist"
                        exit 3
                    fi
                    __interface="${1}"
                else
                    echo "Error: Only one interface may be specified"
                    exit 4
                fi
                ;;

        esac
        shift
    done
else
    echo "Error: No inputs given"
    __usage
    exit 1
fi

__option_total="$(echo "${__another}+${__reset}+${__current}+${__permanent}+${__new}+${__list}+${__update}" | bc)"

if [ "${__option_total}" == '0' ]; then
    echo "Error: No options passed"
    exit 5
elif [ "${__option_total}" -gt '1' ]; then
    echo "Error: More than one option given"
    exit 6
fi

if [ -z "${__interface}" ] && [ "${__list}" = '0' ] && [ "${__new}" = '0' ] && [ "${__update}" = '0' ]; then
    echo "Error: No interface specified"
    exit 7
fi

__get_new_mac () {
echo "$(cat "${__oui_file}" | cut -c 1-6 | sed -e 's/.*/\L&/' -e 's/.\{2\}/&:/g' | shuf | head -n 1)$(od -t x1 -An -N 3 /dev/random | sed 's/^ //' | tr ' ' ':')" || { echo "Error: Failed to fetch new mac address"; exit 8; }
}

__get_current_mac () {
cat "/sys/class/net/${__interface}/address" || { echo "Error: Failed to fetch current mac address"; exit 9; }
}

__get_permanent_mac () {
if ! sudo which ethtool &> /dev/null; then
    echo "Error: Please ensure 'ethtool' is installed"
    exit 10
fi

sudo ethtool -P "${__interface}" | sed 's/.* //' || { echo "Error: Failed to fetch permanent mac address"; exit 11; }
}

__set_mac () {

if ! which ifconfig &> /dev/null; then
    echo "Error: Please ensure 'ifconfig' is installed"
    exit 12
elif ! sudo which ip &> /dev/null; then
    echo "Error: Please ensure 'ip' is installed"
    exit 13
fi

sudo ifconfig "${__interface}" down || { echo "Error: Failed to take network interface '${__interface}' down"; exit 14; }
sudo ip link set "${__interface}" address "${1}" || { echo "Error: Failed to change mac on network interface '${__interface}'"; exit 15; }
sudo ifconfig "${__interface}" up  || { echo "Error: Failed to bring network interface '${__interface}' up"; exit 16; }
}

__list_interfaces () {
if ! which ifconfig &> /dev/null; then
    echo "Error: Please ensure 'ifconfig' is installed"
    exit 17
fi

ifconfig -l | tr ' ' '\n' || { echo "Error: Failed to fetch interface list"; exit 18; }
}

__fetch_oui () {
if ! which wget &> /dev/null; then
    echo "Error: Please ensure 'wget' is installed"
    exit 19
fi

sudo wget -O "${__oui_file}" "${__oui_source}" &> /dev/null || { echo "Error: Failed to fetch oui list"; exit 20; }
}

if ! [ -d "${__store}" ]; then
    sudo mkdir -p "${__store}" || { echo "Error: Failed to make directory for oui list"; exit 21; }
fi

if [ "${__update}" = '1' ] && [ -e "${__oui_file}" ]; then
    rm "${__oui_file}" || { echo "Error: Failed to remove existing oui list"; exit 22; }
elif ! [ -e "${__oui_file}" ] && [ -e "${__oui_name}" ]; then
    sudo cp "${__oui_name}" "${__oui_file}" || { echo "Error: Failed to copy local oui list"; exit 23; }
fi

if ! [ -e "${__oui_file}" ]; then
    echo "Fetching oui list"
    __fetch_oui
fi

if [ "${__another}" = '1' ]; then
    __set_mac "$(__get_new_mac)"  1> /dev/null
elif [ "${__reset}" = '1' ]; then
    __set_mac "$(__get_permanent_mac)" 1> /dev/null
elif [ "${__current}" = '1' ]; then
    __get_current_mac
elif [ "${__permanent}" = '1' ]; then
    __get_permanent_mac
elif [ "${__new}" = '1' ]; then
    __get_new_mac
elif [ "${__list}" = '1' ]; then
    __list_interfaces
else
    echo "Error: Something has gone very wrong indeed"
    exit 24
fi

exit
