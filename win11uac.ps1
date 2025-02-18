# console execution as administrator :  powershell -ExecutionPolicy Bypass -File win11uac.ps1
# reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0x0 /f

$PromptOnSecureDesktop = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System).PromptOnSecureDesktop

if ($PromptOnSecureDesktop -ne 0) {
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\"
    $registryKey = "PromptOnSecureDesktop"
    $registryValue = 0
    
    try
    {
        Set-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue -ErrorAction Stop
        $exitCode = 0
    }
    catch
    {   
        Write-Error -Message "Could not write regsitry value" -Category OperationStopped
        $exitCode = -1
    }
}

exit $exitCode
