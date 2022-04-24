Set WshShell = CreateObject("WScript.Shell")

Dim fso
Set fso = WScript.CreateObject("Scripting.FilesyStemObject")
if fso.FileExists("winkeys.txt") then WScript.Echo "File winkeys.txt exists and will be overwritten!" end if
Set f = fso.CreateTextFile("winkeys.txt", 2)

f.WriteLine "Date: " & now
f.WriteLine "PC: " & WshShell.ExpandEnvironmentStrings( "%COMPUTERNAME%" ) 
f.WriteLine "User: " & WshShell.ExpandEnvironmentStrings( "%USERNAME%" )

Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
Set oss = objWMIService.ExecQuery ("Select * from Win32_OperatingSystem")
For Each os in oss
f.WriteLine "OS: " & os.Caption
Next
Set oss = objWMIService.ExecQuery ("select * from SoftwareLicensingService")
For Each path in oss
f.WriteLine "EFI: " & path.OA3xOriginalProductKey
Next

f.WriteLine "Win: " & ConvertToKey(WshShell.RegRead("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DigitalProductId"))
f.WriteLine "Reg: " & WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\BackupProductKeyDefault")
f.Close

if fso.FileExists("winkeys.txt") then 
With CreateObject("WScript.Shell")
    .Run "notepad winkeys.txt"
End With
else
WScript.Echo "Something went wrong!"
end if

Function ConvertToKey(Key)
Const KeyOffset = 52
i = 28
Chars = "BCDFGHJKMPQRTVWXY2346789"
Do
Cur = 0
x = 14
Do
Cur = Cur * 256
Cur = Key(x + KeyOffset) + Cur
Key(x + KeyOffset) = (Cur \ 24) And 255
Cur = Cur Mod 24
x = x -1
Loop While x >= 0
i = i -1
KeyOutput = Mid(Chars, Cur + 1, 1) & KeyOutput
If (((29 - i) Mod 6) = 0) And (i <> -1) Then
i = i -1
KeyOutput = "-" & KeyOutput
End If
Loop While i >= 0
ConvertToKey = KeyOutput
End Function
