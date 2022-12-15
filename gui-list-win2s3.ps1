# Menu Radio Button Function

. .\menu.ps1
. .\list-win2s3.ps1

# Get Buckets
$restore_target = "C:\temp\restore" # this is where you are dumping the restore data
$fail_flag=0

$list = $(aws s3api list-buckets --output json | convertfrom-json).buckets.name
$temp = menu("List-Win2S3: Select the S3 Bucket to list from")

if ($temp[0] -eq "yes") {
	
	$bucket = $temp[1]

	# Get Restore Points in bucket
	$restore_point_list = $($(aws s3api list-objects --bucket $bucket --prefix "metadata" --output json | convertfrom-json).contents | where {$_.Key -match "s3api_file_list.json"}).key.replace("metadata/","").replace("/s3api_file_list.json","")
	$restore_point_list
	$list = $restore_point_list

	$temp = menu("List-Win2S3: Select the file system restore point to list from")
	
	if ($temp[0] -eq "yes") {
		
		$folder = $temp[1]
	
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
		$temp = menu("List-Win2S3: Select the point in time to list from")
		
		if ($temp[0] -eq "yes") {
			
			$point_in_time_date = $($list_translate | ? {$_.human -eq $temp[1]}).UTC
		
		} else {$fail_flag = 1}
	} else {$fail_flag = 1}
} else {$fail_flag = 1}
	


" 

  Fail: $fail_flag
Bucket: $bucket
Folder: $folder
  PITR: $point_in_time_date
  

  "


if ($fail_flag -eq 0) {
	
	list-win2s3 $bucket $folder $point_in_time_date
	
	}
