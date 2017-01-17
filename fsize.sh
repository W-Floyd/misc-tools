#!/bin/bash

__filelist=""

__bytes="0"

__usage () {
echo "${0} <OPTIONS> <FILE(s)>

Prints the file size of all given files

Options:
  -h  -? --help         This help message
  -b  --byte            Print the file size in bytes\
"
}

if ! [ "${#}" = 0 ]; then

    while ! [ "${#}" = '0' ]; do

        case "${1}" in

            "-h" | "--help" | "-?")
                __usage
                exit 0
                ;;

            "-b")
                __bytes="1"
                ;;

            *)
                if ! [ -e "${1}" ]; then
                    echo "File \"${1}\" does not exist"
                else
                    __filelist="${__filelist}
${1}"
                fi
                ;;
        esac

        shift

    done

else

    echo "Error: No options passed"
    exit 1

fi

if [ -z "${__filelist}" ]; then
    echo "Error: No files specified"
    exit 2
fi

echo "${__filelist}" | sed '/^$/d' | sort | uniq | while read __file; do

    if [ "${__bytes}" = '1' ]; then

        echo "${__file} - $(stat "${__file}" -c %s) bytes"

    else

        echo "${__file} - $(stat "${__file}" -c %s | numfmt --to=iec-i)"

    fi

done

exit
