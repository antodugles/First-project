
dir = WScript.Arguments(0)

set WshShell = WScript.CreateObject("WScript.Shell")
set fso = WScript.CreateObject("Scripting.FileSystemObject")

strDesktopPath = WshShell.SpecialFolders("AllUsersDesktop")

if fso.FileExists(strDesktopPath & "\InSite ExC.lnk") <> True Then
    set uShortLink = WshShell.CreateShortCut(StrDesktopPath & "\InSite ExC.lnk")
    uShortLink.TargetPath = dir & "\\ActDeactTool.exe"
    uShortLink.Save
end if

