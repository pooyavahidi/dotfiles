#!/bin/sh

# Get aws credentials from a keychain item and set them to the env variables.
# Store the Key and Id in two lines:
# Line1: ACCESS_KEY_ID
# Line2: SECRET_ACCESS_KEY
function aws::get-creds-from-keychain() {
    local __creds
    local __keychain_item_name

    [[ -z "${__keychain_item_name:=$1}" ]] \
        && echo "Keychain item name is not provided" && return 1

    __creds=$(keychain-get-password $__keychain_item_name)
    (( $? != 0 )) && return 1

    export AWS_ACCESS_KEY_ID=$(echo $__creds | awk 'FNR==1')
    export AWS_SECRET_ACCESS_KEY=$(echo $__creds | awk 'FNR==2')
}
