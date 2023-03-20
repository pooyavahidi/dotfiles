#!/bin/sh

# Keychain functions
function keychain-get-password() {
    local __value
    local __item_name
    local __item_info

    [[ -z "${__item_name:=$1}" ]] \
        && __err "Keychain item name is not provided" && return 1

    __item_info=$(security find-generic-password -s $__item_name)
    (( $? != 0 )) && return 1

    # Check if the item is a Secure Note or a Password
    if echo $__item_info | grep '"type".*"note"' &> /dev/null; then
        # Secure Note
        __value=$(security find-generic-password -w -s $__item_name | xxd -p -r \
            | xmllint --xpath '//dict/string/text()' -)
    else
        # Password
        __value=$(security find-generic-password -w -s $__item_name)
    fi

    (( $? != 0 )) && return 1

    echo $__value
}
