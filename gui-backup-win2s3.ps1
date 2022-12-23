# Menu Radio Button Function

. .\PS-Forms.ps1
. .\backup-win2s3.ps1

$fail_flag=0
$temp_folder = "c:\temp\win2s3"

# ------------------

" 
    Function: Backup"


$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = "Select the local source folder to backup"
[void]$FolderBrowser.ShowDialog()

if ($($FolderBrowser.SelectedPath) -eq "") {$fail_flag = 1}


"      Source: `"$($FolderBrowser.SelectedPath)`""


if ($fail_flag -eq 0) {

	# Get Buckets

	$list = $(aws s3api list-buckets --output json | convertfrom-json).buckets.name
	$bucket = Get-FormArrayItem $list -dialogTitle "Select the S3 Bucket to backup to"


	}



if ($fail_flag -eq 0) {

"      Bucket: $bucket
 Temp Folder: $temp_folder"

backup-win2s3 $bucket $($FolderBrowser.SelectedPath) $temp_folder

	
} else {

"

      Program cancelled by user.

"


}
