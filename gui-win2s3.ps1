$host.UI.RawUI.WindowTitle = "Win2S3 Console"
clear
" Win 2 S3 Output Console...

"

. .\PS-Forms.ps1

$list = @("Backup to S3 Bucket","List Backup Contents","Restore a Backup (Requires Admin Privledges)")
$temp = Get-FormArrayItem $list -dialogTitle "Select a function"


if ($temp -eq $list[0]) {.\gui-backup-win2s3.ps1}
if ($temp -eq $list[1]) {.\gui-list-win2s3.ps1}
if ($temp -eq $list[2]) {Start-Process powershell "-command `"cd `"$(pwd)`"; .\gui-restore-win2s3.ps1`"" -verb runas}