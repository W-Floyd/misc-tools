#!/bin/bash
#
# <LIST_OF_FILES> | oext <FILE_1> <FILE_2> <FILE_3> ...
#
# Trims all text before the last '.' in any given strings,
# from piped lines, and/or as inputs
#

__oext () {
if grep -q ' ' <<< "${1}"; then
    sed 's#.*\.##' <<< "${1}"
else
    echo "${1/*.}"
fi
}

while ! [ "${#}" = '0' ]; do
    __oext "${1}"
    shift
done

if read -t 0; then
    cat | while read -r __value; do
        __oext "${__value}"
    done
fi

exit
