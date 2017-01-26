#!/bin/bash

__another='0'
__sanother='0'
__reset='0'
__current='0'
__permanent='0'
__new='0'
__snew='0'
__list='0'
__update='0'
__given='0'
__interface=''
__local_oui='0'

__oui_source='http://linuxnet.ca/ieee/oui/nmap-mac-prefixes'
__store='/usr/share/mactool'
__oui_name='nmap-mac-prefixes'
__oui_file="${__store}/${__oui_name}"

__usage () {
echo "${0} <OPTIONS> <INTERFACE>

Changes or reads the specified interfaces mac address

Options:
  -h  -? --help         This help message
  -n  --new             Print a new random mac address
  -sn --snew            Print a similar mac address
  -a  --another         Change to a random mac address
  -sa --sanother        Change to a similar mac address
  -p  --permanent       Print the permanent mac address
  -r  --reset           Reset to original mac address
  -c  --current         Print the current mac address
  -g  --given           Changes the mac address to
                        the next passed string.
  -l  --list            List available interfaces
  -u  --update          Fetch fresh oui list
  -lo --local           Use a local oui list\
"
}

__warn () {
echo "Error: ${@}"
}

__error () {
__warn "${@}"
exit 1
}

if ! [ "${#}" = 0 ]; then

while ! [ "${#}" = '0' ]; do

    case "${__last_option}" in

        "-g" | "--given")
            __custom_mac="${1}"
            if ! [ "$(echo "${__custom_mac}" | wc -c)" = 18 ]; then
                __error "Given mac address is an invalid length"
            elif ! [ -z "$(echo "${__custom_mac}" | sed 's/^[0-9|a-z|A-Z]\{2\}[:|-][0-9|a-z|A-Z]\{2\}[:|-][0-9|a-z|A-Z]\{2\}[:|-][0-9|a-z|A-Z]\{2\}[:|-][0-9|a-z|A-Z]\{2\}[:|-][0-9|a-z|A-Z]\{2\}//')" ]; then
                __error "Given mac address is badly formed"
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

                "-sa" | "--sanother")
                    __sanother='1'
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

                "-sn" | "--snew")
                    __snew='1'
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

                "-lo" | "--local")
                    __local_oui='1'
                    ;;

                "-"*)
                    __error "Invalid option '${1}' given"
                    ;;

                *)
                    if [ -z "${__interface}" ]; then
                        if ! ifconfig "${1}" &> /dev/null; then
                            __error "Network interface '${1}' does not exist"
                        fi
                        __interface="${1}"
                    else
                        __error "Only one interface may be specified"
                    fi
                    ;;

            esac
            ;;

    esac

    __last_option="${1}"

    shift

done

else
    __warn "No inputs given"
    __usage
    exit 1
fi

__option_total="$(echo "${__another}+${__sanother}+${__reset}+${__current}+${__permanent}+${__new}+${__snew}+${__list}+${__update}+${__given}" | bc)"

if [ "${__option_total}" == '0' ]; then
    __error "No usable options passed"
elif [ "${__option_total}" -gt '1' ]; then
    __error "More than one option given"
fi

__get_current_mac () {
cat "/sys/class/net/${__interface}/address" || __error "Failed to fetch current mac address"
}

__get_valid_oui () {
cat "${__oui_file}" | cut -c 1-6 | sed -e 's/.*/\L&/' -e 's/.\{2\}/&:/g' | shuf | head -n 1
}

__get_current_oui () {
__get_current_mac | cut -c 1-9
}

__get_mac_randomness () {
echo "$(od -t x1 -An -N 3 /dev/random | sed 's/^ //' | tr ' ' ':')" || __error "Failed to fetch new mac address"
}

__get_another_mac () {
echo "$(__get_valid_oui)$(__get_mac_randomness)"
}

__get_sanother_mac () {
echo "$(__get_current_oui)$(__get_mac_randomness)"
}

__get_permanent_mac () {
if ! sudo which ethtool &> /dev/null; then
    __error "Please ensure 'ethtool' is installed"
fi

sudo ethtool -P "${__interface}" | sed 's/.* //' || __error "Failed to fetch permanent mac address"
}

__set_mac () {

if ! which ifconfig &> /dev/null; then
    __error "Please ensure 'ifconfig' is installed"
elif ! sudo which ip &> /dev/null; then
    __error "Please ensure 'ip' is installed"
fi

sudo ifconfig "${__interface}" down &> /dev/null || __error "Failed to take network interface '${__interface}' down"
sudo ip link set "${__interface}" address "${1}" || { __warn "Failed to change mac on network interface '${__interface}'"; { sudo ifconfig "${__interface}" up || __error "Failed to bring network interface '${__interface}' up"; }; exit 1; }
sudo ifconfig "${__interface}" up &> /dev/null || __error "Failed to bring network interface '${__interface}' up"
}

__list_interfaces () {
if ! which ifconfig &> /dev/null; then
    __error "Please ensure 'ifconfig' is installed"
fi

ifconfig -l | tr ' ' '\n' || __error "Failed to fetch interface list"
}

__fetch_oui () {
if ! which wget &> /dev/null; then
    __error "Please ensure 'wget' is installed"
fi

wget -O '/tmp/oui' "${__oui_source}" &> /dev/null || __error "Failed to fetch oui list"
sudo mv '/tmp/oui' "${__oui_file}" || __error "Failed to replace existing oui list"
}

if [ -z "${__interface}" ] && [ "${__list}" = '0' ] && [ "${__new}" = '0' ] && [ "${__update}" = '0' ]; then
    __warn "No interface specified"
    echo "Must be one of:"
    __list_interfaces
    exit 1
fi

if [ "${__given}" = '1' ] && [ -z "${__custom_mac}" ]; then
    __error "No custom mac address specified"
fi

if [ "${__new}" = '1' ] || [ "${__another}" = '1' ] || [ "${__update}" = '1' ]; then

    if [ "${__local_oui}" = '0' ]; then

        if ! [ -d "${__store}" ]; then
            sudo mkdir -p "${__store}" || __warn "Failed to make directory for oui list"
        fi

        if ! [ -e "${__oui_file}" ] && [ -e "${__oui_name}" ]; then
            sudo cp "${__oui_name}" "${__oui_file}" || { __warn "Failed to copy local oui list"; __oui_file="${__oui_name}"; }
        fi

    else

        __oui_file="${__oui_name}"

    fi

    if ! [ -e "${__oui_file}" ] || [ "${__update}" = '1' ]; then
        echo "Fetching oui list"
        __fetch_oui
    fi

fi

if [ "${__another}" = '1' ]; then
    __set_mac "$(__get_another_mac)" 1> /dev/null
elif [ "${__sanother}" = '1' ]; then
    __set_mac "$(__get_sanother_mac)" 1> /dev/null
elif [ "${__reset}" = '1' ]; then
    __set_mac "$(__get_permanent_mac)" 1> /dev/null
elif [ "${__current}" = '1' ]; then
    __get_current_mac
elif [ "${__permanent}" = '1' ]; then
    __get_permanent_mac
elif [ "${__new}" = '1' ]; then
    __get_another_mac
elif [ "${__snew}" = '1' ]; then
    __get_sanother_mac
elif [ "${__list}" = '1' ]; then
    __list_interfaces
elif [ "${__given}" = '1' ]; then
    __set_mac "${__custom_mac}"
else
    __error "Something has gone very wrong indeed"
fi

exit
