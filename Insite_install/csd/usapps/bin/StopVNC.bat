@echo off
rem This batch file is responsible for stopping VNC and 
rem cleaningup
rem Tasks:
rem      Start BlockWindowsKeys if this system is based on GE global ultrasound software platform
rem      Close windows desktop if this is a closed system by restoring explorer policy and Winlogon registry key
rem      Stop VNC
rem
rem Date         Name            Description
rem 24-Mar-2006  Jung Oh         New
rem 19-Apr-2006  Jung Oh         Remove the open desktop registry restore codes. It's restored in StartVNC.cgi right away now. 
rem 23-Feb-2009  D. Clapham      Use ComponentControl to query if VNC is installed.

setlocal

if "%INSITE2_HOME%"=="" (
	goto END
)

rem Exit if VNC is not installed
ComponentControl.exe -vnc -isinstalled -s
if not ERRORLEVEL 1 (
	goto END
)

rem Start BlockWindowsKeys if this system is based on GE global ultrasound software platform
reg query HKCU\Software\GEVU\StartLoader > nul 2>&1
if not ERRORLEVEL 1 (
	rem Kill BlockWindowsKeys so that when you start it there will be only one copy running
	taskkill /f /im BlockWindowsKeys.exe > nul 2>&1
	start /d"%TARGET_ROOT%\bin" BlockWindowsKeys.exe > nul 2>&1
)

rem If %INSITE_HOME%\diagLogs\.desktopStatus file exists, it means that this is a closed system but the desktop is opened when VNC started. 
rem This file is created during the VNC start if explorer was not running at the time.
rem The explorer and userinit started during the VNC start have to be killed to close the desktop and return to the original state before VNC was started.
if exist "%INSITE_HOME%\diagLogs\.desktopStatus" (
    taskkill /f /im explorer.exe > nul 2>&1
    taskkill /f /im userinit.exe > nul 2>&1
    del /f "%INSITE_HOME%\diagLogs\.desktopStatus"
)

rem Finally, stop the VNC server
ComponentControl.exe -vnc -stop -s

:END
exit