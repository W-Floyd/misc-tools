#!/bin/bash

__filelist=''

__files_specified='0'

__bytes='0'

__sort='0'

__reverse='0'

__usage () {
echo "${0} <OPTIONS> <FILE(s)>

Prints the file size of all given files

Options:
  -h   -? --help         This help message
  -b   --byte            Print the file size in bytes
  -n   --name            Sort the files in order of name
  -r   --reverse         Reverse the order of the listed files\
"
}

if ! [ "${#}" = 0 ]; then

    while ! [ "${#}" = '0' ]; do

        case "${1}" in

            "-h" | "--help" | "-?")
                __usage
                exit 0
                ;;

            "-b" | "--byte")
                __bytes="1"
                ;;

            "-n" | "--name")
                __sort='1'
                ;;

            "-r" | "--reverse")
                __reverse='1'
                ;;

            *)
                __files_specified='1'
                if ! [ -e "${1}" ]; then
                    echo "File \"${1}\" does not exist"
                elif ! [ -r "${1}" ]; then
                    echo "File \"${1}\" is not readable"
                elif ! [ -d "${1}" ]; then
                    __filelist="${__filelist}
${1}"
                fi
                ;;
        esac

        shift

    done

else

    ls -1 | while read -r __file; do

    if [ -r "${1}" ]; then
        __filelist="${__filelist}
${__file}"
    fi

    done

fi

if [ -z "${__filelist}" ] && [ "${__files_specified}" = '0' ]; then
    echo "Error: No readable files found"
    exit 1
fi

__filelist="$(sed '/^$/d' <<< "${__filelist}")"

echo "${__filelist}" | sed '/^$/d' | (

if [ "${__sort}" = '1' ]; then
    cat | sort | uniq
else
    cat
fi

) | while read __file; do

    if [ "${__bytes}" = '1' ]; then

        echo "${__file} - $(stat "${__file}" -c %s) bytes"

    else

        echo "${__file} - $(stat "${__file}" -c %s | numfmt --to=iec-i)"

    fi

done (

if [ "${__reverse}" = '1' ]; then
    tac
else
    cat
fi

)

exit
