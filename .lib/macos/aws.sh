#######################################
# aliases
#######################################
alias aws-auth="aws::auth_using_keychain"


#######################################
# functions
#######################################
# Get aws credentials from a keychain item and set them to the env variables.
# Store the Key and Id in two lines:
# Line1: ACCESS_KEY_ID
# Line2: SECRET_ACCESS_KEY
function aws::get_creds_from_keychain() {
    local __creds
    local __keychain_item_name

    [[ -z "${__keychain_item_name:=$1}" ]] \
        && __err "Keychain item name is not provided" && return 1

    __creds=$(keychain-get-password $__keychain_item_name)
    (( $? != 0 )) && return 1

    export AWS_ACCESS_KEY_ID=$(echo $__creds | awk 'FNR==1')
    export AWS_SECRET_ACCESS_KEY=$(echo $__creds | awk 'FNR==2')
}

function aws::auth_using_keychain() {
    local __keychain_item
    local __session_duration

    # Parse parameters
    while [[ -n "$1" ]]; do
        case $1 in
            -d | --duration)
                shift
                __session_duration=$1
                ;;
            -i | --keychain-item)
                shift
                __keychain_item=$1
        esac
        (( $# > 0 )) && shift
    done

    [[ -z "${__session_duration}" ]] \
        && [[ -z "${__session_duration:=$AWS_SESSION_TOKEN_DURATION}" ]] \
        && __session_duration=900

    # AWS_USER_ORIGINAL env variable is used when assuming roles or get sts
    # session tokens. It helps to know who was the original user before getting
    # the temp token.
    if [[ -z $AWS_USER_ORIGINAL ]]; then
        # Load the creds from keychain and set them to the env variables.
        aws::get_creds_from_keychain $__keychain_item

        if (( $? != 0 )); then
            __err Cannot read $__keychain_item from the Keychain
            return 1
        fi

        # Set the creds as original
        aws::set_original_env_variables
        export AWS_USER_ORIGINAL=$(aws::current_mfa_serial_number)
        export AWS_SESSION_TOKEN_DURATION=$__session_duration

    else
        # Load the original credentials from the env variables.
        aws::load_original_env_variables
    fi

    aws::sts_session_token \
        -d $AWS_SESSION_TOKEN_DURATION \
        -s $AWS_USER_ORIGINAL
}
