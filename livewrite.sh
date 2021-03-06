#!/bin/bash

__old_ifs="${IFS}"
IFS="
"

__old_columns="${COLUMNS}"
COLUMNS='1'

function cleanup () {
IFS="${__old_ifs}"
COLUMNS="${__old_columns}"
}

PS3="Choose your image:"
__options="$(ls -1 | grep '\.')
Exit"
select __file in ${__options}; do
case ${__file} in
    "Exit")
        echo "Exiting"
        cleanup
        exit 0
        ;;
    *)
        __selected_file="${__file}"
        break
        ;;
esac
done

echo

PS3="Select your device
(Make sure it is not mounted):"
__options="$(lsblk -dn -o NAME,SIZE,MODEL,LABEL)
Exit"
select __device in ${__options}; do
case ${__device} in
    "Exit")
        echo "Exiting"
        cleanup
        exit 0
        ;;
    *)
        __selected_device="${__device}"
        break
        ;;
esac
done

__real_device="$(echo "${__selected_device}" | sed 's/ .*//')"

__curr_device="$(df "${PWD}" | tail -n 1 | sed 's/ .*//' | sed 's/\/dev\///' | sed "s/[0-9]$//")"

if [ ! -z "$(mount | grep "/dev/${__real_device}")" ]; then
    echo "Selected device is mounted, aborting."
    cleanup
    exit 1
fi

echo "
About to write ${__selected_file} to /dev/${__real_device}
Is this correct?
"

PS3="Select your answer:"

select __yn in "Yes" "No"; do
    case ${__yn} in
        "Yes")
            break
            ;;
        "No")
            echo "Exiting"
            cleanup
            exit 0
            ;;
    esac
done

echo



if which pv &> /dev/null; then
    dd status=none if="${__selected_file}" | pv -s $(stat -c %s "${__selected_file}") | sudo dd status=none of="/dev/${__real_device}"
else
    __check="$(echo "$(dd --version | head -n 1 | sed 's/.* //')>=8.25")"
    if [ "$(echo "${__check}" | bc)" = '1' ]; then
        sudo dd if="${__selected_file}" of="/dev/${__real_device}" status=progress
    else
        sudo dd if="${__selected_file}" of="/dev/${__real_device}" status=none
    fi
fi

sync

cleanup

exit
