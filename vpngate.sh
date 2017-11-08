#!/bin/bash

__output_dir='./vpngate'

__fetch () {
echo 'Fetching newest list...'
# Fetch the raw CSV
#
# As I learnt, it's possible to accidentally spam these addressess, so I've put a number in
#
while read -r __url; do
    echo "Trying ${__url}"
    if curl --output /dev/null --silent --head --fail "${__url}"; then
        wget -q "${__url}" -O vpngate.csv
        break
    fi
done <<< 'http://www.vpngate.net/api/iphone/
http://118.216.211.167:36479/api/iphone/
http://65.49.54.51:58486/api/iphone/
http://175.205.176.171:54531/api/iphone/
http://211.243.203.173:48914/api/iphone/
http://211.229.147.154:41916/api/iphone/'

}

__install () {

if ! [ -e 'vpngate.csv' ]; then
    echo 'Please fetch (`-f`) the list first.'
    exit 1
fi

if ! [ -d "${__output_dir}" ]; then
    mkdir "${__output_dir}"
fi

if ! [ -d "${__output_dir}_country" ]; then
    mkdir "${__output_dir}_country"
fi

sed -e '1,2d' -e '$d' vpngate.csv | {
    if [ "${__install_num}" = '0' ]; then
        cat
    else
        head -n "${__install_num}"
    fi
} | while read -r __line; do

    __name="${__line/,*}"
    __output="${__output_dir}/${__name}.ovpn"

    if ! [ -e "${__output}" ]; then

        openssl enc -base64 -d -A <<< "$(cut -d , -f 15 <<< "${__line}")" > "${__output}"

        __destination="$(grep -E '^remote' "${__output}" | sed 's/^.* \([^ ]*\) .*/\1/')"

        echo -n "Testing ${__destination}... "

        if fping "${__destination}" -q; then

            echo 'success'

            __country="$(cut -d , -f 6 <<< "${__line}")"
            __country_file="${__output_dir}_country/.${__country}"

            if ! [ -e "${__country_file}" ]; then
                echo '00' > "${__country_file}"
            fi

            __num="$(cat "${__country_file}")"

            __num="$((10#$__num+1))"

            __num="$(printf "%02d\n" "${__num}")"

            echo "${__num}" > "${__country_file}"

            __country_output="${__output_dir}_country/VPN Gate ${__country} ${__num}.ovpn"

            cp "${__output}" "${__country_output}"

            nmcli connection import type openvpn file "${__country_output}"

        else
            echo ' fail'
        fi

    fi
    
done

}

__uninstall () {

if [ -d "${__output_dir}" ]; then
    rm -r "${__output_dir}"
fi

if [ -d "${__output_dir}_country" ]; then
    rm -r "${__output_dir}_country"
fi

__num=0

nmcli -m multiline connection show | while mapfile -t -n 4 ary && ((${#ary[@]})); do
    __type="$(echo "${ary[2]}" | sed 's/^[^ ]* *//')"
    if [ "${__type}" = 'vpn' ]; then
        __name="$(echo "${ary[0]}" | sed 's/^[^ ]* *//')"
        if echo "${__name}" | grep --silent -E '^VPN Gate'; then
            __id="$(echo "${ary[1]}" | sed 's/^[^ ]* *//')"

            ((__num++))

            if [ "${__num}" -gt 10 ]; then
                nmcli connection delete "${__id}"
                wait
                __num=0
            else
                nmcli connection delete "${__id}" &
            fi

        fi
    fi
    
done

wait

}

if [ "${1}" = '-i' ]; then
    shift
    if ! [ -z "${1}" ]; then
        __install_num="${1}"
    else
        __install_num='0'
    fi
    __install
elif [ "${1}" = '-u' ]; then
    __uninstall
    wait
elif [ "${1}" = '-f' ]; then
    __fetch
else
    echo '-f to fetch, -i to install, -u to uninstall. Required nmcli'
fi



exit
