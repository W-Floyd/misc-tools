#!/bin/bash

__output_dir='./vpngate'

__size () {
stat "${1}" -c %s
}

__fetch () {
echo 'Fetching newest list...'
# Fetch the raw CSV
#
# As I learnt, it's possible to accidentally spam these addressess, so I've put a number in
#
while read -r __url; do
    echo "Trying ${__url}"
    if curl --output /dev/null --silent --head --fail "${__url}"; then
        curl "${__url}" -o vpngate.csv
        if ! [ "$(__size vpngate.csv)" = 0 ] ; then
            break
        fi
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
} > _vpngate.csv 

echo 'Extracting configs...'

n=0

while read -r __line; do

    ((n++))

    __name="${__line/,*}"
    __output="${__output_dir}/${__name}.ovpn"

    if ! [ -e "${__output}" ]; then

        openssl enc -base64 -d -A <<< "$(cut -d , -f 15 <<< "${__line}")" > "${__output}"

        __destination="$(grep -E '^remote' "${__output}" | sed 's/^.* \([^ ]*\) .*/\1/')"

        echo "${n},${__destination}" >> vpngate_destinations.csv

    fi
    
done < _vpngate.csv

echo 'Testing addresses...'

while read -r __line; do

    echo "${__line#*,}"

done < vpngate_destinations.csv | fping -a -f - 2>/dev/null > vpngate_pingable.csv

echo 'Installing valid configs...'

while read -r __destination; do

    __list_line="$(grep -E "^[0-9]*,${__destination}$" < vpngate_destinations.csv)"

    __line_number="${__list_line/,*}"

    __line="$(sed "${__line_number}!d" < _vpngate.csv)"

    __name="${__line/,*}"
    __output="${__output_dir}/${__name}.ovpn"

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
    
done < vpngate_pingable.csv

rm _vpngate.csv

}

__uninstall () {

if [ -d "${__output_dir}" ]; then
    rm -r "${__output_dir}"
fi

if [ -d "${__output_dir}_country" ]; then
    rm -r "${__output_dir}_country"
fi

nmcli -m multiline connection show | while mapfile -t -n 4 ary && ((${#ary[@]})); do
    __type="$(echo "${ary[2]}" | sed 's/^[^ ]* *//')"
    if [ "${__type}" = 'vpn' ]; then
        __name="$(echo "${ary[0]}" | sed 's/^[^ ]* *//')"
        if echo "${__name}" | grep --silent -E '^VPN Gate'; then
            echo "$(echo "${ary[1]}" | sed 's/^[^ ]* *//')"
        fi
    fi
    
done | parallel -j10 nmcli connection delete

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
    echo '-f to fetch, -i to install, -u to uninstall. Requires nmcli'
fi

exit
