clear

	$bucket = "your-version-enabled-bucket" # must be lowercase, AWS rules
	$folder = "C/Users/gordon/Desktop"
	$restore_target = "C:\temp\restore"
	$point_in_time_restore_date = "2022-12-13T04:20:31+00:00"

# ------------

    $spot = $folder.split("/").length
	$base_folder = $folder.split("/")[$spot-1] # the last folder in the bucket. This is important for the Win ACL restore

# ------------


	"

	"
	$restore_point_list = $($(aws s3api list-objects --bucket $bucket --prefix "metadata" --output json | convertfrom-json).contents | where {$_.Key -match "s3api_file_list.json"}).key.replace("metadata/","").replace("/s3api_file_list.json","")

	# The list of core root files to restore from. (The location to restore from)
	$restore_point_list


	"

	"

	$version_list = aws s3api list-object-versions --bucket $bucket --prefix "metadata/$folder/s3api_file_list.json" | convertfrom-json

	# list of versions from selected core files. (The point in time to restore from)
	$version_list.versions | sort-object -Property LastModified | select LastModified

	"
	
	----------------------------

	"

# ------------

	# Pull a list of all versions of all files from AWS | convert from json into a powershell object
	$list = aws s3api list-object-versions --bucket $bucket --prefix "files/$folder" | convertfrom-json

	  # If you want to do the while bucket, not a recursive subfolder. use this line without the --prefix property
	  # $list = aws s3api list-object-versions --bucket $bucket | convertfrom-json

	# Take the versions and deletemarker arrays and put them in their own variables
	$versions      = $list.versions      | select key,lastmodified,versionid,islatest 
	$deletemarkers = $list.deletemarkers | select key,lastmodified,versionid,islatest

	# Denote what items are delete markers respectfully
	$versions      | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name "deletemarker" -Value 0}
	$deletemarkers | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name "deletemarker" -Value 1}

	# JOIN the 2 identically formatted tables
	# | remove anything newer then the point in time date
	# |  sort by date
	# |  only keep the unique newest entries
	$combined = $versions + $deletemarkers | ? {$_.LastModified -le $point_in_time_restore_date} | sort-object -Property @{Expression = "LastModified"; Descending = $true} | sort-object -unique -Property key

	# make a graph showing the new formatted table
	# $combined | out-gridview

# ------------


	$restore_commands = foreach ($item in $($combined | sort key)) {
		
		# Note that the base folder is here. 
		$counter=0
		$file_to_write = "$restore_target\$base_folder\"+$($item.key).replace("files/$folder/","").replace("/","\")
		$file_to_write_dir = Split-Path -Path $file_to_write
		
		
		if ($temp -ne $file_to_write_dir) {
			"md $file_to_write_dir -ErrorAction SilentlyContinue"
		}
		

		$temp = $file_to_write_dir
		
		"aws s3api get-object --bucket $bucket --key `"$($item.key)`" --version-id $($item.versionId) `"$file_to_write`" | out-null"
	}
	
	$counter=0
	$total = $restore_commands.count
	
	"Download Files" 
	
	foreach ($item in $restore_commands) {
		
		$counter=$counter+1
		
		"$counter / $total"
		
		invoke-expression $item
		
		
	}
	
# --------------



	# Pull a list of all versions of all files from AWS | convert from json into a powershell object
	$list = aws s3api list-object-versions --bucket $bucket --prefix "metadata/$folder" | convertfrom-json

	  # If you want to do the while bucket, not a recursive subfolder. use this line without the --prefix property
	  # $list = aws s3api list-object-versions --bucket $bucket | convertfrom-json

	# Take the versions and deletemarker arrays and put them in their own variables
	$versions      = $list.versions      | select key,lastmodified,versionid,islatest 
	$deletemarkers = $list.deletemarkers | select key,lastmodified,versionid,islatest

	# Denote what items are delete markers respectfully
	$versions      | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name "deletemarker" -Value 0}
	$deletemarkers | ForEach-Object {$_ | Add-Member -MemberType NoteProperty -Name "deletemarker" -Value 1}

	# JOIN the 2 identically formatted tables
	# | remove anything newer then the point in time date
	# |  sort by date
	# |  only keep the unique newest entries
	$combined = $versions + $deletemarkers | ? {$_.LastModified -le $point_in_time_restore_date} | sort-object -Property @{Expression = "LastModified"; Descending = $true} | sort-object -unique -Property key

	# make a graph showing the new formatted table
	# $combined | out-gridview

# --------------


	$restore_commands = foreach ($item in $($combined | sort key)) {
		
		$counter=0
		$file_to_write = $restore_target+"\"+$($item.key).replace("metadata/$folder/","").replace("/","\")
		$file_to_write_dir = Split-Path -Path $file_to_write
		
		
		if ($temp -ne $file_to_write_dir) {
			"md $file_to_write_dir -ErrorAction SilentlyContinue | out-null"
		}
		

		$temp = $file_to_write_dir
		
		"aws s3api get-object --bucket $bucket --key `"$($item.key)`" --version-id $($item.versionId) `"$file_to_write`" | out-null"
	}
	
	$counter=0
	$total = $restore_commands.count
	
	"Download Metadata (File Permissions, Original Dates)" 
	
	foreach ($item in $restore_commands) {
		
		$counter=$counter+1
		
		"$counter / $total"
		
		invoke-expression $item
		
	}

# --------------


	# Windows command to restore file permissions. This Requires Admininstrator account
	icacls $restore_target /restore "$restore_target\icacls.txt" /t /c | out-null
   
