$host.UI.RawUI.WindowTitle = "Win2S3 Console"
clear
" Win 2 S3 Output Console...

"

. .\PS-Forms.ps1

$list = @("Backup to S3 Bucket","List Backup Contents","Restore a Backup")
$temp = Get-FormArrayItem $list -dialogTitle "Select a function"


if ($temp -eq "Backup to S3 Bucket") {.\gui-backup-win2s3.ps1}
if ($temp -eq "List Backup Contents") {.\gui-list-win2s3.ps1}
if ($temp -eq "Restore a Backup") {Start-Process powershell "-command `"cd `"$(pwd)`"; .\gui-restore-win2s3.ps1`"" -verb runas}