# Menu Radio Button Function

. .\PS-Forms.ps1
. .\backup-win2s3.ps1

$fail_flag=0
$temp_folder = "c:\temp\win2s3"

# ------------------

" 
    Function: Write Backup Command"


$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = "Select the local source folder to backup"
[void]$FolderBrowser.ShowDialog()

if ($($FolderBrowser.SelectedPath) -eq "") {$fail_flag = 1}


"      Source: `"$($FolderBrowser.SelectedPath)`""


if ($fail_flag -eq 0) {

	# Get Buckets

	$list = $(aws s3api list-buckets --output json | convertfrom-json).buckets.name
	$bucket = Get-FormArrayItem $list -dialogTitle "Select the S3 Bucket to backup to"


	}



if ($fail_flag -eq 0) {

"      Bucket: $bucket
 Temp Folder: $temp_folder"

		# Import the necessary assemblies
		Add-Type -AssemblyName System.Windows.Forms

		$width = 600

		# Create a new form
		$form = New-Object System.Windows.Forms.Form

		# Set the form's properties
		$form.Text = "Copyable backup command"
		$form.Size = New-Object System.Drawing.Size($width, 200)
		$form.StartPosition = "CenterScreen"

		# Create a multiline text field
		$textBox = New-Object System.Windows.Forms.TextBox
		$textBox.Multiline = $true
		$textBox.ReadOnly = $true
		$textBox.Location = New-Object System.Drawing.Point(10, 10)
		$textBox.Size = New-Object System.Drawing.Size(($width - 40), 120)
		$textBox.text = "powershell -command `". ```"$(pwd)\backup-win2s3.ps1```"; backup-win2s3 $bucket ```"$($FolderBrowser.SelectedPath)```" ```"$temp_folder```" `""

		# Add the text field to the form
		$form.Controls.Add($textBox)

		# Show the form
		$form.ShowDialog()


	
} else {

"

      Program cancelled by user.

"


}
