
dir = WScript.Arguments(0)

set WshShell = WScript.CreateObject("WScript.Shell")
set fso = WScript.CreateObject("Scripting.FileSystemObject")

startMenuPath = WshShell.SpecialFolders("StartMenu")

if fso.FileExists(startMenuPath & "\InSite ExC.lnk") <> True Then
    set uShortLink = WshShell.CreateShortCut(startMenuPath & "\InSite ExC.lnk")
    uShortLink.TargetPath = dir & "\\ActDeactTool.exe"
    uShortLink.Save
end if

