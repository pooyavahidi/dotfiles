#!/bin/sh

#######################################
# aliases
#######################################
alias aws-whoami="aws sts get-caller-identity"


#######################################
# functions
#######################################

# Get credentials for MFA enabled authentication
function aws-sts-session-token() {
    local credentials
    local mfa_serial_number
    local token_code
    local duration_seconds

    # Parse parameters
    while [[ -n "$1" ]]; do
        case $1 in
            -d | --duration)
                shift
                duration_seconds=$1
                ;;
            -s | --serial)
                shift
                mfa_serial_number=$1
        esac
        [[ $# > 0 ]] && shift
    done

    [[ -z $duration_seconds ]] && duration_seconds=900
    if [[ -z $mfa_serial_number ]]; then
        # Get the current user's mfa serial number
        mfa_serial_number=$(__aws_current_mfa_serial_number $1) || return 1
    fi

    echo Getting session token using mfa: $mfa_serial_number for duration: $duration_seconds seconds.
    # Get the mfa token code
    printf "Enter the MFA code: "; read token_code

    # Get the credential
    credentials=$(aws sts get-session-token \
        --duration-seconds ${duration_seconds} \
        --serial-number ${mfa_serial_number} \
        --token-code ${token_code} \
        --query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]' \
        --output text \
    )

    # Return if the previous command executed with error
    if (( $? != 0 )); then
        echo "Unable to get session token"
        return 1
    fi

    # Replace tabs (if there is any) to space, and then split the string by spaces.
    export AWS_ACCESS_KEY_ID=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f1)
    export AWS_SECRET_ACCESS_KEY=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f2)
    export AWS_SESSION_TOKEN=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f3)
}

# Assume the given role and return credentials
function aws-sts-assume-role() {
    local credentials
    local mfa_serial_number
    local role_arn
    local token_code
    local duration_seconds

    # Parse parameters
    while [[ -n "$1" ]]; do
        case $1 in
            -r | --role-arn)
                shift
                role_arn=$1
                ;;
            -d | --duration)
                shift
                duration_seconds=$1
                ;;
            -s | --serial)
                shift
                mfa_serial_number=$1
        esac
        [[ $# > 0 ]] && shift
    done

    [[ -z $role_arn ]] && echo "role arn is missing" && return 1
    [[ -z $duration_seconds ]] && duration_seconds=900

    # Print the caller identity before assume role
    aws sts get-caller-identity

    echo Assuming role: $role_arn using mfa: $mfa_serial_number for duration: $duration_seconds seconds.

    # Get the credential
    if [[ -n $mfa_serial_number ]]; then
        # If mfa_serial_number is provided, then get the token code
        printf "Enter the MFA code: "; read token_code

        credentials=$(aws sts assume-role \
        --role-arn ${role_arn} \
        --role-session-name $(date '+%Y%m%d%H%M%S%3N') \
        --duration-seconds ${duration_seconds} \
        --serial-number ${mfa_serial_number} \
        --query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]' \
        --output text \
        --token-code ${token_code} \
        )
    else
        credentials=$(aws sts assume-role \
        --role-arn ${role_arn} \
        --role-session-name $(date '+%Y%m%d%H%M%S%3N') \
        --duration-seconds ${duration_seconds} \
        --query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]' \
        --output text \
        )
    fi

    # Return if the previous command executed with error
    if (( $? != 0 )); then
        echo "Unable to get session token"
        return 1
    fi

    # Replace tabs (if there is any) to space, and then split the string by spaces.
    export AWS_ACCESS_KEY_ID=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f1)
    export AWS_SECRET_ACCESS_KEY=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f2)
    export AWS_SESSION_TOKEN=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f3)
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)

    # Print caller identity after the assume role
    aws sts get-caller-identity

}

function aws-list-env-variables {
    echo AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
    echo AWS_REGION=$AWS_REGION
    echo AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
    echo AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
    echo AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
    echo AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
}


# sync workspace directory to the workspace bucket in s3
function s3-upload-ws {
    aws s3 sync ${WORKSPACE} s3://${S3_WS_BUCKET}/ \
        --exclude '*.git/*' \
        --exclude '*.env/*' \
        --exclude '.DS_Store' \
        --delete
}

function s3-upload {
    aws s3 cp $1 s3://${S3_WS_BUCKET}
}

function s3-ls {
    aws s3 ls s3://${S3_WS_BUCKET}
}

function s3-download {
    [[ -z $1 || -z $2 ]] \
        && echo "Usage: s3-download <source> <destination>" \
        && return

    aws s3 sync s3://${S3_WS_BUCKET}/$1 $2
}

# Get aws mfa serial number. If it's not set as an env variable, it gets it
# from the aws sts get-caller-identity
function __aws_current_mfa_serial_number() {
    local mfa_serial_number

    [[ -n "${mfa_serial_number:=$1}" ]] \
    || [[ -n "${mfa_serial_number:=$AWS_MFA_SERIAL_NUMBER}" ]] \
    || mfa_serial_number=$(aws sts get-caller-identity \
                        | grep Arn \
                        | cut -d'"' -f 4 \
                        | sed 's/:user/:mfa/g')

    # If mfa serial number is empty, return with error
    [[ -z "$mfa_serial_number" ]] && echo "mfa serial number is missing" \
        && return 1

    echo $mfa_serial_number
}

# Get current aws username
function __aws_current_user() {
    local iam_user
    iam_user=$(aws sts get-caller-identity \
                | grep Arn \
                | sed 's/.*\/\(.*\)"/\1/') \
    || return 1

    echo $iam_user
}
