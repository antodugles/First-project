Dim portno

portno = WScript.Arguments(0)

set WshShell = WScript.CreateObject("WScript.Shell")
strDesktopPath = WshShell.SpecialFolders("AllUsersDesktop")

set uShortLink = WshShell.CreateShortCut(StrDesktopPath & "\Service Browser.url")
uShortLink.TargetPath = "http://localhost:" & portno & "/service/"
uShortLink.Save