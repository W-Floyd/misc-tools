#!/bin/bash

set -f

__oext () {
echo "${1/*.}"
}

# __length <FILE>
# Reports length in miliseconds
__length () {
local __ext="$(__oext "${1}")"
case "${__ext}" in
    *)
        mediainfo --Inform="Audio;%Duration%" "${1}"
        ;;
esac
}

parent='Youtube'
target='Compilation'

if ! [ -d "${parent}" ]; then
    echo "Folder \"${parent}\" not present"
    exit
elif ! which mediainfo &> /dev/null; then
    echo "Please install mediainfo"
    exit
fi

if [ -d "${target}" ]; then
    rm -r "${target}"
fi

mkdir -p "${target}"

__link () {
ln -s "${__file}" "${file_target}"
}

find "${PWD}/${parent}/" -type f | grep -E '\.m4a$|\.mp3$|\.flac$' | sort | while read -r __file; do
    file_target="./${target}/$(basename "${__file}")"
    if [ -e "${file_target}" ]; then
        __new_length="$(__length "${__file}")"
        __old_length="$(__length "${file_target}")"
        if [ "${__new_length}" -gt "${__old_length}" ]; then
            rm "${file_target}"
            __link
        fi
    else
        __link
    fi
done

exit
