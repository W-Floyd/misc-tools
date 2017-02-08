#!/bin/bash
#
# <LIST_OF_FILES> | odir <FILE_1> <FILE_2> <FILE_3> ...
#
# Trims the all text after the last '/' in any given strings,
# either piped, and/or as inputs
#

__odir () {
echo "${1}" | sed 's|\(.*\)\(\/\).*|\1\2|'
}

while ! [ "${#}" = '0' ]; do
    __odir "${1}"
    shift
done

if read -t 0; then
    cat | while read -r __value; do
        __odir "${__value}"
    done
fi

exit
