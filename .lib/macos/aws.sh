#!/bin/sh

# Get aws credentials from a keychain item and set them to the env variables.
# Id and Key are stored in two lines. Line 1 is Id and line 2 is the Key.
function aws-set-creds-from-keychain {
    local __creds
    local __access_key_id
    local __secret_access_key
    local __keychain_item_name

    __keychain_item_name=$1
    [[ -z $__keychain_item_name ]] \
        && echo "keychain item name is not provided" && return 1

    __aws_load_original_env_variables

    # If after loading the original variables, credentials are still empty,
    # read them from the keychain.
    if [[ -z $AWS_ACCESS_KEY_ID ]]; then
        __creds=$(_keychain_get_password $__keychain_item_name)
        __access_key_id=$(echo $__creds | awk 'FNR==1')
        __secret_access_key=$(echo $__creds | awk 'FNR==2')

        export AWS_ACCESS_KEY_ID=$__access_key_id
        export AWS_SECRET_ACCESS_KEY=$__secret_access_key

        __aws_set_original_env_variables
    fi
}
