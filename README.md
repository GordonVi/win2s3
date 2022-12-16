# Win2S3
## _A Powershell frontend for AWS CLI_
https://github.com/GordonVi/win2s3/

![win2s3](http://virasawmi.com/gordon/images/win2s3.jpg)

Win2S3 is a collection of Powershell scripts to make backing up and restoring files to Windows easy

- Uses AWS CLI, icacls.exe, and Powershell
- Doesn't require admin in backup
- Works with proxies

## Features

- Quick Backup using "AWS CLI s3 sync"
- Backs up Windows File Permissions, Read Only attribute, Hidden Item flag, and file dates
- Supports Point in Time Restore
- No License, free to use for anything

## The Koan that got me to make this

_ChatGPT writes a koan about s3 backup and a lack of good backup clients for windows_

> A wise Zen master once said, "The true value of a backup is not in its creation, but in its restoration."

> One of the disciples asked, "But master, what if there are no good backup clients for our operating system?"

> The Zen master replied, "Then you must become the backup client. You must take responsibility for your own data and ensure that it is properly backed up, even if it means creating your own solution."

> The disciple was enlightened.

Win2S3 was [born from my frustration of a lack of a simple and free backup client for Windows to S3.](https://old.reddit.com/r/aws/comments/yxy9cp/windows_server_backup_to_s3_via_proxy/) 


## Installation

Drop the files in a folder and run "gui-win2s3.ps1"

## Plugins

This requires the AWS CLI installed and configured.

This mean:

- Run "aws configure"
- Make sure the attached account has permissions to your bucket
- if you use a proxy, set your proxy using the SETX command in Powershell

## Development

Just 1 guy.


## License

None

**Free Software, Hell Yeah!**

## What should my IAM Permission look like?

#### Create a policy

In AWS > IAM > Policies.

Click "Create Policy."
Paste this JSON into the Permissions:

--------------------
_Notice that I have a single bucket named "version-enabled-bucket" included. Also, all buckets that begin with the prefix "win2s3--" are included. This is how you control AWS to enforce what buckets have permissions._ 

_The "ListAllMyBuckets" permission is not a mistake. To find the right bucket, AWS only allows you to see (but not read or write in) all buckets. This is an AWS thing._

--------------------

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:DeleteObject",
                "s3:DeleteBucketPolicy",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectVersion",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::version-enabled-bucket",
                "arn:aws:s3:::version-enabled-bucket/*",
                "arn:aws:s3:::win2s3--*"
            ],
            "Condition": {}
        },
        {
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        }
    ]
}
```

# Give me a quick list of how to setup AWS S3 and this script from scratch

- Sign up for AWS with a credit card at https://aws.amazon.com/resources/create-account/

- #### Setup MFA (Multi Factor Authorization with Google Authenticator)
- Create a user
- Create a Key / Secret for API access

- #### Create an IAM policy (permissions) with the policy template from above
- Attach that Policy (permissions) to a Role
- Attach that Role to a Group
- Add your created user to that group OR attach the policy to your User

- #### In AWS, go to the S3 Section
- Create a bucket, make sure to enable versioning
- Do not enable public viewing
- I recommend having a common prefix for your backup buckets with 2 dashes. Like "win2s3--"

- #### Install AWS CLI on your Windows PC
- Open Powershell
- Type "aws configure"
- Enter your key/secret

## Now, you can run the script. It will see your bucket. Start with making your first backup.
