$target = "C:\Users\gordon\Desktop" #\powershell\files"
$bucket_prefix="novermber2022demo"
$bucketname = "$bucket_prefix".ToLower()
$local_temp_folder = "c:\temp\win2s3"

# --------------------------------

$target_bucket_subfolder_name = $target.replace("\","/").replace(":","")


# Write Meta Files in local temp folder
aws s3 sync "$target" "s3://$bucketname/files/$target_bucket_subfolder_name/" --delete --dryrun > "$local_temp_folder\aws_s3_dryrun.txt"
icacls "$target" /save "$local_temp_folder\icacls.txt" /t /c

# generate a list of files and folders from powershell
# this is how we know what empty directories exist and to recreate.
# --------------------------------

	$list = $(gci $target -recurse) | select name, PSIsContainer, length, CreationTimeUTC, LastWriteTimeUTC, isreadonly, directoryname, fullname

# ---

	# Add Recursive file count per folder
		$combined_list = foreach ($item in $list) {

		$OutputItem = $item
		
		if ($item.PSIsContainer -eq 1) {
			
			$OutputItem | Add-Member -NotePropertyName "recurse_file_count" $(gci $item.fullname -recurse | where PSIsContainer -eq 0).count
	
		}

		$OutputItem
	}

# ---

	$combined_list | convertto-json | out-file "$local_temp_folder\file_list.powershell.json"

# --------------------------------


aws s3 sync "$target" "s3://$bucketname/files/$target_bucket_subfolder_name/" --delete

aws s3api list-objects-v2 --bucket mtha-acronis --profile acronis --prefix "s3://$bucketname/files/$target_bucket_subfolder_name/" --output json > "$local_temp_folder\s3api_file_list.json"
aws s3 sync "$local_temp_folder" "s3://$bucketname/metadata/$target_bucket_subfolder_name/" --delete
