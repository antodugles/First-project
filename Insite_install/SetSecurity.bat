@echo off
rem This batch file will open or close the web server, VNC server  and/or Telnet server security
rem for manufacturing or training purpose.
rem Make sure to close the security after the work.
rem Usage: SetSecurity [open | close]

if not "%1"=="open" (
	if not "%1"=="close" (
		goto UsageEnd
	)
)

if "%INSITE2_HOME%"=="" (
	echo Service Platform is not installed.
	goto END
)

rem Check if web server is configured to be installed
"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" WebServer "%INSITE2_HOME%\InstallOption.xml" > nul
if ERRORLEVEL 1 goto configVNC

echo Changing Web Server Security...
"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\SetWebServerSec.pl" %1 "%WIP_HOME%Apache\conf\httpd.conf"
if exist "%INSITE2_HOME%\bin\ComponentControl.exe" (
	echo Starting/Restarting Web Server...
	call "%INSITE2_HOME%\bin\StartComp.bat" -webserver 
	echo.
)

:configVNC
rem Check if VNC is configured to be installed
"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" VNC "%INSITE2_HOME%\InstallOption.xml" > nul
if ERRORLEVEL 1 goto configTelnet

echo Changing VNC Security...
if "%1"=="open" (
	reg add HKLM\SOFTWARE\RealVNC\WinVNC4 /f /v LocalHost /t REG_DWORD /d 0 > nul
	reg add HKCU\SOFTWARE\RealVNC\WinVNC4 /f /v LocalHost /t REG_DWORD /d 0 > nul
	reg add HKLM\SOFTWARE\RealVNC\WinVNC4 /f /v Hosts /t REG_SZ /d +, > nul
	reg add HKCU\SOFTWARE\RealVNC\WinVNC4 /f /v Hosts /t REG_SZ /d +, > nul
	rem Create "%INSITE2_HOME%\bin\OpenVNC.txt" file, so starting VNC using ComponentControl.exe will not add the Hosts registry security
	echo No VNC Security > "%INSITE2_HOME%\bin\OpenVNC.txt"
) else (
	reg add HKLM\SOFTWARE\RealVNC\WinVNC4 /f /v LocalHost /t REG_DWORD /d 1 > nul
	reg add HKCU\SOFTWARE\RealVNC\WinVNC4 /f /v LocalHost /t REG_DWORD /d 1 > nul
	if exist "%INSITE2_HOME%\bin\OpenVNC.txt" (
		del /f /q "%INSITE2_HOME%\bin\OpenVNC.txt"
	)
)
if exist "%INSITE2_HOME%\bin\ComponentControl.exe" (
	echo Starting/Restarting VNC Server...
	call "%INSITE2_HOME%\bin\StartComp.bat" -vnc 
	echo.
)

:configTelnet
rem Check if Telnet is configured to be installed
"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" Telnet "%INSITE2_HOME%\InstallOption.xml" > nul
if ERRORLEVEL 1 goto WARN

echo Changing Telnet Security...
if "%1"=="open" (
	reg add HKLM\SOFTWARE\Microsoft\TelnetServer\1.0 /f /v ListenToSpecificIpAddr /t REG_EXPAND_SZ /d INADDR_ANY > nul
) else (
	reg add HKLM\SOFTWARE\Microsoft\TelnetServer\1.0 /f /v ListenToSpecificIpAddr /t REG_EXPAND_SZ /d 127.0.0.1 > nul
)
if exist "%INSITE2_HOME%\bin\ComponentControl.exe" (
	echo Starting/Restarting Telnet Server...
	call "%INSITE2_HOME%\bin\StartComp.bat" -telnet 
	echo.
)
goto WARN

:UsageEnd
echo Usage: SetSecurity [open ^| close]
goto END
:WARN
rem In case ComponentControl.exe is not installed because AltInstall is set in InstallOption.xml,
if not exist "%INSITE2_HOME%\bin\ComponentControl.exe" (
	echo.
	echo The security change will be effective when the affected servers are restarted.
)
if "%1"=="open" (
	echo Warning: Don't forget to close the security after the work!
)
:END