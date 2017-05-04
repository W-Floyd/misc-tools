#!/bin/bash
#
# ... | help_fold.sh fold_size=<NUM> width=<NUM>
#
# fold_size is the size to pad the new help (this needs to be formatted by
# hand), width is the width to fold everything to.
#
################################################################################

for __input in $@; do
    eval "${1}"
    shift
done

__leadin='32'
__width='80'

################################################################################
#
# __print_pad
#
# Prints the given number of spaces.
#
################################################################################

__print_pad () {
seq 1 "${1}" | while read -r __line; do
    echo -n ' '
done
}

################################################################################
#
# ... | __help_fold
#
# Help Fold
# Folds text in a way appropritate for parts of help messages, nothing else.
# Each line gets folded, with the set lead-in added for formatting.
#
################################################################################

__help_fold () {

if [ -z "${fold_size}" ]; then
    __fold_width="${__leadin}"
else
    __fold_width="${fold_size}"
fi

if [ -z "${width}" ]; then
    __wrap_size="${__width}"
else
    __wrap_size="${width}"
fi

local __pipe="$(cat)"

local __pad="$(__print_pad "${__fold_width}")"

while read -r __line; do

    __real_line="$(cut -c "2-" <<< "${__line}")"

    echo -en "$(cut -c "1-${__fold_width}" <<< "${__real_line}")"

    local __loop_num='0'

    cut -c "$((__fold_width+1))-" <<< "${__real_line}" | fold -w "$((__wrap_size-__fold_width))" -s | while read -r __sub_line; do
        if ! [ "${__loop_num}" = 0 ]; then
            echo -n "${__pad}"
        fi
        __loop_num=$((__loop_num+1))
        echo -e "${__sub_line}"
    done

done <<< "$(sed 's/^/_/' <<< "${__pipe}")"

}

################################################################################
#
# ... | __help_unfold
#
# Help unfold
# Unfolds help text, so it can be re-folded.
#
################################################################################

__help_unfold () {

if [ -z "${fold_size}" ]; then
    __unfold_width="${__leadin}"
else
    __unfold_width="${fold_size}"
fi

local __pad="$(__print_pad "${__unfold_width}")"

cat | perl -pe "BEGIN{undef $/;} s#\n${__pad}# #g"

}

cat | __help_unfold | __help_fold

exit
