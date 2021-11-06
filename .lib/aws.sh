#!/bin/sh


#######################################
# environment variables
#######################################


#######################################
# functions
#######################################

# Get credentials for MFA enabled authentication
function aws-sts-session-token() {
    local credentials
    local mfa_serial_number
    local token_code
    local duration
    local duration_seconds

    # Get the mfa serial number
    mfa_serial_number=$(__get_aws_mfa_serial_number $1) \
    || return 1

    # Reset the environment variables
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
    export AWS_SESSION_TOKEN=

    # Get the session duration and convert it to seconds
    printf "Enter the session duration in hours [default is 1]: "; read duration
    [ -z "$duration" ] && duration=1
    duration_seconds=$(($duration*3600))

    # Get the code and sts token
    printf "Enter the MFA code: "; read token_code

    # Get the credential
    credentials=$(aws sts get-session-token \
        --duration-seconds ${duration_seconds} \
        --serial-number ${mfa_serial_number} \
        --token-code ${token_code} \
        --query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]' \
        --output text \
    )

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
    local __mfa_enabled
    local token_code
    local duration
    local duration_seconds

    # Input variables
    role_arn=$1 #"arn:aws:iam::trusting_account_id:role/role_name"
    mfa_serial_number=$2 #"arn:aws:iam::trusted_account_id:mfa/myuser"

    [[ -z $role_arn ]] && echo "role arn is missing" && return 1
    [[ -n $mfa_serial_number ]] && __mfa_enabled=true

    # Reset the environment variables
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
    export AWS_SESSION_TOKEN=
    export AWS_ACCOUNT_ID=

    # Get the caller identity before assume role
    aws sts get-caller-identity

    # Get the session duration and convert it to seconds
    printf "Enter the session duration in hours [default is 1]: "; read duration
    [ -z "$duration" ] && duration=1
    duration_seconds=$(($duration*3600))

    # Get the code and sts token
    if [[ ${__mfa_enabled} ]]; then
        printf "Enter the MFA code: "; read token_code
    fi

    # Get the credential
    if [[ ${__mfa_enabled} ]]; then
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

    # Replace tabs (if there is any) to space, and then split the string by spaces.
    export AWS_ACCESS_KEY_ID=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f1)
    export AWS_SECRET_ACCESS_KEY=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f2)
    export AWS_SESSION_TOKEN=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f3)
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)

    # get caller identity after the assume role
    aws sts get-caller-identity

}

# Assume role using MFA
function aws-sts-assume-role-mfa() {
    local role_arn
    local mfa_serial_number

    role_arn=$1

    # Get the mfa serial number
    mfa_serial_number=$(__get_aws_mfa_serial_number $2) \
    || return 1

    aws-sts-assume-role $role_arn $mfa_serial_number
}

function aws-sts-session-token-current-user {
    aws-sts-session-token ${AWS_MFA_SERIAL_NUMBER}
}

function aws-user-elevate-to-poweruser {
    aws iam add-user-to-group --user-name $1 --group-name PowerUsers
}

function aws-user-elevate-to-readonly {
    aws iam add-user-to-group --user-name $1 --group-name ReadOnlyUsers
}

function aws-user-elevate-to-admin {
    aws iam add-user-to-group --user-name $1 --group-name Admins
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
function __get_aws_mfa_serial_number() {
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
function __get_aws_current_user() {
    local iam_user
    iam_user=$(aws sts get-caller-identity \
                | grep Arn \
                | sed 's/.*\/\(.*\)"/\1/') \
    || return 1

    echo $iam_user
}
