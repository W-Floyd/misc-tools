#!/bin/bash

################################################################################
# __save_array <ARRAY1> <ARRAY2> <ARRAY3> ...
#
# Save Array
# Saves specified arrays in a function called __restore_array.
#
################################################################################

__save_array () {

local __header='__restore_array () {
until [ "${#}" = 0 ]; do
case "${1}" in'
local __tail='esac
shift
done
}'

eval "${__header}
$(until [ "${#}" = 0 ]; do
    echo "${1})"
    echo "declare -gA ${1}"
    for __item in $(eval "echo \${!${1}[@]}"); do
        echo "${1}[${__item}]=$(eval "echo \${${1}[${__item}]}")"
    done
    echo ";;"
    shift
done)
${__tail}"

export -f __restore_array

}

################################################################################
# __restore_array ( <ARRAY1> <ARRAY2> ... )
#
# Restore Array
# Restores specified arrays, or, if no options are given, all arrays.
# Self destructs on use, so be careful.
#
################################################################################

echo 'This is not a script to run, please view this file directly and extract parts as needed.'

exit
