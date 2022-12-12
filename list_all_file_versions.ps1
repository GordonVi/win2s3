<#
.SYNOPSIS
  List files in an AWS S3 bucket for Point in Time Restore.
  Works with files uploaded using the AWS CLI using "aws s3 sync"
  This will yeild an array of objects reflecting what you need to restore for a point in time restore from S3.  
  
.DESCRIPTION
  The purpose of this is to get a list of files from a "point in time."
  This "point in time" will be used with an "aws s3api restore-object" foreach/loop.
  The purpose of this is to restore files after a crypto ransomware attack happens. (Ransomware is usually noticed after the malicious software has conpleted it's deed)
  
  Lets say I want to backup a folder: c:\Users\gordon\Desktop
  
  
  After I have AWS CLI and an S3 bucket (november2022demo) setup, I would use the AWS CLi to back it up like this:
  
  - aws s3 sync C:\Users\Gordon\desktop s3://november2022demo/files/ --delete
  
  
  Now, if I wanted to restore the most recent backup, I'd swap the source and destination:

  - aws s3 sync s3://november2022demo/files/ C:\Users\Gordon\desktop --delete
  
  
  But, lets say I was hit with a ransomware and all my files were encrypted or deleted. And... my backup has copied all the encrypted files to s3.
  How to I restore from a "point in time?" This is professionally known as PITR, point in time recovery.
  This script looks at a subfolder in a bucket and reads the AWS metadata of all file   
  

.PARAMETER 
  3 Variables at the top of the script

.INPUTS
  This pulls data from the AWS CLI and parses it
  This requires you to set up the AWS CLI, your account, a user account, connection keys, an S3 Bucket (version enabled), and the IAM Permissions for S3 access > Role > Add said role to user.
  This requires you to type in "aws configure" in the command line and link your access key/secret to your AWS CLI.

.OUTPUTS
  This outputs an array (list) of Objects the reflect the following:

   - Key (File Name)
   - LastModified (Last upload date to S3)
   - VersionID (The VersionID of the file. Used in AWS s3api restore-object)
   - IsLatest (Is this the latest version of the file as of the run of this script)
   - deletemarker (Meta Data. Useful to tell if the last action before the point in time date was a delete.)


.NOTES
  Version:        1.0
  Author:         /u/gordonv
  Creation Date:  12/09/2022
  Purpose/Change: Writing a restore function for Windows Files from S3.
  Site:           https://github.com/GordonVi/win2s3/

.EXAMPLE

Run the PS1 script. It doesn't request prompts. It can be scheduled.

#>

$bucket = "november2022demo" # must be lowercase, AWS rules
$folder = "files" # Case Sensitive

# Standard AWS Date Format ISO 8601) (https://stackoverflow.com/questions/69506719/dealing-with-0000-in-datetime-forma)
$point_in_time_restore_date = "2022-12-12T15:25:00+00:00"

# ------------

# Pull a list of all versions of all files from AWS | convert from json into a powershell object
$list = aws s3api list-object-versions --bucket $bucket --prefix $folder --output json | convertfrom-json

  # If you want to do the whole bucket, not a recursive subfolder. use this line without the --prefix property
  # $list = aws s3api list-object-versions --bucket $bucket --output json | convertfrom-json

# Take the versions and deletemarker arrays and put them in their own variables
$versions      = $list.versions      | select key,lastmodified,versionid,islatest 
$deletemarkers = $list.deletemarkers | select key,lastmodified,versionid,islatest

# Denote what items are delete markers respectfully
$versions      | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name "deletemarker" -Value 0}
$deletemarkers | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name "deletemarker" -Value 1}

# JOIN the 2 identically formatted tables
# | remove anything newer then the point in time date
# |  sort by date
# |  only keep the unique newest entry per file. (remember, we removed anything newer than the point in time before. Now we're trimming the old dates.)
$combined = $versions + $deletemarkers | ? {$_.LastModified -le $point_in_time_restore_date} | sort-object -Property @{Expression = "LastModified"; Descending = $true} | sort-object -unique -Property key

# make a graph showing the new formatted table
$combined | out-gridview