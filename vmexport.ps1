if (!$args[0]) { echo "Please specify VM name"; exit; }

$vm=$args[0]
$basedir=Get-Location
$dir1="$basedir\$vm"
$dir2="$dir1-old"

if (Test-Path "$dir2") { Remove-Item "$dir2" -Recurse -Force }
if (Test-Path "$dir1") { Move-Item -Path "$dir1" -Destination "$dir2" -Force }

function Send-Me-Mail {
 Param($MailText)
 Send-MailMessage -From '<your@email.address>' -To '<your@email.address>' -Subject "$MailText" -Body "$MailText" -DeliveryNotificationOption None -SmtpServer '127.0.0.1' -Encoding utf8
}

Send-Me-Mail -MailText "Backup started for $vm"

Stop-VM -Name "$vm"
if (!$?) { Send-Me-Mail -MailText "Backup job is unable to stop $vm" }

Export-VM -Name "$vm" -Path "$basedir"
if ($?) { Send-Me-Mail -MailText "Backup of $vm is successful" } else { Send-Me-Mail -MailText "Backup of $vm has failed" }

Start-VM -Name "$vm"
if (!$?) { Send-Me-Mail -MailText "Backup job is unable to start $vm" }

Send-Me-Mail -MailText "Backup completed for $vm"

