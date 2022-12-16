Add-Type -AssemblyName System.Windows.Forms

function menu($title) {

# ------------

$radio=@()
$kerning=27
$kerning_temp=10
$result=1

$form_x = 600
$form_y = 150 + ($list.count * $kerning)

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

