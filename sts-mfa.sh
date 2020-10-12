#!/bin/bash
#Check that AWS CLI is installed
AWS_CLI=`which aws`

if [ $? -ne 0 ]; then
  echo "AWS CLI is not installed; exiting"
  exit 1
else
  echo "Using AWS CLI found at $AWS_CLI"
fi

function usage () {
  echo "A Shell script to obtain temporary credentials with MFA"
  echo ""
  echo "Usage: $0 --user <AWS_IAM_USERNAME> --token <MFA_TOKEN> --profile <AWS_CLI_PROFILE> [Optional]"
  echo ""
  echo "Example: $0 --user Bob --token 012345"
  echo "         or"
  echo "         $0 --user Bob --token 012345 --profile Bob"
  echo "Arguments:"
  echo "   -u | --user : AWS IAM username to obtain MFA ARN for"
  echo "   -t | --token : OTP from MFA device"
  echo "   -p | --profile : aws-cli profile usually in $HOME/.aws/config"
  echo "   -d | --duration : Duration of temporary AWS credentials in seconds"
  echo "   -h | --help : Command Usage"
}
# Check that there is at least one argument
if [[ $# -lt 2 && -gt 8 ]]; then
  usage
  exit 2
fi

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

function getMFA_ID () {
  if test -z "$USERNAME" ; then
    echo  "You need to specify an AWS IAM user with -u or --user flag"
    usage
  fi
  if test -z "$PROFILE" ; then
    MFA_ARN=$(aws iam list-mfa-devices --user-name $USERNAME | jq -r '.MFADevices[] | .SerialNumber')
  else
    MFA_ARN=$(aws iam list-mfa-devices --user-name $USERNAME --profile $PROFILE | jq -r '.MFADevices[] | .SerialNumber')
  fi
}

function getSTS_Credentials () {
  echo "Setting Temporary Credentials ....."
  if test -z "$PROFILE" ; then
    aws sts get-session-token --serial-number $MFA_ARN --token-code $TOKEN > /tmp/cred.json
  else
    if test -z "$DURATION" ; then
      aws sts get-session-token --profile $PROFILE --serial-number $MFA_ARN --token-code $TOKEN > /tmp/cred.json
    else
      aws sts get-session-token --profile $PROFILE --duration-seconds $DURATION --serial-number $MFA_ARN --token-code $TOKEN  > /tmp/cred.json
    fi
  fi
  AccessKeyId=$(cat /tmp/cred.json | jq -r '.Credentials | .AccessKeyId')
  SecretAccessKey=$(cat /tmp/cred.json  | jq -r '.Credentials | .SecretAccessKey')
  SessionToken=$(cat /tmp/cred.json | jq -r '.Credentials | .SessionToken')
  if [[ -z "$AccessKeyId" || -z "$SecretAccessKey" || -z "$SessionToken" ]] ; then
    echo  "Error setting temporary credentials"
  else
    echo "Temporary credentials for $USERNAME have been set as environment variables"
  fi
}

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -u | --user)
      shift
      if test $# -gt 0; then
        export USERNAME=$1
      else
        echo "no IAM user specified"
        exit 1
      fi
      shift
      ;;
    -t | --token)
      shift
      if test $# -gt 0; then
        export TOKEN=$1
      else
        echo "no MFA token specified"
        exit 1
      fi
      shift
      ;;
    -p | --profile)
      shift
      if test $# -gt 0; then
        export PROFILE=$1
      else
        echo "no AWS Profile specified"
        exit 1
      fi
      shift
      ;;
    -d | --duration)
      shift
      if test $# -gt 0; then
        export DURATION=$1
      else
        echo "no duration specified"
        exit 1
      fi
      shift
      ;;
    *)
      echo "$1 is not a recognized argument!"
      break
      ;;
  esac
done

echo $TOKEN

echo "Obtaining MFA ARN ....."
getMFA_ID
echo $MFA_ARN
echo "Fetching Temporary Credentials ....."
getSTS_Credentials
export AWS_ACCESS_KEY_ID=$AccessKeyId
export AWS_SECRET_ACCESS_KEY=$SecretAccessKey
export AWS_SESSION_TOKEN=$SessionToken

rm /tmp/cred.json
