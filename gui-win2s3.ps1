. .\menu.ps1

$list = @("Backup to S3 Bucket","List Backup Contents","Restore a Backup")
$temp = menu "Win2S3 Main Menu: Select a function"

if ($temp[0] -eq "no"){"Cancelled by user"; exit}

if ($temp[1] -eq "Backup to S3 Bucket") {.\gui-backup-win2s3.ps1}
if ($temp[1] -eq "List Backup Contents") {.\gui-list-win2s3.ps1}
if ($temp[1] -eq "Restore a Backup") {.\gui-restore-win2s3.ps1}