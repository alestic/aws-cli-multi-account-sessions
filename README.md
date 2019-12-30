# aws-cli-multi-account-sessions

bash functions to help run aws-cli commands across roles in multiple
accounts with MFA

## Blog Post

For more background information and explaination for how to use this,
please read this blog post:

> <https://alestic.com/2019/12/aws-cli-across-organization-accounts/>

## Setup

You didn't read that, did you?

Ok, here are the quick notes I use to set this up and use it in my
accounts.

Clone this repo wherever you like:

    mkdir -p $HOME/src && (
      cd     $HOME/src &&
      git clone git@github.com:alestic/aws-cli-multi-account-sessions.git
    )

Add something like this to `$HOME/.bashrc` using the values for
`source_profile` and `mfa_serial` from your aws-cli config file.

    # https://github.com/alestic/aws-cli-multi-account-sessions
    test -x $HOME/src/aws-cli-multi-account-sessions/functions.sh &&
     source $HOME/src/aws-cli-multi-account-sessions/functions.sh
    export AWS_SESSION_SOURCE_PROFILE=your_aws_cli_source_profile
    export AWS_SESSION_MFA_SERIAL=arn:aws:iam::YOUR_ACCOUNT:mfa/YOUR_USER

    source $HOME/.bashrc

## Usage

Specify the role you can assume in all accounts:

    role="admin" # Yours might be called "OrganizationAccountAccessRole"

Get a list of all accounts in the AWS Organization:

    accounts=$(aws organizations list-accounts \
      --output text \
      --query 'Accounts[].[JoinedTimestamp,Status,Id,Email,Name]' |
      grep ACTIVE |
      sort |
      cut -f3) # just the ids
    echo "$accounts"

Run once to create temporary session credentials with MFA:

    aws-session-init

Iterate through AWS accounts, running AWS CLI commands in each
account/role:

    for account in $accounts; do
      aws-session-set $account $role || continue

      this_account=$(aws-session-run \
                       aws sts get-caller-identity \
                         --output text \
                         --query 'Account')
      echo "Account: $account ($this_account)"

      aws-session-run aws s3 ls
    done

Clear out bash variables holding temporary credentials:

    aws-session-cleanup

Of course, this might not work for you if you don't have things set up
quite the same way as me. Perhaps you should go back and read the blog
post above?

## Author

Eric Hammond
<https://twitter.com/esh>

## Credit

All the good in this is based on example code from Jennine
Townsend. All the bad is mine.
