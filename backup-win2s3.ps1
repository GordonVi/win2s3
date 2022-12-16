function backup-win2s3($bucket,$target,$local_temp_folder) {
	
	$target_bucket_subfolder_name = $target.replace("\","/").replace(":","")

	# make the temp folder, this temp folder stages the meta data files
	# https://stackoverflow.com/questions/16906170/create-directory-if-it-does-not-exist
	md -Force $local_temp_folder | out-null

	# Write Meta Files in local temp folder
	aws s3 sync "$target" "s3://$bucket/files/$target_bucket_subfolder_name/" --delete --dryrun > "$local_temp_folder\aws_s3_dryrun.txt"
	icacls "$target" /save "$local_temp_folder\icacls.txt" /t /c | out-null

	# generate a list of files and folders from powershell
	# this is how we know what empty directories exist and to recreate.
	# --------------------------------

		$list = $(gci $target -recurse -force) | select name, PSIsContainer, mode, length, CreationTimeUTC, LastWriteTimeUTC, isreadonly, directoryname, fullname

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


	aws s3 sync "$target" "s3://$bucket/files/$target_bucket_subfolder_name/" --delete  | out-null

	aws s3api list-objects-v2 --bucket $bucket --prefix "files/$target_bucket_subfolder_name" --output json > "$local_temp_folder\s3api_file_list.json"
	aws s3 sync "$local_temp_folder" "s3://$bucket/metadata/$target_bucket_subfolder_name/" | out-null

	# remove the temp folder
	# https://stackoverflow.com/questions/7909167/how-to-quietly-remove-a-directory-with-content-in-powershell
	rm $local_temp_folder -r -force  | out-null

}
