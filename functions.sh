#
# aws-cli-multi-account-sessions/functions.sh
#
# bash functions to help run aws-cli commands across roles in multiple
# accounts with MFA
#
# See also: https://github.com/alestic/aws-cli-multi-account-sessions
# See also: https://alestic.com/2019/12/aws-cli-across-organization-accounts/
#

#
# Get temporary session credentials with MFA. These are used to
# generate temporary assume-role credentials for different
# accounts/roles without having to re-enter MFA tokens for each.
#
aws-session-init() {
  # Sets: source_access_key_id source_secret_access_key source_session_token
  local source_profile=${1:-${AWS_SESSION_SOURCE_PROFILE:?source profile must be specified}}
  local mfa_serial=${2:-$AWS_SESSION_MFA_SERIAL}
  local token_code=
  local mfa_options=
  if [ -n "$mfa_serial" ]; then
    read -s -p "Enter MFA code for $mfa_serial: " token_code
    echo
    mfa_options="--serial-number $mfa_serial --token-code $token_code"
  fi
  read -r source_access_key_id \
          source_secret_access_key \
          source_session_token \
    <<<$(aws sts get-session-token \
           --profile $source_profile \
           $mfa_options \
           --output text \
           --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]')
}

#
# Get temporary assume-role credentials for a specific account/role,
# using the temporary session credentials from aws-session-init above.
#
aws-session-set() {
  # Sets: aws_access_key_id aws_secret_access_key aws_session_token
  local account=$1
  local role=${2:-$AWS_SESSION_ROLE}
  local name=${3:-aws-session-access}
  read -r aws_access_key_id \
          aws_secret_access_key \
          aws_session_token \
    <<<$(AWS_ACCESS_KEY_ID=$source_access_key_id \
         AWS_SECRET_ACCESS_KEY=$source_secret_access_key \
         AWS_SESSION_TOKEN=$source_session_token \
         aws sts assume-role \
           --role-arn arn:aws:iam::$account:role/$role \
           --role-session-name "$name" \
           --output text \
           --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]')
  test -n "$aws_access_key_id" && return 0 || return 1
}

#
# Run an AWS command using the temporary assume-role credentials from
# aws-session-set above.
#
aws-session-run() {
  AWS_ACCESS_KEY_ID=$aws_access_key_id \
  AWS_SECRET_ACCESS_KEY=$aws_secret_access_key \
  AWS_SESSION_TOKEN=$aws_session_token \
    "$@"
}

#
# Clear out temporary credentials for security.
#
aws-session-cleanup() {
  unset source_access_key_id source_secret_access_key source_session_token
  unset    aws_access_key_id    aws_secret_access_key    aws_session_token
}
