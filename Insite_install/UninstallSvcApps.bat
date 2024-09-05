@echo off
rem        Uninstall batch file for:
rem              Service Apps which includes:
rem                  Utilities Uninstall
rem                  VNC Uninstall
rem                  Distinct Uninstall
rem                  CSD Uninstall 
rem                  RFS Uninstall
rem                  Service Platform Windows Services Uninstall:
rem                    ELRService
rem                    RFSService
rem                    InCpProxyService

if not "%WIP_HOME%"=="" (
	set WebAppsDir=%WIP_HOME%tomcat\webapps
)

echo Uninstalling Service Applications

set StoppingComponents=No
set CurrentDir=%CD%

if exist "%WebAppsDir%\modality-csd\usapps\PCDoctor\bin\pcd.exe" (
	echo Stopping PC Doctor
	cmd /c "cd /d %WebAppsDir%\modality-csd\usapps\PCDoctor\bin & pcd.exe Stop" > nul
	set StoppingComponents=Yes
)

set DISTINCTPROG=C:\Program Files\Distinct\Monitor\Monitor.exe
if exist "%DISTINCTPROG%" (
	echo Stopping Distinct
	taskkill /f /im Monitor.exe > nul 2>&1
	set StoppingComponents=Yes
)

if exist "%WIP_HOME%CookieMonster.bat" (
	echo Stopping Apache/Tomcat Web Server
	cd /d "%WIP_HOME%"
	call CookieMonster.bat stop > nul
	cd /d "%CurrentDir%"
	set StoppingComponents=Yes
)

if not exist "%INSITE2_HOME%\bin\ComponentControl.exe" (
	if exist "%INSITE2_ROOT_DIR%\bin\qsaMain.exe" (
		echo Stopping Questra Agent 
		net stop qsa > nul 2>&1
		taskkill /f /im qsaMain.exe > nul 2>&1
		set StoppingComponents=Yes
	)

rem <<<< NOTE TO PRODUCT TEAMS >>>>
rem  The following lines of code provide a "brute-force" stop of VNC when
rem  ComponentControl.exe is not available.  If some other version of VNC is
rem  installed, the following lines must be modified as needed to check for
rem  and stop your version of VNC.
	if exist "%INSITE2_HOME%\UltraVNC\winvnc.exe" (
		echo Stopping VNC
		net stop uvnc_service > nul
		set StoppingComponents=Yes
	)
)
	
if exist "%INSITE2_HOME%\bin\ComponentControl.exe" (
	if exist "%INSITE2_ROOT_DIR%\bin\qsaMain.exe" (
		echo Stopping Questra Agent 
		"%INSITE2_HOME%\bin\ComponentControl.exe" -agent -stopservice -s
		"%INSITE2_HOME%\bin\ComponentControl.exe" -agent -stopprocess -s
		set StoppingComponents=Yes
	)
	"%INSITE2_HOME%\bin\ComponentControl.exe" -vnc -isinstalled -s
	if ERRORLEVEL 1 (
		echo Stopping VNC
		"%INSITE2_HOME%\bin\ComponentControl.exe" -vnc -stop -s
		set StoppingComponents=Yes
	)
)

reg query "HKLM\SYSTEM\CurrentControlSet\Services\TlntSvr" > nul 2>&1
if not ERRORLEVEL 1 (
	echo Stopping Telnet
	sc stop TlntSvr > nul
	set StoppingComponents=Yes
)

if "%StoppingComponents%"=="Yes" (
	rem Sleep for about 10 seconds
	ping 1.1.1.1 -n 5 -w 500 > nul
)

echo Uninstalling Service Web Apps if installed
rem Delete all files (agent config. update tool) in %INSITE2_HOME%\Questra folder
rem except for "AgentConfigMetaData.xml" which is installed using QuestraInstall.bat.
if exist "%INSITE2_HOME%\Questra" (
	move /y "%INSITE2_HOME%\Questra\AgentConfigMetaData.xml" "%INSITE2_HOME%\Temp" > nul 2>&1
	del /f /q "%INSITE2_HOME%\Questra\*.*"
	move /y "%INSITE2_HOME%\Temp\AgentConfigMetaData.xml" "%INSITE2_HOME%\Questra" > nul 2>&1
)

rem Delete the user account added for Telnet
net user GEService /delete > nul 2>&1

