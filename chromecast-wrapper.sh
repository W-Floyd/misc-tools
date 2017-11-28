#!/bin/bash

which stream2chromecast &> /dev/null || { zenity --error --text='stream2chromecast could not be found'; exit; }

__progress_pipe="$(mktemp)"

tail -f "${__progress_pipe}" | zenity \
--progress \
--pulsate \
--auto-kill \
--auto-close \
--text='Searching for Chromecast devices...' &

__device_list="$(stream2chromecast -devicelist | sed '1,2d' | sed 's/.* : //')"

echo 100 > "${__progress_pipe}"

rm "${__progress_pipe}"

if [ -z "${__device_list}" ]; then
    zenity --error --text='No Chromecast devices could be found'
    exit
fi

__list_array=()

while read -r __line; do
    __list_array+=('FALSE')
    __list_array+=("${__line}")
done <<< "${__device_list}"

__target_device="$(
zenity \
--list \
--radiolist \
--column='' \
--column='Chromecast Device' \
--text='Select your target device.' \
"${__list_array[@]}"
)"

__source_file="$(zenity --file-selection)"

# <file> <track>
__extract_sub () {

local __sub_file="$(mktemp -u --suffix='.srt')"

mkvextract tracks "${1}" "${2}":"${__sub_file}" &> /dev/null

echo "${__sub_file}"

}

__oext () {
if grep -q ' ' <<< "${1}"; then
    sed 's#.*\.##' <<< "${1}"
else
    echo "${1/*.}"
fi
}

if which mkvmerge &> /dev/null && [ "$(__oext "${__source_file}")" = 'mkv' ]; then
    __subs="$(mkvmerge -i "${__source_file}" | grep subtitles | sed 's/Track ID \([0-9]*\).*/\1/')"
    if ! [ -z "${__subs}" ]; then
        if [ "$(wc -l <<< "${__subs}")" = 1 ]; then
            if zenity --question --text='Do you want to use the embedded subtitle track?'; then
                __use_sub='true'
                __sub="${__subs}"
                __sub_file="$(__extract_sub "${__source_file}" "${__sub}")"
            else   
                __use_sub='false'
            fi
        else

            if zenity --question --text='Do you want to use an embedded subtitle track?'; then
                __use_sub='true'

                __list_array=()

                while read -r __line; do
                    __list_array+=('FALSE')
                    __list_array+=("${__line}")
                done <<< "${__subs}"

                __sub="$(
                zenity \
                --list \
                --radiolist \
                --column='' \
                --column='Track ID' \
                --text='Select your target subtitle ID.' \
                "${__list_array[@]}"
                )"

                __sub_file="$(__extract_sub "${__source_file}" "${__sub}")"

            else   
                __use_sub='false'
            fi

        fi
    fi
fi

if ! [ "${__use_sub}" = 'true' ]; then
    if zenity --question --text='Do you want to use an external subtitle track?'; then
        __use_sub='true'
        __sub_file="$(mktemp -u --suffix='.srt')"
        cp "$(zenity --file-selection)" "${__sub_file}"
    else
        __use_sub='false'
    fi
fi

if [ "${__use_sub}" = 'true' ]; then

    stream2chromecast \
    -transcode \
    -transcodeopts \
    "-f matroska -vf subtitles=${__sub_file}" \
    -transcodebufsize 5242880 \
    -devicename "${__target_device}" \
    "${__source_file}"

else

    stream2chromecast \
    -devicename "${__target_device}" \
    "${__source_file}"

fi

if [ -e "${__sub_file}" ]; then
    rm "${__sub_file}"
fi

exit
