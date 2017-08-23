#!/bin/bash

__filelist=''

__files_specified='0'

__bytes='0'

__sort_name='0'

__sort_size='0'

__reverse='0'

__total='0'

__stop_options='0'

__usage () {
echo "<FILE(s)> | ${0} <OPTIONS> <FILE(s)>

Prints the file size of all given files (including piped).
Use -- to stop processing options.

Options:
  -h   -? --help         This help message
  -b   --byte            Print the file size in bytes
  -n   --name            Sort the files in order of name
  -s   --size            Sort the files in order of size
  -r   --reverse         Reverse the order of the listed files
  -t   --total           Print total size of listed files\
"
}

__size () {
stat "${1}" -c %s
}

__check_input () {

case "${1}" in

    "-h" | "--help" | "?")
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

    "-t" | "--total")
        __total='1'
        ;;

    "--")
        __stop_options='1'
        ;;

    *)
        echo "Invalid option \"${1}\" passed."
        exit
        ;;
esac

}

__process_option () {

if grep '^--.*' <<< "${1}" &> /dev/null && [ "${__stop_options}" = '0' ]; then

    __check_input "${1}"

elif grep '^-.*' <<< "${1}" &> /dev/null && [ "${__stop_options}" = '0' ]; then

    __letters="$(cut -c 2- <<< "${1}" | sed 's/./& /g')"

    for __letter in ${__letters}; do

        __check_input "-${__letter}"

    done

else
    __files_specified='1'
    if ! [ -e "${1}" ]; then
        echo "File \"${1}\" does not exist "
    elif ! [ -r "${1}" ]; then
        echo "File \"${1}\" is not readable"
    elif ! [ -d "${1}" ]; then
        __filelist="${__filelist}
${1}"
    fi
fi

}

if ! [ "${#}" = 0 ]; then

    while ! [ "${#}" = '0' ]; do

        __process_option "${1}"

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

if read -t 0; then
    __filelist+="
$(cat)"
fi

if [ -z "${__filelist}" ]; then
    if [ "${__files_specified}" = '0' ]; then
        __filelist="$(find . -maxdepth 1 -type f | sed 's/^\.\///' | sort)"
    else
        echo "No valid files listed."
        exit
    fi
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
        cat | sort -g
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

if [ "${__total}" = '1' ]; then
    echo

    __total_size="$(echo "${__filelist}" | sed '/^$/d' | while read -r __file; do
        echo -n "$(__size "${__file}")+"
    done | sed 's/+$/\n/' | bc)"

    if [ "${__bytes}" = '1' ]; then

        echo "${__total_size} bytes - Total"

    else

        echo "$(echo ${__total_size} | numfmt --to=iec-i) - Total"

    fi

fi

exit