reg query "HKLM\SYSTEM\CurrentControlSet\Services\TlntSvr" > nul 2>&1
if not ERRORLEVEL 1 (
	rem Restore Telnet's startup type to manual
	sc config TlntSvr start= demand > nul
	rem Restore Telnet related registries
	reg add HKLM\SOFTWARE\Microsoft\TelnetServer\1.0 /f /v ListenToSpecificIpAddr /t REG_EXPAND_SZ /d INADDR_ANY > nul
	rem Restore the default Telnet authentication scheme
	tlntadmn config sec=+ntlm +passwd > nul 2>&1
)

rem Remove VNC run registry
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v VNC /f > nul 2>&1
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunStart /v VNC /f > nul 2>&1

rem Remove Questra Agent run registry
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v QuestraAgent /f > nul 2>&1
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunStart /v QuestraAgent /f > nul 2>&1

rem Remove Web Server run registry
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v Insite2WebServer /f > nul 2>&1
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunStart /v Insite2WebServer /f > nul 2>&1

rem Remove component services (brute-force)
rem <<<< NOTE TO PRODUCT TEAMS >>>>
rem  If another version of VNC is installed, replace "winVNC4" (below) with
rem  the service name of your version of VNC in order to provide a "brute-force"
rem  removal of the VNC service.
if not exist "%INSITE2_HOME%\bin\ComponentControl.exe" (
        sc delete qsa > nul
        sc delete uvnc_service > nul
        sc delete Apache2 > nul
        sc delete Tomcat5 > nul
)

echo Stopping the ActDeactTool, if running
if exist "%INSITE2_HOME%\bin\ActDeactTool.exe" (
	taskkill /IM ActDeactTool.exe > nul 2>&1
	ActDeactTool.exe -noautostart
	ActDeactTool.exe -unregeventsrc
)

rem Unregister all components.
if exist "%INSITE2_HOME%\bin\ComponentControl.exe" (
	"%INSITE2_HOME%\bin\ComponentControl.exe" -vnc -unregservice -s
	"%INSITE2_HOME%\bin\ComponentControl.exe" -agent -unregservice -s
	"%INSITE2_HOME%\bin\ComponentControl.exe" -webserver -unregservice -s
	
	rem Unregister ComponentControl.exe
	"%INSITE2_HOME%\bin\ComponentControl.exe" /UnregServer
	"%INSITE2_HOME%\bin\ComponentControl.exe" /unregeventsrc
)

rem Unregister CustomBrowser.exe
if exist "%INSITE2_HOME%\bin\CustomBrowser.exe" (
	"%INSITE2_HOME%\bin\CustomBrowser.exe" /UnregServer
)

rem Remove ultrasound specific entries from Apache/Tomcat Web Server Configuration File.
"%PERL_HOME%bin\perl" update_conf.pl "%WIP_HOME%Apache\conf\httpd.conf" > nul

rem Delete system environment variables set during the install
if exist "%INSITE2_HOME%\InstallOption.xml" (
	"%PERL_HOME%bin\perl" SystemEnvVars.pl delete "%INSITE2_HOME%\InstallOption.xml" > nul
)

rem Delete "%INSITE2_HOME%\CKM\tomcat\webapps\modality-csd\usapps\bin" from PATH
echo Deleting %INSITE2_HOME%\CKM\tomcat\webapps\modality-csd\usapps\bin from PATH
SetEnv.exe -d PATH ~"%INSITE2_HOME%\CKM\tomcat\webapps\modality-csd\usapps\bin" > nul

rem Delete INSITE_HOME evironment variable
SetEnv.exe -d INSITE_HOME > nul
set INSITE_HOME=

echo Deleting files and directories
if exist "%WebAppsDir%\modality-csd" (
	rd /S /Q "%WebAppsDir%\modality-csd" > nul 2>&1
)

rem Delete all old agent configurations and tesmplates directory in the default agent configuration directory.
rem This is to ensure that this uninstallation will restore all the configurations to the original state.
del /q /f "%INSITE2_ROOT_DIR%\etc\*.*" > nul 2>&1
rd /q /s "%INSITE2_ROOT_DIR%\etc\templates" > nul 2>&1
rem Restore the original agent configuration files and folders from the back_up directory.
move /y "%INSITE2_ROOT_DIR%\etc\back_up\*.*" "%INSITE2_ROOT_DIR%\etc" > nul 2>&1
move /y "%INSITE2_ROOT_DIR%\etc\back_up\templates" "%INSITE2_ROOT_DIR%\etc" > nul 2>&1

rem Delete INSITE2_DATA_DIR evironment variable
SetEnv.exe -d INSITE2_DATA_DIR > nul
set INSITE2_DATA_DIR=

