#!/bin/bash

set -e

declare -A __time __time_description __time_start __script_option

stripzero () {
#cat | sed -e 's/\(\.[0-9]*[^0]\)0*$/\1/' -e 's/\.$//' -e 's/\(.*[^0]\)[0*|\.0*]$/\1/'
cat | sed -e 's/^0*\(.*\..*\)/\1/' -e 's/\(.*\..*[^0]\)0*/\1/' -e 's/\.0*$//'
}

hcf () {
# finding the highest value
if [[ $1 -eq $2 ]];then
   echo "${1}"
   return 0
elif [[ $1 -gt $2 ]];then
   greater="${1}"
   lower="${2}"
elif [[ $1 -eq 0 ]];then
    echo '1'
    return 0
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
# simplify a b, outputs in a:b
local common="$(hcf "${1}" "${2}")"

local __a="$(bc <<< "${1}/${common}")"
local __b="$(bc <<< "${2}/${common}")"

echo "${__a}:${__b}"
}

__usage () {
echo "$(basename "${0}") <OPTIONS> <NUMBER>

Approximates ratios to a given number until it finds an exact match.

Options:
  -h  -?  --help            Short help (this message).

  -c  --converge            Use non-exhaustive starting numbers that may
                            converge quicker with numbers larger than 10

  -e  --exact               Use an alternative method to find the exact ratio.

  -b  --benchmark           Time some operations and give an iteration reading.
                            Comes with significant performance issues."
}

# __set_option <NAME> <VAL>
__set_option () {
__script_option[${1}]="${2}"
}

__check_option () {
[[ "${__script_option[${1}]}" = '1' ]]
}

__print_option () {
echo "${1^}: ${__script_option[${1}]}"
}

__set_option converge 0
__set_option exact 0
__set_option benchmark 0

until [ "${#}" = '0' ]; do

    case "${1}" in

    '-h' | '-?' | '--help')
        __usage
        exit
        ;;

    '-c' | '--converge')
        __set_option converge 1
        __exact='0'
        ;;

    '-e' | '--exact')
        __set_option exact 1
        ;;

    '-b' | '--benchmark')
        __set_option benchmark 1
        ;;

    '-'*)
        echo 'Not an option'
        exit
        ;;

    *)
        __goal="$(bc -l <<< ${1} | stripzero)"
        ;;

    esac

    shift

done

if [ -z "${__goal}" ]; then
    echo 'No goal specified'
    exit
elif ! [ -z "$(sed -e 's/[0-9]\+\.[0-9]\+//' -e 's/\.[0-9]\+//' -e 's/[0-9]*//' <<< "${__goal}")" ]; then
    echo "Not a number"
    exit
fi

__set_ratio () {
__ratio="$(bc -l <<< "${_a}/${_b}" | stripzero)"
}

__set_diff () {
__diff="$(bc -l <<< "${__goal}-${__ratio}" | sed 's/^[-|+]//' | stripzero)"
if [ -z "${__diff}" ]; then
    __diff='0'
fi
}

__set_sign () {
if [ "${__ratio}" = "${__goal}" ]; then
    __sign=''
elif [ "$(bc -l <<< "${__ratio} > ${__goal}")" = '1' ]; then
    __sign='+'
else
    __sign='-'
fi
}

__check_best () {
if [ "$(bc -l <<< "${__diff#[+|-]} < ${__best_diff#[+|-]}" 2> /dev/null)" = '1' ] || ( [ -z "${__best_diff}" ] || [ -z "${__best_ratio}" ] ); then
    __best_diff="${__sign}${__diff}"
    __best_ratio="${_a}:${_b}"
    if [ "${__best_diff}" = '0' ]; then
        echo "$(simplify "${__best_ratio/:*}" "${__best_ratio/*:}") - Exactly"
        break
    fi
    echo -n "$(simplify ${_a} ${_b}) - ${__ratio} - "
    if [ "${__sign}" = '-' ]; then
        echo -e "\e[34m-${__diff}\e[39m"
    else
        echo -e "\e[36m+${__diff}\e[39m"
    fi
fi
}
# __timer start|end DESCRIPTION
__timer () {
if __check_option benchmark; then
    local __curtime="$(date +%s.%N)"
    local __hash="$(md5sum <<< "${2}" | sed -e 's/ .*//' -e 's/^/X/')"
    if [ -z "${__time[${__hash}]}" ]; then
        __time[${__hash}]='0'
    fi
    if [ -z "${__time_description[${__hash}]}" ]; then
        __time_description[${__hash}]="${2}"
    fi
    if [ "${1}" = 'start' ]; then
        __time_start[${__hash}]="${__curtime}"
    elif [ "${1}" = 'end' ]; then
        __time[${__hash}]="$(bc <<< "${__time[${__hash}]}+(${__curtime}-${__time_start[${__hash}]})")"
    else
        echo 'Timer derp'
    fi
fi
}

__get_time () {
local __hash="$(md5sum <<< "${1}" | sed -e 's/ .*//' -e 's/^/X/')"
echo "${__time_description[${__hash}]^}: ${__time[${__hash}]}"
}

i=0

#set -x

if __check_option exact; then

    __timer start "Calculating exact number"

    i=$((i+1))

    if [ "${__goal}" = '0' ]; then

        __real='0:1'

    else

        __decimal="${__goal#[0-9]*.}"

        __mult="$(bc <<< "10^${#__decimal}")"

        _a="$(bc -l <<< "${__goal}*${__mult}" | stripzero)"

        _b="${__mult}"

        __real="$(simplify "${_a}" "${_b}")"

    fi

    echo "${__real/:*}:${__real/*:} - Exactly"

    __timer end "Calculating exact number"

else

    _a="$(bc <<< "${__goal}/1")"
    if [ "${__converge}" = '1' ]; then
        __num="$(bc <<< "10^(${#_a}-1)")"
        _b="${__num}"
        _a="$(bc <<< "${_a}*${__num}")"
    else
        _b='1'
    fi

    if [ "${__goal}" = '0' ]; then

        echo "0:1 - Exactly"

    else

        while true; do

            i=$((i+1))

            #__timer start "Set ratio"
            __set_ratio
            #__timer end "Set ratio"

            #__timer start "Set diff"
            __set_diff
            #__timer end "Set diff"

            #__timer start "Set sign"
            __set_sign
            #__timer end "Set sign"

            #__timer start "Check best"
            __check_best
            #__timer end "Check best"

            #__timer start "Change ratio"

            if [ "${__sign}" = '+' ]; then
                _b=$((_b+1))
            else
                _a=$((_a+1))
            fi

            #__timer end "Change ratio"

        done

    fi

fi

if __check_option benchmark; then

    for __item in "${__time_description[@]}"; do
        __get_time "${__item}"
    done | sort -rgk 3

    echo -n 'Total: '

    for __item in "${__time_description[@]}"; do
        __get_time "${__item}"
    done | sed 's/.* //' | paste -sd+ | bc

    echo "${i} Iterations"

fi

exit
