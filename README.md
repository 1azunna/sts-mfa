# STS-MFA

A simple script to generate temporary aws credentials with mfa.

# Installation
To be able to execute the script from any location, execute
```
chmod +x sts-mfa/sts-mfa.sh
ln -s sts-mfa/sts-mfa.sh /usr/local/bin/sts-mfa.sh
echo PATH=~/sts-mfa/ >> /etc/environment
```
# Usage

```
Usage: sts-mfa.sh --user <AWS_IAM_USERNAME> --token <MFA_TOKEN> --profile <AWS_CLI_PROFILE> [Optional]

Example: sts-mfa.sh --user Bob --token 012345
         or
         sts-mfa.sh --user Bob --token 012345 --profile Bob
Arguments:
   -u | --user : AWS IAM username to obtain MFA ARN for
   -t | --token : OTP from MFA device
   -p | --profile : aws-cli profile 
   -d | --duration : Duration of temporary AWS credentials in seconds
   -h | --help : Command Usage
```

