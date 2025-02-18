@ECHO OFF
SETLOCAL

GOTO :_print_

::: Use Shift+F10 to run

:_reg_
echo --- Setting up registry to avoid TPM and CPU checks
reg add HKCU\SOFTWARE\Microsoft\PCHC /v UpgradeEligibility /t REG_DWORD /d 1 /f
reg add HKLM\SYSTEM\Setup\MoSetup /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f
reg add HKLM\SYSTEM\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f
reg add HKLM\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f
reg add HKLM\SYSTEM\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f
reg add HKLM\SYSTEM\Setup\LabConfig /v BypassStorageCheck /t REG_DWORD /d 1 /f
reg add HKLM\SYSTEM\Setup\LabConfig /v BypassCPUCheck /t REG_DWORD /d 1 /f
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
echo --- You can now perform clean install without TPM and unsupported CPUs
GOTO :_print_

:_install_
if not exist "setup.exe" ( echo Error: setup.exe is missing & GOTO :_print_ )
echo --- Performing clean install of Windows 11
setup.exe /quiet /eula accept /compat ignorewarning /migratedrivers all /telemetry disable
GOTO :_print_

:_notpm_
if not exist "sources\setupprep.exe" ( echo Error: sources\setupprep.exe is missing & GOTO :_print_ )
echo --- Install Windows 11 without TPM or supported CPU
PUSHD sources
if exist "sources\setupprep.exe" ( setupprep.exe /product server /eula accept /compat ignorewarning /migratedrivers all /telemetry disable )
POPD
GOTO :_print_

:_moreop_
echo --- Setting up show more options in menus by default
reg add HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32 /ve /d "" /f
echo --- Done
GOTO :_print_

:_nomsac_
echo --- Disabling MS accounts and internet connection requirements
PUSHD C:
if exist "C:Windows\System32\oobe\BypassNRO.cmd" C:Windows\System32\oobe\BypassNRO.cmd
POPD
PUSHD %windir%
if exist "%windir%\System32\oobe\BypassNRO.cmd" %windir%\System32\oobe\BypassNRO.cmd
POPD
PUSHD %SystemRoot%
if exist "%SystemRoot%\System32\oobe\BypassNRO.cmd" %SystemRoot%\System32\oobe\BypassNRO.cmd
POPD
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
shutdown /r /t 0
echo --- Done
GOTO :_print_

:_fast_
if not exist "setup.exe" ( echo Error: setup.exe is missing & GOTO :_print_ )
echo --- Performing fast install of Windows 11
setup.exe /quiet /eula accept /compat ignorewarning /migratedrivers all /telemetry disable /ShowOOBE None
GOTO :_print_

:_print_
echo 1 - Set up registry entries for TPM and CPU
echo 2 - Perform clean Win11 install
echo 3 - No TPM or supported CPU install
echo 4 - Show more options in menus by default
echo 5 - Disable MS accounts and internet requirements
echo 6 - Fast Win11 install
echo q - Quit
GOTO :_ask_

:_ask_
set /p ask="Choose option 1-6 or q for quit : "
if "%ask%" == "1" GOTO :_reg_
if "%ask%" == "2" GOTO :_install_
if "%ask%" == "3" GOTO :_notpm_
if "%ask%" == "4" GOTO :_moreop_
if "%ask%" == "5" GOTO :_nomsac_
if "%ask%" == "6" GOTO :_fast_
if "%ask%" == "q" GOTO :EOF
GOTO :_ask_

:EOF
ENDLOCAL
