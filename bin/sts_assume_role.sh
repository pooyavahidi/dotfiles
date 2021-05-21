#!/bin/bash

# Input variables
mfa_serial_number=$1 #"arn:aws:iam::trusted_account_id:mfa/myuser"
role_arn=$2 #"arn:aws:iam::trusting_account_id:role/role_name"

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
printf "Enter the MFA code: "; read token_code

# Get the credential
credentials=$(aws sts assume-role \
--role-arn ${role_arn} \
--role-session-name $(date '+%Y%m%d%H%M%S%3N') \
--duration-seconds ${duration_seconds} \
--serial-number ${mfa_serial_number} \
--query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]' \
--output text \
--token-code ${token_code} \
)

# Replace tabs (if there is any) to space, and then split the string by spaces.
export AWS_ACCESS_KEY_ID=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f1)
export AWS_SECRET_ACCESS_KEY=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f2)
export AWS_SESSION_TOKEN=$(echo $credentials | tr -s '\t' ' ' | cut -d' ' -f3)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)

# get caller identity after the assume role
aws sts get-caller-identity

unset credentials
unset mfa_serial_number
unset role_arn
unset token_code
unset duration
unset duration_seconds
