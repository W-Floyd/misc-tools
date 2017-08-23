#!/bin/bash
# This script helps to automate simple gpg encryption of a folder.

set -e

__intent=''

__should_compress='1'

__base_encrypted_name='encrypt'
__base_decrypted_name='decrypt'

__base_extension='tar'
__compressed_extension="${__base_extension}.gz"

__key_file='key_id'

if [ -e "${__key_file}" ]; then
    __key_id="$(cat "${__key_file}")"
fi

__set_extension () {
if [ "${__should_compress}" = '1' ]; then
    __full_extension="${__compressed_extension}"
else
    __full_extension="${__base_extension}"
fi
}

__announce () {
echo "Info: ${@}"
}

__warn () {
echo "Warning: ${@}"
}

__error () {
echo "Error: ${@}, exiting now."
exit 1
}

__pack () {
tar -cf "${__base_encrypted_name}.${__base_extension}" "${__base_decrypted_name}/"

if [ "${__should_compress}" = '1' ]; then
    gzip -9 "${__base_encrypted_name}.${__base_extension}"
fi
    
}

__unpack () {
if [ "${__existing_extension}" = "${__compressed_extension}" ]; then
    gzip -d "${__base_decrypted_name}.${__existing_extension}"
fi

tar -xf "${__base_decrypted_name}.${__base_extension}"

}

__encrypt () {

__verify_intent

if ! [ -d "${__base_decrypted_name}" ]; then
    __error "Decrypted directory '${__base_decrypted_name}' missing, cannot encrypt"
fi

__pack

gpg --batch --trust-model always -e -r "${__key_id}" "${__base_encrypted_name}.${__full_extension}"

rm -f "${__base_encrypted_name}.${__full_extension}"

rm -f -r "./${__base_decrypted_name}/"

}

__decrypt () {

__verify_intent

if ! ( [ -e "${__base_encrypted_name}.${__base_extension}.gpg" ] || [ -e "${__base_encrypted_name}.${__compressed_extension}.gpg" ] ); then
    __error "Encrypted file 'encrypt.tar.gpg' missing, cannot decrypt"
fi

gpg --quiet --batch --trust-model always -d -r "${__key_id}" -o "${__base_decrypted_name}.${__existing_extension}" "${__base_encrypted_name}.${__existing_extension}.gpg"

rm -f "${__base_encrypted_name}.${__existing_extension}.gpg"

__unpack

rm -f "${__base_decrypted_name}.${__base_extension}"

}

__check () {
if [ -e "${__base_encrypted_name}.${__base_extension}.gpg" ] && [ -e "${__base_encrypted_name}.${__compressed_extension}.gpg" ]; then
    __error "Both a compressed and uncompressed encrypted file exist"
elif [ -d "${__base_decrypted_name}" ] && ( [ -e "${__base_encrypted_name}.${__base_extension}.gpg" ] || [ -e "${__base_encrypted_name}.${__compressed_extension}.gpg" ] ); then
    __error "Both a decrypted directory and encrypted file exist"
elif ! [ -d "${__base_decrypted_name}" ] && ! ( [ -e "${__base_encrypted_name}.${__base_extension}.gpg" ] || [ -e "${__base_encrypted_name}.${__compressed_extension}.gpg" ] ); then
    __error "Please place files in a directory named 'encrypt'"
fi

if [ -e "${__base_encrypted_name}.${__base_extension}.gpg" ]; then
    __existing_extension="${__base_extension}"
elif [ -e "${__base_encrypted_name}.${__compressed_extension}.gpg" ]; then
    __existing_extension="${__compressed_extension}"
fi
}

__check_key () {
if [ -z "${__key_id}" ] && [ "${__intent}" = 'encrypt' ]; then
    __error "A key ID is required to encrypt anything. It must be acceptable by gpg"
fi
}

__verify_intent () {
if [ -z "${__intent}" ]; then
    __error "Intent has not yet been set"
elif [ "${__intent}" = 'decrypt' ] && [ -d "${__base_decrypted_name}" ]; then
    __error "Decrypted directory already exists"
elif [ "${__intent}" = 'encrypt' ] && [ -e 'encrypt.tar.gpg' ]; then
    __error "Encrypted file already exists"
fi
}

__set_intent () {
if [ -z "${__intent}" ]; then
    export __intent="${1}"
    __announce "Will try to ${__intent}"
else
    __error "Intent may not be declared more than once"
fi
}

__usage () {
echo "${0} <OPTIONS>

Encrypt or decrypt a set directory easily, using a set key.
Removes decrypted files when done.

Options:
  -h  -? --help         This help message
  -e  --encrypt         Encrypt the directory
  -d  --decrypt         Decrypt the directory
  
  --key_id=xxxxxxxx     The gpg key to use for encryption.
                        May be stored in file '${__key_file}'\
"
}

__process_option () {

if grep '^--.*' <<< "${1}" &> /dev/null; then

    __check_input "${1}"

elif grep '^-.*' <<< "${1}" &> /dev/null; then

    __letters="$(cut -c 2- <<< "${1}" | sed 's/./& /g')"

    for __letter in ${__letters}; do

        __check_input "-${__letter}"

    done

else
    __check_input "${1}"
fi

}

__check_input () {

case "${1}" in
    '-h' | '--help' | '-?')
        __usage
        exit 0
        ;;

    '-e' | '--encrypt')
        __set_intent 'encrypt'
        ;;

    '-d' | '--decrypt')
        __set_intent 'decrypt'
        ;;

    '-c' | '--compress')
        __should_compress='1'
        __set_extension
        ;;
        
    '--no-compress')
        __should_compress='0'
        __set_extension
        ;;
        
    '--'*'='*)
        export ${1/--/__}
        ;;

    *)
        __error "Invalid option '${1}' specified"
        ;;

esac

}

if ! [ "${#}" = 0 ]; then

    while ! [ "${#}" = '0' ]; do

        __process_option "${1}"

        shift

    done

fi

__check

__set_extension

if [ -z "${__intent}" ]; then
    __announce "No intent given, will guess."
    __check
    if [ -d "${__base_decrypted_name}" ]; then
        __set_intent 'encrypt'
    elif [ -e "${__base_encrypted_name}.${__base_extension}.gpg" ] || [ -e "${__base_encrypted_name}.${__compressed_extension}.gpg" ]; then
        __set_intent 'decrypt'
    else
        __error "Sorry, I didn't check things and something's wrong"
    fi
fi

__check_key

__${__intent}


exit
