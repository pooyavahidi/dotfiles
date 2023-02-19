#!/bin/sh

# Get aws credentials from a keychain item and set them to the env variables.
# Id and Key are stored in two lines. Line 1 is Id and line 2 is the Key.
function aws-set-creds-from-keychain {
    local __creds
    local __keychain_item_name

    __keychain_item_name=$1
    [[ -z $__keychain_item_name ]] \
        && echo "keychain item name is not provided" && return 1

    __creds=$(_keychain_get_password $__keychain_item_name)
    export AWS_ACCESS_KEY_ID=$(echo $__creds | awk 'FNR==1')
    export AWS_SECRET_ACCESS_KEY=$(echo $__creds | awk 'FNR==2')
}
