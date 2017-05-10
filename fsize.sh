#!/bin/bash

__filelist=''

__files_specified='0'

__bytes='0'

__sort_name='0'

__sort_size='0'

__reverse='0'

__usage () {
echo "${0} <OPTIONS> <FILE(s)>

Prints the file size of all given files

Options:
  -h   -? --help         This help message
  -b   --byte            Print the file size in bytes
  -n   --name            Sort the files in order of name
  -s   --size            Sort the files in order of size
  -r   --reverse         Reverse the order of the listed files\
"
}

__size () {
stat "${1}" -c %s
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
                __sort_size='0'
                __sort_name='1'
                ;;

            "-s" | "--size")
                __sort_size='1'
                __sort_name='0'
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

if [ "${__sort_name}" = '1' ]; then
    cat | sort | uniq
else
    cat
fi

) | while read __file; do

    if [ "${__bytes}" = '1' ]; then

        echo "$(__size "${__file}") bytes - ${__file}"

    else

        echo "$(__size "${__file}" | numfmt --to=iec-i) - ${__file}"

    fi

done | (

if [ "${__sort_size}" = '1' ]; then
    cat | (

    if [ "${__bytes}" = '1' ]; then
        cat | sort
    else
        cat | sort -h
    fi

    ) | tac
else
    cat
fi

) | (

if [ "${__reverse}" = '1' ]; then
    tac
else
    cat
fi

)

exit
