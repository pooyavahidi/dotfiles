#!/bin/sh

# Keychain functions
function keychain-get-password {
    local value
    local item_name

    [[ -z "${item_name:=$1}" ]] \
        && echo "Keychain item name is not provided" && return 1

    value=$(security find-generic-password -w -s $item_name | xxd -p -r \
           | xmllint --xpath '//dict/string/text()' -)

    (( $? != 0 )) && return 1

    echo $value
}
