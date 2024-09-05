@echo off
rem This batch file will start/restart the web server, Questra agent, VNC server or Telnet server in the StartMode according to the InstallOption.xml file
rem Usage: StartComp [-webserver | -agent | -vnc | -telnet] [-nr] [-s]
rem -nr: No Restart.  If the component is running already.  It won't be restarted.
rem -s: Silent mode. No error or warning message will pop up.

if "%1"=="-h" (
	goto UsageEnd
)

if "%1"=="/?" (
	goto UsageEnd
)

set Component=
if "%1"=="-webserver" (
	set Component=WebServer
)
if "%1"=="-agent" (
	set Component=QuestraAgent
)
if "%1"=="-vnc" (
	set Component=VNC
)
if "%1"=="-telnet" (
	set Component=Telnet
)

if .%Component%==. (
	goto UsageEnd
)

rem Check if the component is installed
"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" %Component% "%INSITE2_HOME%\InstallOption.xml" > nul
if ERRORLEVEL 1 (
	rem The component is not supposed to be installed.
	echo Not Installed
	goto END
)
		
rem Check the StartMode
"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" %Component% "%INSITE2_HOME%\InstallOption.xml" AutoService > nul
if ERRORLEVEL 1 (
	goto checkManualService
)
goto startService
		
:checkManualService
"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" %Component% "%INSITE2_HOME%\InstallOption.xml" ManualService > nul
if ERRORLEVEL 1 (
	goto startProcess
)

:startService
rem Start/Restart the service
ComponentControl.exe %* -startservice 
echo The service started
goto END
		
:startProcess
rem Start/Restart the service
ComponentControl.exe %* -startprocess
echo The process started
goto END

:UsageEnd
echo StartComp [-webserver ^| -agent ^| -vnc ^| -telnet] [-nr]
echo -nr: No Restart.  If the component is running already.  It won't be restarted.
echo -s: Silent mode. No error or warning message will pop up.
:END