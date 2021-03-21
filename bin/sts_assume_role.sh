#!/bin/bash

# Input variables
mfa_serial_number=$1 #"arn:aws:iam::trusted_account_id:mfa/myuser"
role_arn=$2 #"arn:aws:iam::trusting_account_id:role/role_name"
session_name=$3 #"assumerole_my_session"

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
printf "Enter the MFA code: "; read code
res="$(aws sts assume-role --role-arn $role_arn --role-session-name $session_name --serial-number $mfa_serial_number --token-code $code --duration-seconds $duration_seconds)"

# Parse the json result using python
$(python3 -c "import sys, json; data = json.loads(''.join(sys.argv[1:]));print (f'export AWS_ACCESS_KEY_ID={data[\"Credentials\"][\"AccessKeyId\"]} export AWS_SECRET_ACCESS_KEY={data[\"Credentials\"][\"SecretAccessKey\"]} export AWS_SESSION_TOKEN={data[\"Credentials\"][\"SessionToken\"]}')" $res 2>&1)

# Set the account id to the id of trusting account
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)

# Unset the temp variables
unset mfa_serial_number
unset role_arn
unset session_name
unset code
unset duration
unset duration_seconds
unset res

# get caller identity after the assume role
aws sts get-caller-identity
