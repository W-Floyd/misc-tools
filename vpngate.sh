#!/bin/bash

__output_dir='./vpngate'

__fetch () {
echo 'Fetching newest list...'
# Fetch the raw CSV
#
# As I learnt, it's possible to accidentally spam this address, 
#
wget -q 'http://www.vpngate.net/api/iphone/' -O vpngate.csv
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

sed -e '1,2d' -e '$d' vpngate.csv | while read -r __line; do

    __name="${__line/,*}"
    __output="${__output_dir}/${__name}.ovpn"

    if ! [ -e "${__output}" ]; then

        openssl enc -base64 -d -A <<< "$(cut -d , -f 15 <<< "${__line}")" > "${__output}"

        __country="$(cut -d , -f 7 <<< "${__line}")"
        __country_file="${__output_dir}_country/.${__country}"

        if ! [ -e "${__country_file}" ]; then
            echo '0' > "${__country_file}"
        fi

        __num="$(cat "${__country_file}")"

        __num=$((__num+1))

        echo "${__num}" > "${__country_file}"

        __country_output="${__output_dir}_country/vpngate_${__country}_${__num}.ovpn"

        cp "${__output}" "${__country_output}"

        nmcli connection import type openvpn file "${__country_output}"

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

nmcli connection | grep vpngate | while read -r __line; do
sed -e 's/^[^ ]* *//' -e 's/ .*//' <<< "${__line}"
done | while read -r __id; do

    ((__num++))

    if [ "${__num}" -gt 10 ]; then

        nmcli connection delete "${__id}"

        wait

        __num=0

    else

            nmcli connection delete "${__id}" &

    fi

done

wait

}

if [ "${1}" = '-i' ]; then
    __install
elif [ "${1}" = '-u' ]; then
    __uninstall
elif [ "${1}" = '-f' ]; then
    __fetch
else
    echo '-f to fetch, -i to install, -u to uninstall. Required nmcli'
fi



exit
