# Win2S3
## _A Powershell frontend for backup and restore to S3 using the AWS CLI_
https://github.com/GordonVi/win2s3/

![win2s3](http://virasawmi.com/gordon/images/win2s3.jpg)

Win2S3 is a collection of Powershell scripts to make backing up and restoring files to Windows easy

- Uses AWS CLI, icacls.exe, and Powershell
- Doesn't require admin in backup or list
- Works with proxies

_Win2S3 operates in the same fashion as robocopy, rsync, and such. It's not a drive imager. It can't backup everything from the root._

## Features

- Quick Backup using "AWS CLI s3 sync"
- Backs up Windows File Permissions, Read Only attribute, Hidden Item flag, and file dates. (Important to Windows)
- Supports Point in Time Restore (Important for Ransomware restores and quick incremental backups)
- Works though proxy / proxies like squid and McAfee Security through port 443. 
- Command line commands can be used without the GUI. Great for Task Scheduler Jobs and adding into your own scripts.
- No License, free to use for anything
- Works with folders:
```
c:\Users\EndUser\Desktop
c:\Users\EndUser\Pictures
c:\Users\EndUser\Downloads
```

## Limits
- Will not work with folders like:
```
c:\Users\EndUser
```

## Installation

Drop the files in a folder and run "gui-win2s3.ps1"

## Plugins

This requires the AWS CLI installed and configured.

This mean:

- Run "aws configure"
- Make sure the attached account has permissions to your bucket
- if you use a proxy, set your proxy using the SETX command in Powershell
```
SETX HTTP="http://proxy.fakecompany.com:3124"
SETX HTTPS="http://proxy.fakecompany.com:3124"
```


## Development

Just 1 guy.


## License

- None
- This software uses software from another Github Repo
  - https://github.com/Zerg00s/powershell-forms
  
# Give me a quick list of how to setup AWS S3 and this script from scratch

- #### Sign up for AWS with a credit card at https://aws.amazon.com/resources/create-account/
  - Setup MFA (Multi Factor Authorization with Google Authenticator)
  - _Highly Recommended. Set up "AWS Budgets"_

- #### Create a user
  - _Highly Recommended to name the user something like "service-win2s3"_
  - Create a Key / Secret for API access

- #### In AWS, go to the S3 Section
  - Create a bucket. 
_I recommend having a common prefix for your backup buckets with 2 dashes. Like "win2s3--"_
  - Disable ACLs
  - Block all public access
  - Enable Bucket Versioning
  - Disable encryption. (I haven't worked that into this script. It is possible to do)
  - Advanced > Object Lock. You should enable this. This prevents a hacker from deleting your data if they get onto your PC and steal your AWS key/secret.

- #### Create an IAM policy (permissions) with the policy template from above

## In AWS > IAM > Policies.

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
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectVersion",
                "s3:ListBucket",
                "s3:ListBucketVersions",
                "s3:ListBucketMultipartUploads",
                "s3:ListObjectVersions",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::version-enabled-bucket",
                "arn:aws:s3:::version-enabled-bucket/*",
                "arn:aws:s3:::win2s3--*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        }
    ]
}
```
-
  - Attach that Policy (permissions) to a Role
  - Attach that Role to a Group
  - Add your created user to that group OR attach the policy to your User

- #### Install AWS CLI on your Windows PC
  - Open Powershell
  - Type "aws configure"
  - Enter your key/secret
  - Test if you can reach AWS by typing this into a powershell prompt:
```
aws s3 ls
```

- #### Copy the script files to a folder into your computer
  - Right click and run "gui-win2s3.ps1"
  - To restore, you need to run powershell as an admin. The script will bring a user account control (UAC) dialogue asking for admin privledges. The restore fuction will not continue unless this is satisfied. This is for restoring file permissions using ICACLS.EXE in Windows.

## Now, you can run the script. It will see your bucket. Start with making your first backup.

# The Koan that got me to make this

_ChatGPT writes a koan about s3 backup and a lack of good backup clients for windows_

> A wise Zen master once said, "The true value of a backup is not in its creation, but in its restoration."

> One of the disciples asked, "But master, what if there are no good backup clients for our operating system?"

> The Zen master replied, "Then you must become the backup client. You must take responsibility for your own data and ensure that it is properly backed up, even if it means creating your own solution."

> The disciple was enlightened.

Win2S3 was [born from my frustration of a lack of a simple and free backup client for Windows to S3.](https://old.reddit.com/r/aws/comments/yxy9cp/windows_server_backup_to_s3_via_proxy/) 

