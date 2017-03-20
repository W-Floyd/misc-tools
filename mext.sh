#!/bin/bash
#
# <LIST_OF_FILES> | mext <FILE_1> <FILE_2> <FILE_3> ...
#
# Trims all text after the last '.' in any given strings,
# either piped lines, and/or as inputs
#

__mext () {
echo "${1%.*}"
}

while ! [ "${#}" = '0' ]; do
    __mext "${1}"
    shift
done

if read -t 0; then
    cat | while read -r __value; do
        __mext "${__value}"
    done
fi

exit
