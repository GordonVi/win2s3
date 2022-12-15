Add-Type -AssemblyName System.Windows.Forms

function menu($title) {
	
$radio=@()
$kerning=20
$kerning_temp=10
$result=1

$form_x = 600
$form_y = 110 + ($list.count * $kerning)

$form = New-Object System.Windows.Forms.Form
$form.Text = $title
$form.Size = New-Object System.Drawing.Size($form_x, $form_y)

foreach ($item in $list) {

	# Create the radio buttons

	$radio_temp = New-Object System.Windows.Forms.RadioButton
	$radio_temp.Text = $item
	$radio_temp.Location = New-Object System.Drawing.Point(10, $kerning_temp)
	$radio_temp.Size = New-Object System.Drawing.Size(100,20)
	$radio_temp.AutoSize = $true

	$form.Controls.Add($radio_temp)
	$radio += $radio_temp
	
    $kerning_temp = $kerning_temp + $kerning
	}


# Add the radio buttons to the form
    $kerning_temp = $kerning_temp + $kerning

# Create the "OK" and "Cancel" buttons
$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Location = New-Object System.Drawing.Point(10, $kerning_temp)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Location = New-Object System.Drawing.Point(100, $kerning_temp)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

# Add the buttons to the form

$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

    $okButton.Add_Click(
			{
				$form.dispose()
			}
		)

    $cancelButton.Add_Click(
			{    
				$form.close()
			}
		)
	

# Show the form
$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
	
	return @("yes",$($radio | ? {$_.checked -eq 1}).text)
	
} else {
	
	return @("no",$($radio | ? {$_.checked -eq 1}).text)
	
}

}


	$restore_target = "C:\temp\restore" # this is where you are dumping the restore data
	$fail_flag=0

	$list = $(aws s3api list-buckets --output json | convertfrom-json).buckets.name
	$temp = menu("Select the S3 Bucket")

	if ($temp[0] -eq "yes") {
		
		$bucket = $temp[1]

		$restore_point_list = $($(aws s3api list-objects --bucket $bucket --prefix "metadata" --output json | convertfrom-json).contents | where {$_.Key -match "s3api_file_list.json"}).key.replace("metadata/","").replace("/s3api_file_list.json","")
		$restore_point_list
		$list = $restore_point_list

		$temp = menu("Select the restore point")
		
		if ($temp[0] -eq "yes") {
			
			$folder = $temp[1]
		
			$version_list = aws s3api list-object-versions --bucket $bucket --prefix "metadata/$folder/s3api_file_list.json" --output json | convertfrom-json
			# list of versions from selected core files. (The point in time to restore from)
			$temp = $($version_list.versions).lastmodified | sort -descending
			$list = $temp

			$temp = menu("Select the point in time")

			if ($temp[0] -eq "yes") {
				
				$point_in_time_date = $temp[1]
			
			} else {$fail_flag = 1}
		} else {$fail_flag = 1}
	} else {$fail_flag = 1}
	
" 
  Fail: $fail_flag
Bucket: $bucket
Folder: $folder
  PITR: $point_in_time_date"

