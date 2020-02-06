Set WshShell = CreateObject("WScript.Shell")
' strPCname = InputBox("Please insert computer name: ", "Computer Name")
strPCname = WshShell.ExpandEnvironmentStrings( "%COMPUTERNAME%" )

' UefiSerial = "UEFI Serial: " & WshShell.run("powershell -command ""(Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey""", 0, true)
UefiSerial = WshShell.run("powershell -command ""(Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey | Out-File winsn.txt""", 0, true)
Set DSO = CreateObject("Scripting.FileSystemObject")
Set oFile = DSO.OpenTextFile("winsn.txt", 1, , -2) 
UefiSerial = oFile.ReadAll 
oFile.Close
if DSO.FileExists("winsn.txt") then DSO.DeleteFile "winsn.txt" end if

Dim fso
Set fso = WScript.CreateObject("Scripting.FilesyStemObject")
Set f = fso.CreateTextFile("winsn.txt", 2)

f.WriteLine "Computer Name: " & UCase(strPCname) & " - " & WshShell.ExpandEnvironmentStrings( "%COMPUTERNAME%" )

Set dtmConvertedDate = CreateObject("WbemScripting.SWbemDateTime")
strComputer = "."
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set oss = objWMIService.ExecQuery ("Select * from Win32_OperatingSystem")
For Each os in oss
'Wscript.Echo "OS: " & os.Caption
f.WriteLine os.Caption
Next

f.WriteLine "UEFI Serial: " & UefiSerial
f.WriteLine "Reg Serial: " & ConvertToKey(WshShell.RegRead("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DigitalProductId"))
f.WriteLine  "User Name: " & WshShell.ExpandEnvironmentStrings( "%USERNAME%" )

strQuery = "SELECT * FROM Win32_NetworkAdapterConfiguration WHERE MACAddress > ''"
Set objWMIService = GetObject( "winmgmts://./root/CIMV2" )
Set colItems      = objWMIService.ExecQuery( strQuery, "WQL", 48 )
For Each objItem In colItems
    If IsArray( objItem.IPAddress ) Then
        If UBound( objItem.IPAddress ) = 0 Then
            strIP = "IP Address: " & objItem.IPAddress(0)
        Else
            strIP = "IP Addresses: " & Join( objItem.IPAddress, "," )
        End If
    End If
Next
f.WriteLine strIP

dim WMI:  set WMI = GetObject("winmgmts:\\.\root\cimv2")
dim Nads: set Nads = WMI.ExecQuery("Select * from Win32_NetworkAdapter where physicaladapter=true") 
dim nad
for each Nad in Nads
    if not isnull(Nad.MACAddress) then f.WriteLine Nad.description & " MAC: " & Nad.MACAddress   
next

f.Close

WScript.Echo "Finished."

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
