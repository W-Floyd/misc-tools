#!/bin/bash

__numbefore='0'
__equation='0'
__lastlarge='0'

__verbose='0'

__roman_number=''

__usage () {
echo "${0} <OPTIONS> <ROMAN_NUMERALS>

Converts a Roman numeral into base 10 arabic numerals

Options:
  -h  -? --help         This help message
  -v  --verbose         Show the final equation produced\
"
}

if ! [ "${#}" = 0 ]; then

    while ! [ "${#}" = '0' ]; do

        case "${1}" in
            "-h" | "--help" | "-?")
                __usage
                exit 1
                ;;

            "-v" | "--verbose")
                __verbose='1'
                ;;

            "-"*)
                echo "Error: Invalid option '${1}' given"
                exit 1
                ;;

            *)
                if [ -z "$(echo "${1}" | sed 's/[i|I|v|V|x|X|l|L|c|C|d|D|m|M]*//g')" ]; then
                    if [ -z "${__roman_number}" ]; then
                        __roman_number="${1}"
                    else
                        if [ "${__verbose}" = '1' ]; then
                            echo "Error: Only one number may be specified, ignoring '${1}'"
                        fi
                    fi
                else
                    if [ "${__verbose}" = '1' ]; then
                        echo "Error: Invalid characters in specified number, ignoring '${1}'"
                    fi
                fi
                ;;

        esac

        shift

    done

else
    echo "Error: No inputs given"
    __usage
    exit 1
fi

for __numeral in $(echo "${__roman_number}" | sed -e 's/./& /g' | rev); do

case "${__numeral}" in
	'i' | 'I')
		__number='1'
		;;
	'v' | 'V')
		__number='5'
		;;
	'x' | 'X')
		__number='10'
		;;
	'l' | 'L')
		__number='50'
		;;
	'c' | 'C')
		__number='100'
		;;
	'd' | 'D')
		__number='500'
		;;
	'm' | 'M')
		__number='1000'
		;;
	*)
		echo "Unrecognized character '${__numeral}'.
Please use the following numerals
I (1)
V (5)
X (10)
L (50)
C (100)
D (500)
M (1000)"
		exit
esac

if [ "${__number}" -gt "${__lastlarge}" ]; then
	__lastlarge="${__number}"
fi

if [ "${__numbefore}" -lt "${__number}" ]; then
	__sign1="+"
elif [ "${__numbefore}" -eq "${__number}" ]; then
	if [ "${__number}" -lt "${__lastlarge}" ]; then
		__sign1="-"
	else
		__sign1="+"
	fi
else
	__sign1="-"
fi

__numbefore="${__number}"

__equation="${__equation}${__sign1}${__number}"

done

__equation=$(echo "${__equation}" | cut -c3-)

__answer=$(echo "${__equation}" | bc)

if [ "${__verbose}" = '1' ]; then
    echo "${__equation}"
    echo "${__roman_number} = ${__answer}"
else
    echo "${__answer}"
fi

exit
