#!/bin/bash

__another='0'
__reset='0'
__current='0'
__permanent='0'
__new='0'
__list='0'
__update='0'
__given='0'
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
  -n  --new             Print a new mac address
  -a  --another         Change to a new mac address
  -p  --permanent       Print the permanent mac address
  -r  --reset           Reset to original mac address
  -c  --current         Print the current mac address
  -g  --given           Changes the mac address to
                        the next passed string.
  -l  --list            List available interfaces
  -u  --update          Fetch fresh oui list\
"
}

if ! [ "${#}" = 0 ]; then

while ! [ "${#}" = '0' ]; do

    case "${__last_option}" in

        "-g" | "--given")
            __custom_mac="${1}"
            if ! [ "$(echo "${__custom_mac}" | wc -c)" = 18 ]; then
                echo "Error: Given mac address is an invalid length"
                exit 1
            elif ! [ -z "$(echo "${__custom_mac}" | sed 's/^[0-9|a-z|A-Z]\{2\}[:|-][0-9|a-z|A-Z]\{2\}[:|-][0-9|a-z|A-Z]\{2\}[:|-][0-9|a-z|A-Z]\{2\}[:|-][0-9|a-z|A-Z]\{2\}[:|-][0-9|a-z|A-Z]\{2\}//')" ]; then
                echo "Error: Given mac address is badly formed"
                exit 1
            fi
            ;;

        *)

            case "${1}" in
                "-h" | "--help" | "-?")
                    __usage
                    exit 1
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

                "-g" | "--given")
                    __given='1'
                    ;;

                "-"*)
                    echo "Error: Invalid option '${1}' given"
                    exit 1
                    ;;

                *)
                    if [ -z "${__interface}" ]; then
                        if ! ifconfig "${1}" &> /dev/null; then
                            echo "Error: Network interface '${1}' does not exist"
                            exit 1
                        fi
                        __interface="${1}"
                    else
                        echo "Error: Only one interface may be specified"
                        exit 1
                    fi
                    ;;

            esac
            ;;

    esac

    __last_option="${1}"

    shift

done

else
    echo "Error: No inputs given"
    __usage
    exit 1
fi

__option_total="$(echo "${__another}+${__reset}+${__current}+${__permanent}+${__new}+${__list}+${__update}+${__given}" | bc)"

if [ "${__option_total}" == '0' ]; then
    echo "Error: No options passed"
    exit 1
elif [ "${__option_total}" -gt '1' ]; then
    echo "Error: More than one option given"
    exit 1
fi

__get_new_mac () {
echo "$(cat "${__oui_file}" | cut -c 1-6 | sed -e 's/.*/\L&/' -e 's/.\{2\}/&:/g' | shuf | head -n 1)$(od -t x1 -An -N 3 /dev/random | sed 's/^ //' | tr ' ' ':')" || { echo "Error: Failed to fetch new mac address"; exit 1; }
}

__get_current_mac () {
cat "/sys/class/net/${__interface}/address" || { echo "Error: Failed to fetch current mac address"; exit 1; }
}

__get_permanent_mac () {
if ! sudo which ethtool &> /dev/null; then
    echo "Error: Please ensure 'ethtool' is installed"
    exit 1
fi

sudo ethtool -P "${__interface}" | sed 's/.* //' || { echo "Error: Failed to fetch permanent mac address"; exit 1; }
}

__set_mac () {

if ! which ifconfig &> /dev/null; then
    echo "Error: Please ensure 'ifconfig' is installed"
    exit 1
elif ! sudo which ip &> /dev/null; then
    echo "Error: Please ensure 'ip' is installed"
    exit 1
fi

sudo ifconfig "${__interface}" down &> /dev/null || { echo "Error: Failed to take network interface '${__interface}' down"; exit 1; }
sudo ip link set "${__interface}" address "${1}" || { echo "Error: Failed to change mac on network interface '${__interface}'"; { sudo ifconfig "${__interface}" up || { echo "Error: Failed to bring network interface '${__interface}' up"; exit 1; }; }; exit 1; }
sudo ifconfig "${__interface}" up &> /dev/null || { echo "Error: Failed to bring network interface '${__interface}' up"; exit 1; }
}

__list_interfaces () {
if ! which ifconfig &> /dev/null; then
    echo "Error: Please ensure 'ifconfig' is installed"
    exit 1
fi

ifconfig -l | tr ' ' '\n' || { echo "Error: Failed to fetch interface list"; exit 1; }
}

__fetch_oui () {
if ! which wget &> /dev/null; then
    echo "Error: Please ensure 'wget' is installed"
    exit 1
fi

wget -O '/tmp/oui' "${__oui_source}" &> /dev/null || { echo "Error: Failed to fetch oui list"; exit 1; }
sudo mv '/tmp/oui' "${__oui_file}" || { echo "Error: Failed to replace existing oui list"; exit 1; }
}

if [ -z "${__interface}" ] && [ "${__list}" = '0' ] && [ "${__new}" = '0' ] && [ "${__update}" = '0' ]; then
    echo "Error: No interface specified"
    echo "Must be one of:"
    __list_interfaces
    exit 1
fi

if [ "${__given}" = '1' ] && [ -z "${__custom_mac}" ]; then
    echo "Error: No custom mac address specified"
    exit 1
fi

if ! [ -d "${__store}" ]; then
    sudo mkdir -p "${__store}" || { echo "Error: Failed to make directory for oui list"; exit 1; }
fi

if ! [ -e "${__oui_file}" ] && [ -e "${__oui_name}" ]; then
    sudo cp "${__oui_name}" "${__oui_file}" || { echo "Error: Failed to copy local oui list"; exit 1; }
fi

if ! [ -e "${__oui_file}" ] || [ "${__update}" = '1' ]; then
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
elif [ "${__given}" = '1' ]; then
    __set_mac "${__custom_mac}"
else
    echo "Error: Something has gone very wrong indeed"
    exit 1
fi

exit
