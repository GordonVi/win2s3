clear

	$bucket = "november2022demo" # must be lowercase, AWS rules
	$folder = "C/Users/Gordon/Desktop/powershell/aws" # Case Sensitive
	$restore_target = "C:\temp\restore" # this is where you are dumping the restore data
	$point_in_time_restore_date = "2022-12-15T01:21:47+00:00"

# ------------
# Check if this logged in user is an admin. If not, exit.

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

    $spot = $folder.split("/").length
	$base_folder = $folder.split("/")[$spot-1] # the last folder in the bucket. This is important for the Win ACL restore
	$folder_win_format = $folder.replace("/","\").insert(1,":")
	
	md $restore_target | out-null
	
# ------------


	write-host -foregroundcolor cyan "
	Restore Target..
	"

	$restore_target

	write-host -foregroundcolor cyan "
	Getting the points in the disk that are restorable...
	"
	$restore_point_list = $($(aws s3api list-objects --bucket $bucket --prefix "metadata" --output json | convertfrom-json).contents | where {$_.Key -match "s3api_file_list.json"}).key.replace("metadata/","").replace("/s3api_file_list.json","")

	# The list of core root files to restore from. (The location to restore from)
	$restore_point_list


	write-host -foregroundcolor cyan "
	Getting the points in time of backup.
	"

	$version_list = aws s3api list-object-versions --bucket $bucket --prefix "metadata/$folder/s3api_file_list.json" --output json | convertfrom-json

	# list of versions from selected core files. (The point in time to restore from)
	$temp = $($version_list.versions).lastmodified | sort -descending
	$temp


	write-host -foregroundcolor cyan "
	
	----------------------------

	"

# ------------

	# Pull a list of all versions of all files from AWS | convert from json into a powershell object
	$list = aws s3api list-object-versions --bucket $bucket --prefix "files/$folder" --output json | convertfrom-json

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
	# |  only keep the unique newest entries

	$combined_temp = $versions + $deletemarkers | ? {$_.LastModified -le $point_in_time_restore_date}
	$combined_key = $combined_temp | sort key -unique

	$combined = foreach ($item in $combined_key) {
		
		$combined_temp | ? {$_.key -eq $item.key} | sort LastModified -descending | select-object -first 1
	}

	# make a graph showing the new formatted table
	# $combined | out-gridview

# ------------


	write-host -foregroundcolor cyan "Find Files from S3" 

	$restore_commands = foreach ($item in $($combined | sort key)) {
		
		# Note that the base folder is here. 
		$counter=0
		$file_to_write = "$restore_target\$base_folder\"+$($item.key).replace("files/$folder/","").replace("/","\")
		$file_to_write_dir = Split-Path -Path $file_to_write
		
		
		if ($temp -ne $file_to_write_dir) {
			"md `"$file_to_write_dir`" -ErrorAction SilentlyContinue | out-null"
		}
		

		$temp = $file_to_write_dir # this is a post process cache. Check if the value was the same as te last iteration.
		
		"aws s3api get-object --bucket $bucket --key `"$($item.key)`" --version-id $($item.versionId) `"$file_to_write`" --output json | out-null"
	}
	
	$counter=0
	$total = $restore_commands.count
	
		write-host -foregroundcolor cyan "Download Files" 
	
	foreach ($item in $restore_commands) {
		
		$counter=$counter+1
		
		"$counter / $total"
		
		invoke-expression $item
		
		
	}
	
# --------------


	write-host -foregroundcolor cyan "Find Metadata from s3 (File Permissions, Original Dates)" 

	# Pull a list of all versions of all files from AWS | convert from json into a powershell object
	$list = aws s3api list-object-versions --bucket $bucket --prefix "metadata/$folder" --output json | convertfrom-json

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
	# |  only keep the unique newest entries

	$combined_temp = $versions + $deletemarkers | ? {$_.LastModified -le $point_in_time_restore_date}
	$combined_key = $combined_temp | sort key -unique

	$combined = foreach ($item in $combined_key) {
		
		$combined_temp | ? {$_.key -eq $item.key} | sort LastModified -descending | select-object -first 1
	}
	
	
	# make a graph showing the new formatted table
	# $combined | out-gridview

# --------------


	$restore_commands = foreach ($item in $($combined | sort key)) {
		
		$counter=0
		$file_to_write = $restore_target+"\"+$($item.key).replace("metadata/$folder/","").replace("/","\")
		$file_to_write_dir = Split-Path -Path $file_to_write
		

		if ($restore_target -eq $file_to_write_dir){
				# only restore the base directory, not recursive.
				"aws s3api get-object --bucket $bucket --key `"$($item.key)`" --version-id $($item.versionId) `"$file_to_write`" --output json | out-null"
		}
	}
	
	$counter=0
	$total = $restore_commands.count
	
	write-host -foregroundcolor cyan "Download Metadata (File Permissions, Original Dates)" 
	
	foreach ($item in $restore_commands) {
		
		$counter=$counter+1
		
		"$counter / $total"
		
		invoke-expression $item
		
	}

# --------------

# https://www.ghacks.net/2017/10/09/how-to-edit-timestamps-with-windows-powershell/

	write-host -foregroundcolor cyan "Set File Dates, Write Empty Folders, set read only attributes" 
   
 $list = gc "$restore_target\file_list.powershell.json" | convertfrom-json

 foreach ($item in $list) {

	 $FullName = $item.FullName.replace($folder_win_format,"$restore_target\$base_folder")
	 
	if (Test-Path -Path $FullName -PathType Leaf) {
		 
		 $file_object = $(Get-Item $FullName)
		 $file_object.CreationTimeUtc = $item.CreationTimeUtc
		 $file_object.LastWriteTimeUtc = $item.LastWriteTimeUtc
		 $file_object.IsReadOnly = $item.IsReadOnly

		}
	
	# this makes the blank folders that were stored in the metadata but not in s3
	if ($item.recurse_file_count -eq 0) {md $FullName | out-null}

	}

 $list = $list 

# --------------

	write-host -foregroundcolor cyan "Set folder Permission with Icacls.exe (Windows)" 

	# Windows command to restore file permissions. This Requires Admininstrator account
	$temp = icacls $restore_target /restore "$restore_target\icacls.txt" /t /c | out-null

# --------------


# --------------


	write-host -foregroundcolor cyan "Finalize folder (move)" 

# clean up metadata

	$list = gci $restore_target | ? {$_.PSIscontainer -eq 0}
	remove-item $list.fullname

# Move base folder to root

	Move-Item "$restore_target\$base_folder" "$restore_target-$base_folder"
	#sleep 1
	
	rm $restore_target
	#sleep 1

	Move-Item "$restore_target-$base_folder" $restore_target
	

	