
. .\PS-Forms.ps1
. .\restore-win2s3.ps1

# ------------
# Check if this logged in user is an admin. If not, exit.

		clear
		
		$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		if (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

			write-host -foregroundcolor yellow "

	   Error: This user account " -nonewline

			write-host -foregroundcolor white "($(type env:userdomain)\$(type env:username))" -nonewline
			write-host -foregroundcolor yellow " is not an administrator."

			"
		  The User doing a restore must be an administrator.  
	  
		  This is required to set object ownership permissions with ICACLS.exe
				  
			"

			write-host -foregroundcolor cyan "    Press Any Key to Exit this script...


"

			#pause
			$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
			exit	
	
		}


# ------------

"






      Function: Restore"

$fail_flag=0

# Get Buckets
$list = $(aws s3api list-buckets --output json | convertfrom-json).buckets.name
$bucket = Get-FormArrayItem $list -dialogTitle "Select the S3 Bucket to restore from"
"        Bucket: $bucket"

# Get Restore Points in bucket
$restore_point_list = $($(aws s3api list-objects --bucket $bucket --prefix "metadata" --output json | convertfrom-json).contents | where {$_.Key -match "s3api_file_list.json"}).key.replace("metadata/","").replace("/s3api_file_list.json","")
$list = $restore_point_list
$folder = Get-FormArrayItem $list -dialogTitle "Select the file system restore point to restore from"
"        Folder: $folder"
	
# Get Points in Time in Restore Point
$version_list = aws s3api list-object-versions --bucket $bucket --prefix "metadata/$folder/s3api_file_list.json" --output json | convertfrom-json
# list of versions from selected core files. (The point in time to restore from)
$temp = $($version_list.versions).lastmodified | sort -descending
$list = $temp

		$list_translate = foreach ($item in $list) {
			
			[PSCustomObject]@{
				UTC = $item
				Human = $([DateTime]$item).tostring("r")
				}

			
		}

		$list = $list_translate.human
		$temp = Get-FormArrayItem $list -dialogTitle "Select the point in time to restore from"
		
			
		$point_in_time_date = $($list_translate | ? {$_.human -eq $temp}).UTC
" Point in Time: $point_in_time_date"
		

if ($fail_flag -eq 0) {
	
		$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
		$FolderBrowser.Description = "Restore-Win2S3: Select the local destination to restore the backup to:"
		[void]$FolderBrowser.ShowDialog()
"    Extract to: `"$($FolderBrowser.SelectedPath)`""
		
		if ($($FolderBrowser.SelectedPath) -eq "") {$fail_flag = 1}

	}



if ($fail_flag -eq 0) {

	restore-win2s3 $bucket $folder $($FolderBrowser.SelectedPath) $point_in_time_date
	
} else {

"

      Program cancelled by user.

"


}
