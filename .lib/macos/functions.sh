#!/bin/sh

# Keychain functions
function _keychain_get_password {
    local value
    local item_name

    item_name=$1
    [[ -z $item_name ]] && echo "Keychain item name is missing" && return 1

    value=$(security find-generic-password -w -s $item_name | xxd -p -r \
           | xmllint --xpath '//dict/string/text()' -)
    echo $value
}

# Checksum for directories
function sha256sum-dir {
    local __dir

    __dir=$1
    [[ -z $__dir ]] && __dir="."

    find -s $__dir -type f -exec shasum -a 256 {} \; | shasum -a 256
}
