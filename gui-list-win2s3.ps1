. .\PS-Forms.ps1
. .\list-win2s3.ps1

# Get Buckets

$list = $(aws s3api list-buckets --output json | convertfrom-json).buckets.name
$temp =  Get-FormArrayItem $list -dialogTitle "Select the S3 Bucket to list from"

	
	$bucket = $temp

# Get Restore Points in bucket
$restore_point_list = $($(aws s3api list-objects --bucket $bucket --prefix "metadata" --output json | convertfrom-json).contents | where {$_.Key -match "s3api_file_list.json"}).key.replace("metadata/","").replace("/s3api_file_list.json","")
$list = $restore_point_list

$temp = Get-FormArrayItem $list -dialogTitle "Select the file system restore point to list from"
		
		$folder = $temp
	
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
	$temp = Get-FormArrayItem $list -dialogTitle "Select the point in time to list from"

				
				$point_in_time_date = $($list_translate | ? {$_.human -eq $temp}).UTC
		


" 

Bucket: $bucket
Folder: $folder
  PITR: $point_in_time_date
  

  "
	
	list-win2s3 $bucket $folder $point_in_time_date
	