rem ********************************************
rem Uninstall Service platform Windows Services.
rem ********************************************

echo Uninstalling Service Platform Windows Service(s) if installed.
call "%INSITE2_HOME%\Uninstall\RuntimeDir.bat" > nul 2>&1

if exist "%INSITE2_HOME%\bin\RFSService.exe" (
	"%DotNetDir%InstallUtil.exe" /u "%INSITE2_HOME%\bin\RFSService.exe" > nul
)

if exist "%INSITE2_HOME%\bin\ELRService.exe" (
	"%DotNetDir%InstallUtil.exe" /u "%INSITE2_HOME%\bin\ELRService.exe" > nul
)

if exist "%INSITE2_HOME%\bin\InCpProxyService.exe" (
	"%DotNetDir%InstallUtil.exe" /u "%INSITE2_HOME%\bin\InCpProxyService.exe" > nul
)

rem *******************
rem Uninstall Distinct.
rem *******************

echo Uninstalling Distinct if installed

rem Delete distinct path variable "C:\PROGRA~1\Distinct\Monitor" from PATH
echo Deleting C:\PROGRA~1\Distinct\Monitor from PATH
SetEnv.exe -d PATH ~"C:\PROGRA~1\Distinct\Monitor" > nul

if exist "%DISTINCTPROG%" (
	msiexec.exe /qn /x {EA650877-60F5-11D5-820A-00A024E0013C}
)

echo Uninstalling VNC if installed
set VNCUninstall=%INSITE2_HOME%\UltraVNC\unins000.exe
if exist "%VNCUninstall%" (
   "%VNCUninstall%" /verysilent
   rem Remove VNC related registries
   rem reg delete HKLM\SOFTWARE\RealVNC /f > nul 2>&1
   rem reg delete HKCU\SOFTWARE\RealVNC /f > nul 2>&1
)

echo Uninstalling RFS if installed
if exist "%INSITE2_HOME%\RFS" (
	rd /S /Q "%INSITE2_HOME%\RFS" > nul 2>&1
)

rem remove desktop and startmenu shortcuts for actDeactTool
echo Removing shortcuts
if exist delactdeactshortcut.bat (
    call delactdeactshortcut.bat
)
if exist delactdeactstartmenu.bat (
    call delactdeactstartmenu.bat
)
call delshort.bat > nul 2>&1

echo Uninstalling standalone AgentConfig if installed
if exist "%INSITE2_HOME%\AgentConfig" (
	rd /S /Q "%INSITE2_HOME%\AgentConfig" > nul 2>&1
)

echo Uninstalling BackupRestore if installed
if exist "%INSITE2_HOME%\BackupRestore" (
	echo Uninstalling BackupRestore 
	rd /S /Q "%INSITE2_HOME%\BackupRestore" > nul 2>&1
)

echo Uninstalling install directory
if exist "%INSITE2_HOME%\install" (
	rd /S /Q "%INSITE2_HOME%\install" > nul 2>&1
)

echo Uninstalling Utilities
rem Delete "%INSITE2_HOME%\bin" from PATH
echo Deleting %INSITE2_HOME%\bin from PATH
SetEnv.exe -d PATH ~"%INSITE2_HOME%\bin" > nul


rem Delete "%INSITE2_HOME%\bin" directory
if not "%INSITE2_HOME%" == "" (
	if exist "%INSITE2_HOME%\bin" (
		rd /S /Q "%INSITE2_HOME%\bin" > nul 2>&1
	)
)

rem Delete "%INSITE2_HOME%\Temp" directory
if not "%INSITE2_HOME%" == "" (
	if exist "%INSITE2_HOME%\Temp" (
		rd /S /Q "%INSITE2_HOME%\Temp" > nul 2>&1
	)
)

rem
rem remove registry entries from Uninstall registry for Add/Remove programs
rem Notice that removing the key removes the subkeys.  We can always attempt to
rem remove the keys because there can only be one service platform install and
rem the "> nul 2>&1" avoids ugly output if the key doesn't exist
rem 
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\InSite ExC %DeviceType%" /f > nul 2>&1  

rem remove UpdateAgentConfig.time registry Key from Registry entry
rem this is fix for Uninstall Insite2 Service platfrom before restart. 
rem Just to make sure no registry keys left by Service Paltfrom. Ref SPR # FBUG124531  

echo Deleting UpdateAgentregistry Keys
for /f "tokens=1" %%x in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce^|find /i "UpdateAgentConfig"') do reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v %%x /f > nul 2>&1
     
:end
echo Uninstalled Service Applications Successfully. 
echo.
