#!/bin/bash

# Ratio Approximator
#
# raproximate <DECIMAL_NUMBER> -c
#
# Press enter to keep trying to find closer approximations
# or use -c to not break and only show best

if ! [ -z "$(echo "${1}" | sed -e 's/[0-9]*\.[0-9]*//' -e 's/[0-9]*//')" ]; then
    echo "Not a number"
    exit
fi

stripzero () {
cat | sed -e 's/\([^0]*\)0*$/\1/' -e 's/\.$//'
}

hcf () {
# finding the highest value
if [[ $1 -eq $2 ]];then
   echo "${1}"
   return 0
elif [[ $1 -gt $2 ]];then
   greater="${1}"
   lower="${2}"
else
   greater="${2}"
   lower="${1}"
fi

#finding hcf
while [ $lower -ne 0 ];do
    hcf=$lower
    lower=$((greater%lower))
    greater=$hcf
done

echo "${hcf}"
}

simplify () {
# simplify a b
local common="$(hcf "${1}" "${2}")"

local __a="$(echo "${1}/${common}" | bc)"
local __b="$(echo "${2}/${common}" | bc)"

echo "${__a} ${__b}"
}

__goal="${1}"
__ratios=''
__tried=''
__diffs=''
__best=''
_a="$(echo "${__goal}/1" | bc)"
_b='1'

while true; do

    __ratio="$(echo "${_a}/${_b}" | bc -l)"

    __ratios="${_a}:${_b}
${__ratios}"

    __tried="${__ratio}
${__tried}"

    if [ "$(echo "${__ratio} > ${__goal}" | bc)" = '1' ]; then
        __sign='+'
        __diff="$(echo "(${__ratio}/${__goal})-1" | bc -l | stripzero)"
    else
        __sign='-'
        __diff="$(echo "1-(${__ratio}/${__goal})" | bc -l | stripzero)"
    fi

    __diffs="${__sign}${__diff}
${__diffs}"

    if ! [ "${2}" = '-c' ]; then

    echo -n "$(simplify ${_a} ${_b} | tr ' ' ':') - $(echo "${__ratio}" | stripzero) - "

    if [ "${__sign}" = '-' ]; then
        echo -e "\e[31m-${__diff}\e[39m"
    else
        echo -e "\e[32m+${__diff}\e[39m"
    fi

    fi

    __best="$(echo "${__diffs}" | grep -v '^$' | cut -c '2-' | sort -n | head -n 1)"

    __match_line="$(echo "${__diffs}" | cut -c '2-' | grep -n "${__best}" | head -n 1 | sed 's/\([0-9]*\):.*/\1/')"

    __best_ratio="$(echo "${__ratios}" | sed "${__match_line}!d")"

    if [ "$(echo "$(echo ${__best_ratio} | sed 's#:#/#' | bc -l) > ${__goal}" | bc)" = '1' ]; then
        __best_sign='+'
    else
        __best_sign='-'
    fi

    if [ "${2}" = '-c' -a "${__best}" = "${__diff}" ]; then

    echo -n "Best so far: $(simplify "$(echo ${__best_ratio} | sed 's/:.*//')" "$(echo ${__best_ratio} | sed 's/.*://')" | tr ' ' ':') - "

    if [ "${__best_sign}" = '-' ]; then
        echo -e "\e[31m-${__best}\e[39m"
    else
        echo -e "\e[32m+${__best}\e[39m"
    fi

    if [ "${__best}" = '0' ]; then
        echo "
Exactly: $(simplify "$(echo ${__best_ratio} | sed 's/:.*//')" "$(echo ${__best_ratio} | sed 's/.*://')" | tr ' ' ':')"

        exit
    fi

    fi

    if ! [ "${__best}" = "${__last_best}" ] && ! [ "${2}" = '-c' ]; then
        __last_best="${__best}"
        read -n 1
    elif ! [ "${2}" = '-c' ]; then
        echo
    fi

    until ! echo "${__tried}" | grep "${__ratio}" &> /dev/null; do

        if [ "${__sign}" = '-' ]; then
            _a=$((_a+1))
        else
           _b=$((_b+1))
        fi

        __ratio="$(echo "${_a}/${_b}" | bc -l)"

    done

done

exit
