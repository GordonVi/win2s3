# Menu Radio Button Function

. .\menu.ps1
. .\backup-win2s3.ps1

$fail_flag=0
$temp_folder = "c:\temp\win2s3"

# ------------------

$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = "Backup-Win2S3: Select the local source folder to backup"
[void]$FolderBrowser.ShowDialog()

if ($($FolderBrowser.SelectedPath) -eq "") {$fail_flag = 1}



if ($fail_flag -eq 0) {

	# Get Buckets

	$list = $(aws s3api list-buckets --output json | convertfrom-json).buckets.name
	$temp = menu("Backup-Win2S3: Select the S3 Bucket to backup to")

	if ($temp[0] -eq "yes") {
		$bucket = $temp[1]
		} else {$fail_flag = 1}
	
	

	}



if ($fail_flag -eq 0) {

" 

      Bucket: $bucket
      Source: `"$($FolderBrowser.SelectedPath)`"
 Temp Folder: $temp_folder


"

backup-win2s3 $bucket $($FolderBrowser.SelectedPath) $temp_folder

	
} else {

"

      Program cancelled by user.

"


}
