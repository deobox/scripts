if (!$args[0]) { echo "Please specify VM name"; exit; }

$vm=$args[0]
$basedir=Get-Location
$dir1="$basedir\$vm"
$dir2="$dir1-old"

if (Test-Path "$dir2") { Remove-Item "$dir2" -Recurse -Force }
if (Test-Path "$dir1") { Move-Item -Path "$dir1" -Destination "$dir2" -Force }

Stop-VM -Name "$vm"
Export-VM -Name "$vm" -Path "$basedir"
Start-VM -Name "$vm"
