@echo off
rem        Batch file for:
rem             Service Apps which includes:
rem                 Utilities Install
rem                 VNC Install
rem                 Distinct Install
rem                 RFS Install
rem                 Service Platform Windows Services Install:
rem                    ELRService
rem                    RFSService
rem                    InCpProxyService
rem                 CSD Install

if .%1%==.-h (
	echo Usage: InstallSvcApps [Install Option XML]
	echo.
	echo [Install Option XML]: Optional. InstallOption.xml will be used as the default if not specified.
	echo INSITE2_HOME environment variable must exist.
	echo Install results will be logged in "%%INSITE2_HOME%%\Install.log".
	echo Example: InstallSvcApps InstallOption2.xml
	echo.
	goto End
)

if not "%INSITE2_HOME%"=="" (
	if not "%WIP_HOME%"=="" (
		set WebAppsDir=%WIP_HOME%tomcat\webapps
	)
	goto instSvcApps
)

echo InSite2 does not exist or not installed properly.  
goto errorEnd

:instSvcApps
echo Installing Service Applications

rem Make %TEMP% folder if it doesn't exist
if not "%TEMP%"=="%INSITE2_HOME%\IS2Temp" (
	if not exist "%TEMP%" (
		set OLDTEMP=%TEMP%
		set TEMP=%INSITE2_HOME%\IS2Temp
	)
)
if not exist "%TEMP%" (
	md "%TEMP%" > nul
)

set outfile="%INSITE2_HOME%\Install.log"
set InstallOptionXML=%1%
if .%InstallOptionXML%==. (
	set InstallOptionXML=InstallOption.xml	
)
set StoppingComponents=No
set CurrentDir=%CD%
if exist "%WebAppsDir%\modality-csd\usapps\PCDoctor\bin\pcd.exe" (
	echo Stopping PC Doctor
	echo Stopping PC Doctor >> %outfile%
	cmd /c "cd /d %WebAppsDir%\modality-csd\usapps\PCDoctor\bin & pcd.exe Stop" >> %outfile%
	set StoppingComponents=Yes
)
if exist "%WIP_HOME%CookieMonster.bat" (
	echo Stopping Apache/Tomcat Web Server
	echo Stopping Apache/Tomcat Web Server >> %outfile%
	cd /d "%WIP_HOME%"
	call CookieMonster.bat stop >> %outfile%
	cd /d "%CurrentDir%"
	set StoppingComponents=Yes
)
	
if exist "%INSITE2_ROOT_DIR%\bin\qsaMain.exe" (
	echo Stopping Questra Agent
	echo Stopping Questra Agent >> %outfile%
	"%INSITE2_ROOT_DIR%\bin\qsaMain.exe" -service qsa -stop > nul
	taskkill /f /im qsaMain.exe > nul 2>&1
	set StoppingComponents=Yes
)
	
if exist "%INSITE2_HOME%\bin\ComponentControl.exe" (
	"%INSITE2_HOME%\bin\ComponentControl.exe" -vnc -isinstalled -s
	if ERRORLEVEL 1 (
		echo Stopping VNC
		echo Stopping VNC >> %outfile%
		"%INSITE2_HOME%\bin\ComponentControl.exe" -vnc -stop -s
		set StoppingComponents=Yes
	)
)

reg query "HKLM\SYSTEM\CurrentControlSet\Services\TlntSvr" > nul 2>&1
if not ERRORLEVEL 1 (
	echo Stopping Telnet
	echo Stopping Telnet >> %outfile%
	sc stop TlntSvr > nul
	set StoppingComponents=Yes
)

rem
rem Stop Legacy Services
rem
if exist "%INSITE2_HOME%\bin\ServicePlatform.exe" (
	echo Stopping Service Platform Windows Service^(s^)
	echo Stopping Service Platform Windows Service^(s^) >> %outfile%
	sc stop RFSService > nul
	sc stop EventLogReader > nul
	set StoppingComponents=Yes
)

rem
rem Stop all of the currently installed Platform Services.
rem
if exist "%INSITE2_HOME%\bin\ELRService.exe" (
	echo Stopping ELR Service
	echo Stopping ELR Service >> %outfile%
	sc stop ELRService > nul
	set StoppingComponents=Yes
)

if exist "%INSITE2_HOME%\bin\RFSService.exe" (
	echo Stopping RFS Service
	echo Stopping RFS Service >> %outfile%
	sc stop RFSService > nul
	set StoppingComponents=Yes
)

if exist "%INSITE2_HOME%\bin\InCpProxyService.exe" (
	echo Stopping INCP Proxy Service
	echo Stopping INCP Proxy Service >> %outfile%
	sc stop InCpProxyService > nul
	set StoppingComponents=Yes
)

if "%StoppingComponents%"=="Yes" (
	rem Sleep for about 10 seconds
	ping 1.1.1.1 -n 5 -w 500 > nul
)

echo Setting system environment variables from %InstallOptionXML%
echo Setting system environment variables from %InstallOptionXML% >> %outfile%
"%PERL_HOME%bin\perl" SystemEnvVars.pl set %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto errorEnd

echo Set the system environment variables locally, so they can be used during the install >> %outfile%
"%PERL_HOME%bin\perl" LocalEnvVars.pl %InstallOptionXML% "%TEMP%\InstallEnvVars.bat" SystemEnvVars >> %outfile%
if ERRORLEVEL 1 goto errorEnd
call "%TEMP%\InstallEnvVars.bat" >> %outfile%

echo Set the local environment variables that will be used in various configurations >> %outfile%
"%PERL_HOME%bin\perl" LocalEnvVars.pl %InstallOptionXML% "%TEMP%\InstallEnvVars.bat" >> %outfile%
if ERRORLEVEL 1 goto errorEnd
call "%TEMP%\InstallEnvVars.bat" >> %outfile%
rem Copy InstallEnvVars.bat file to the install root directory for reference
copy /y "%TEMP%\InstallEnvVars.bat" "%INSITE2_HOME%" >> %outfile%
del /f "%TEMP%\InstallEnvVars.bat"

echo Copying Un-install related files
if not exist "%INSITE2_HOME%\Uninstall" (
	md "%INSITE2_HOME%\Uninstall"
)

copy /y UninstallSvcApps.bat "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y update_conf.pl "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y SystemEnvVars.pl "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y SetEnv.exe "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y UninstallSvcPlatform.bat "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y sc.exe "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y reg.exe "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y delshort.vbs "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y delshort.bat "%INSITE2_HOME%\Uninstall" >> %outfile%

echo Checking whether AddRemovePrograms entry is configured to be installed
echo Checking whether AddRemovePrograms entry is configured to be installed >> %outfile%
"%PERL_HOME%bin\perl" InstallOption.pl AddRemovePrograms %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto installUtilities
    echo Add/Remove Programs entry configured to be installed
    echo Add/Remove Programs entry configured to be installed >> %outfile%

echo Adding Add/Remove Programs entry for UNinstall 
echo Adding Add/Remove Programs entry for UNinstall >> %outfile%
rem 
rem If there is an existing entry overwrite it. Existing entry was likely to be created in error.
rem
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\InSite ExC "%DeviceType% /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\InSite ExC "%DeviceType% /v DisplayName /t REG_EXPAND_SZ /d "InSite ExC" /f 
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\InSite ExC "%DeviceType% /v DisplayVersion /t REG_EXPAND_SZ /d "%Version%" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\InSite ExC "%DeviceType% /v UninstallString /t REG_EXPAND_SZ /d "cmd /C cd /D %INSITE2_HOME% && cd Uninstall && uninstallsvcplatform.bat -n -DeviceType %DeviceType%" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\InSite ExC "%DeviceType% /v InstallLocation /t REG_EXPAND_SZ /d "\"%INSITE2_HOME% \"" /f

:installUtilities
echo Installing Utilities
echo Installing Utilities >> %outfile%

if not exist "%INSITE2_HOME%\bin" (
	md "%INSITE2_HOME%\bin"
)
if not exist "%INSITE2_HOME%\Temp" (
	md "%INSITE2_HOME%\Temp"
)
echo Updating PATH environment variable >> %outfile%
SetEnv.exe -a PATH ~"%INSITE2_HOME%\bin" >> %outfile%
set PATH=%PATH%;%INSITE2_HOME%\bin
if ERRORLEVEL 1 goto errorEnd

rem Copy %InstallOptionXML% file to the install root directory, so we know what options are selected
copy /y %InstallOptionXML% "%INSITE2_HOME%\InstallOption.xml" >> %outfile%

rem Copy the version file to the install root directory, so we know what version of Service Platform is installed
copy /y SVCPFORMVERSION "%INSITE2_HOME%" >> %outfile%

rem Copy some generic utilities to %INSITE2_HOME%\bin
copy /y Utils\ConnectStatus.dll "%INSITE2_HOME%\bin" > nul

"%PERL_HOME%bin\perl" InstallOption.pl AltInstall %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 (
	copy /y Utils\ComponentControl.exe "%INSITE2_HOME%\bin" > nul
	copy /y StartComp.bat "%INSITE2_HOME%\bin" > nul
	echo Registering ComponentControl.exe >> %outfile%
	"%INSITE2_HOME%\bin\ComponentControl.exe" /RegServer
	"%INSITE2_HOME%\bin\ComponentControl.exe" /regeventsrc

	if exist Utils\VNC_Config.xml (
		echo Installing configuration for external VNC installation >> %outfile%
		copy /y Utils\VNC_Config.xml "%INSITE2_HOME%\bin" > nul
	)

	rem .NET apps that access ComponentControl need this Wrapper DLL.
	if exist Utils\Interop.ComponentControlLib.dll (
		copy /y Utils\Interop.ComponentControlLib.dll "%INSITE2_HOME%\bin" > nul
	)
)

if exist Utils\SystemStatus.exe (
	copy /y Utils\SystemStatus.exe "%INSITE2_HOME%\bin" > nul
)

copy /y GetSerialNumber.bat "%INSITE2_HOME%\bin" > nul
copy /y InstallOption.pl "%INSITE2_HOME%\bin" > nul
copy /y SetWebServerSec.pl "%INSITE2_HOME%\bin" > nul
copy /y SetSecurity.bat "%INSITE2_HOME%\bin" > nul
copy /y zip.exe "%INSITE2_HOME%\bin" > nul
copy /y csdmain.html "%INSITE2_HOME%\bin" > nul
copy /y csdmain.hta "%INSITE2_HOME%\bin" > nul

rem Check if Custom Browser is configured to be installed
"%PERL_HOME%bin\perl" InstallOption.pl CustomBrowser %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 (
	goto instVNC
)

copy /y Utils\CustomBrowser.exe "%INSITE2_HOME%\bin" > nul
copy /y Utils\CustomBrowserConfig.xml "%INSITE2_HOME%\bin" > nul
copy /y Utils\NormInternetExplorer.reg "%INSITE2_HOME%\bin" > nul

echo Registering CustomBrowser.exe >> %outfile%
"%INSITE2_HOME%\bin\CustomBrowser.exe" /RegServer
if ERRORLEVEL 1 (
	echo Please check if CustomBrowser.exe is installed in "%INSITE2_HOME%\bin" directory
	echo Please check if CustomBrowser.exe is installed in "%INSITE2_HOME%\bin" directory >> %outfile%
	echo If they are, make sure "MSXML 4.0 SP2" is installed in the system
	echo If they are, make sure "MSXML 4.0 SP2" is installed in the system >> %outfile%
	goto errorEnd
)
echo Configuring CustomBrowser using %InstallOptionXML% >> %outfile%
"%PERL_HOME%bin\perl" UpdateBrowserConfig.pl %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto errorEnd

:instVNC
rem Check if VNC is configured to be installed
"%PERL_HOME%bin\perl" InstallOption.pl VNC %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto instRFS
echo Installing VNC
echo Installing VNC >> %outfile%
rem This reg file will deselect the service registration tasks in the install
regedit /s VNCInstall.reg
vnc-4_1_1-x86_win32.exe /verysilent /dir="%INSITE2_HOME%\VNC" /loadinf="%CD%\VNCInstall.inf"

:instRFS
rem Check if RFS is configured to be installed
"%PERL_HOME%bin\perl" InstallOption.pl RFS %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto instDistinct
echo Installing RFS
echo Installing RFS >> %outfile%
if not exist "%INSITE2_HOME%\RFS" (
	md "%INSITE2_HOME%\RFS"
)

xcopy /y /q /e RFS "%INSITE2_HOME%\RFS" > nul
copy /y Utils\RFSCommon.dll "%INSITE2_HOME%\bin" > nul
copy /y Utils\ConfigRFS.exe "%INSITE2_HOME%\bin" > nul
copy /y Utils\MachineRFS.* "%INSITE2_HOME%\bin" > nul

:instDistinct
rem Check if Distinct is configured to be installed
"%PERL_HOME%bin\perl" InstallOption.pl Distinct %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto instServicePlatformServices
set DISTINCTPROG=C:\Program Files\Distinct\Monitor\Monitor.exe
set SNIFFERLOG=%LogDir%\Sniffer
if not exist "%DISTINCTPROG%" (
    rem Only install if not already installed, otherwise there will be a pop-up to uninstall
    echo Installing Distinct Network Monitor
	echo Installing Distinct Network Monitor >> %outfile%
	
	rem Add C:\PROGRA~1\Distinct\Monitor to the Path so that Monitor.exe read proerly by CSD
	echo Updating PATH environment variable for Distinct Monitor utility >> %outfile%
	SetEnv.exe -a PATH ~"C:\PROGRA~1\Distinct\Monitor" >> %outfile%
	set PATH=%PATH%;C:\PROGRA~1\Distinct\Monitor

	if not exist "%SNIFFERLOG%" md "%SNIFFERLOG%"
	DistinctInstall.exe  /s /v" /qn" >> %outfile%
	if ERRORLEVEL 1 goto distinctError
) else ( 
	echo Distinct Network Monitor is already installed. 
	echo Distinct Network Monitor is already installed. >> %outfile% 
)
	echo Update Monitor.exe to Vista compatible version
	echo Update Monitor.exe to Vista compatible version >> %outfile%
	copy /y Monitor.exe "%DISTINCTPROG%" > nul
	goto instServicePlatformServices

:distinctError
echo Error Installing Distinct Network Monitor
echo Error Installing Distinct Network Monitor >> %outfile%
goto errorEnd

rem ******************************************
rem Install Service Platform Windows Services.
rem ******************************************

:instServicePlatformServices
echo Installing Service Platform Windows Services
echo Installing Service Platform Windows Services >> %outfile%

rem Set .NET Framework directory to "DotNetDir" local environment variable.
rem  Will use "InstallUtil.exe" tool (in "DotNetDir") to install the windows services.
GetRuntimeDir.exe /set > "%TEMP%\RuntimeDir.bat"
call "%TEMP%\RuntimeDir.bat"
rem Copy the batch file that sets "DotNetDir" local environment variable to the Uninstall directory for later use during uninstallation.
copy /y "%TEMP%\RuntimeDir.bat" "%INSITE2_HOME%\Uninstall" >> %outfile%
del /f "%TEMP%\RuntimeDir.bat"

set FailedServices=

rem Check if RFS Service is configured to be installed.
"%PERL_HOME%bin\perl" InstallOption.pl RFSService %InstallOptionXML% >> %outfile%
if not ERRORLEVEL 1 (
	echo Installing RFS Service
	echo Installing RFS Service >> %outfile%
	copy /y Utils\RFSService.exe "%INSITE2_HOME%\bin" > nul

	"%DotNetDir%InstallUtil.exe" /LogFile=%outfile% "%INSITE2_HOME%\bin\RFSService.exe" > nul
	if ERRORLEVEL 1 (
		set FailedServices=YES
		echo Service Install Error: RFS Service
		echo Service Install Error: RFS Service >> %outfile%
	)
)

rem Check if Event Log Reader (ELR) Service is configured to be installed.
"%PERL_HOME%bin\perl" InstallOption.pl EventLogReader %InstallOptionXML% >> %outfile%
if not ERRORLEVEL 1 (
	echo Installing ELR Service
	echo Installing ELR Service >> %outfile%
	copy /y Utils\ELRService.exe "%INSITE2_HOME%\bin" > nul
	copy /y Utils\EventLogReader.exe "%INSITE2_HOME%\bin" > nul
	rem Uncomment out these lines when the elReader_config tool is ready
	rem copy /y Utils\elReader_config.xml "%INSITE2_HOME%\bin" > nul
	rem copy /y Utils\elr_config_tool_config.xml  "%INSITE2_HOME%\bin" > nul

	"%DotNetDir%InstallUtil.exe" /LogFile=%outfile% "%INSITE2_HOME%\bin\ELRService.exe" > nul
	if ERRORLEVEL 1 (
		set FailedServices=YES
		echo Service Install Error: ELR Service
		echo Service Install Error: ELR Service >> %outfile%
	)
)

rem Check if INCP Proxy Service is configured to be installed.
"%PERL_HOME%bin\perl" InstallOption.pl InCpProxyService %InstallOptionXML% >> %outfile%
if not ERRORLEVEL 1 (
	echo Installing INCP Proxy Service
	echo Installing INCP Proxy Service >> %outfile%
	copy /y Utils\InCpProxyService.exe "%INSITE2_HOME%\bin" > nul
	copy /y Utils\InCpProxyConfig.xml "%INSITE2_HOME%\bin" > nul

	"%DotNetDir%InstallUtil.exe" /LogFile=%outfile% "%INSITE2_HOME%\bin\InCpProxyService.exe" > nul
	if ERRORLEVEL 1 (
		set FailedServices=YES
		echo Service Install Error: INCP Proxy Service
		echo Service Install Error: INCP Proxy Service >> %outfile%
	)
)

if "%FailedServices%"=="" goto instSWManagement

echo Error Installing Service Platform Windows Services
echo Error Installing Service Platform Windows Services >> %outfile%
goto errorEnd

rem **********************
rem Install SW Management.
rem **********************

:instSWManagement
rem Check if SWManagement is configured to be installed
"%PERL_HOME%bin\perl" InstallOption.pl SWManagement %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto instPackageRepository
echo Installing SWManagement
echo Installing SWManagement >> %outfile%
copy /y Utils\grubbouncer.exe "%INSITE2_HOME%\bin" > nul
copy /y Utils\grubmount.exe "%INSITE2_HOME%\bin" > nul
copy /y Utils\grubsync.exe "%INSITE2_HOME%\bin" > nul
copy /y Utils\ApplyPatchList.exe "%INSITE2_HOME%\bin" > nul

:instPackageRepository
"%PERL_HOME%bin\perl" InstallOption.pl PKGRepository %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto instDockDevices
echo Installing Package Repository
echo Installing Package Repository >> %outfile%

if "%INSITE2_PKGREPOS_DIR%"=="" (
   SetEnv.exe -d INSITE2_PKGREPOS_DIR
   SetEnv.exe -a INSITE2_PKGREPOS_DIR "%PKGREPOS_HOMEDIR%\PkgRepository"
   set INSITE2_PKGREPOS_DIR=%PKGREPOS_HOMEDIR%\PkgRepository

   echo Adding %PKGREPOS_HOMEDIR%\PkgRepository\bin to PATH env var.

   SetEnv.exe -a PATH ~"%PKGREPOS_HOMEDIR%\PkgRepository\bin"
   set PATH=%PATH%;%INSITE2_PKGREPOS_DIR%\bin
)

pushd .\PkgRepository
call PkgReposInstall.bat
popd

:instDockDevices
"%PERL_HOME%bin\perl" InstallOption.pl DockDevices %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto instSvcWebApps
echo installing Dockable Device Components
echo installing Dockable Device Components >> %outfile%

pushd .\VirtualDevices
call VirtualDevicesInstall.bat
popd

:instSvcWebApps
rem Check if web applications are configured to be installed
"%PERL_HOME%bin\perl" InstallOption.pl WebApps %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto checkShortCut

rem Check if WebAppsDir variable is set. If not set, Web Apps cannot be installed.
if "%WebAppsDir%"=="" (
	echo Web Server is not installed or not installed properly. Web Apps cannot be installed.
	echo Web Server is not installed or not installed properly. Web Apps cannot be installed. >> %outfile%
	goto errorEnd 
)

echo Installing Service Web Apps
echo Installing Service Web Apps in %WebAppsDir% >> %outfile%

echo Copying files
echo Copying CSD files >> %outfile%

cd /d "%WebAppsDir%"
if exist modality-csd (
	rd /S /Q modality-csd
)
	
md modality-csd
cd modality-csd
rem if VERSION exists in CSD folder. It is a file that not dynamically built by VS
rem It is assumed then that the entire csd has been copied over
if exist "%CurrentDir%\csd\VERSION" (
	xcopy /E /Q "%CurrentDir%\csd"
	cd /d "%CurrentDir%"
) else (
	echo CSD files do not exist.
	echo CSD files do not exist. >> %outfile%
	cd /d "%CurrentDir%"
	goto errorEnd
)


echo Setting INSITE_HOME environment variable
echo Setting INSITE_HOME environment variable >> %outfile%
rem This variable is used in some install perl scripts below and in Java codes of the web apps.
SetEnv.exe -a INSITE_HOME "%WebAppsDir%\modality-csd\usapps" >> %outfile%
if "%INSITE_HOME%"=="" (
	set INSITE_HOME=%WebAppsDir%\modality-csd\usapps
)
if ERRORLEVEL 1 goto errorEnd

echo Updating PATH environment variable
echo Updating PATH environment variable >> %outfile%
SetEnv.exe -a PATH ~"%WebAppsDir%\modality-csd\usapps\bin" >> %outfile%
set PATH=%PATH%;%WebAppsDir%\modality-csd\usapps\bin
if ERRORLEVEL 1 goto errorEnd
	
echo Updating Apache/Tomcat Web Server Configuration File using httpd_us.conf
echo Updating Apache/Tomcat Web Server Configuration File using httpd_us.conf >> %outfile%
rem Add ultrasound specific entries to httpd.conf file.
rem If it has ultrasound specific entries already, those entries will be deleted first.
"%PERL_HOME%bin\perl" update_conf.pl "%WIP_HOME%Apache\conf\httpd.conf" >> %outfile%
"%PERL_HOME%bin\perl" ReplaceEnvVars.pl httpd_us.conf "%WIP_HOME%Apache\conf\httpd.conf" >> %outfile%
if ERRORLEVEL 1 goto errorEnd

echo Updating web.xml file of CSD web app with evironment variables >> %outfile%
set WebXML=%WebAppsDir%\modality-csd\WEB-INF\web.xml
set WebXMLOld=%WebAppsDir%\modality-csd\WEB-INF\web.xml.old 
ren "%WebXML%" web.xml.old
"%PERL_HOME%bin\perl" ReplaceEnvVars.pl "%WebXMLOld%" "%WebXML%" >> %outfile%
del /f "%WebXMLOld%"
if ERRORLEVEL 1 goto errorEnd

echo Updating files of CSD and Apache to listen on selected port
echo Updating files of CSD and Apache to listen on selected port >> %outfile%
"%PERL_HOME%bin\perl" UpdateWebPort.pl %WebPort%

echo Updating files of web server to bind tomcat to selected port
echo Updating files of web server to bind tomcat to selected port >> %outfile%
"%PERL_HOME%bin\perl" UpdateTomcatPort.pl %TomcatPort%

echo Updating all perl CGI scripts to have the correct perl.exe path >> %outfile%
"%PERL_HOME%bin\perl" ReplaceEnvVars.pl ReplaceVars.dat "%TEMP%\ReplaceVars.dat" >> %outfile%
if exist "%TEMP%\cgi-bin" (
	rd /s /q "%TEMP%\cgi-bin"
)
md "%TEMP%\cgi-bin"
cd /d "%WebAppsDir%\modality-csd\usapps"
cscript "%CurrentDir%\FixCgiPath.js" -InputFileList "%CurrentDir%\cgibinFiles.dat" -OutputDir "%TEMP%\cgi-bin" -d "%TEMP%" >> %outfile%
xcopy /y /q "%TEMP%\cgi-bin\*.*" .\cgi-bin >> %outfile%
cd /d "%CurrentDir%"
rd /s /q "%TEMP%\cgi-bin"
del /f "%TEMP%\ReplaceVars.dat"

rem Create the log directory used for Log Viewer and Legacy Diagnostics (including PC Doctor Diagnostics), if it doesn't exist
if not exist "%LogDir%" md "%LogDir%"

if not exist "%SystemRoot%\system32\cmdlib.wsc" (
	echo Copying cmdlib.wsc to "%SystemRoot%\system32" directory.  This file is needed for the Event Log Viewer utility. >> %outfile%
	copy /y cmdlib.wsc "%SystemRoot%\system32\cmdlib.wsc" >> %outfile%
)
rem Register cmdlib.wsc.  Some XP embedded systems don't have this component registered.  So this is to make sure it's registered.
echo Registering cmdlib.wsc >> %outfile%
regsvr32 /s /i:"%SystemRoot%\system32\cmdlib.wsc" "%SystemRoot%\system32\scrobj.dll" > nul 2>&1

:checkShortCut
echo Checking if CSD Shortcut is requested.
echo Checking if CSD Shortcut is requested. >> %outfile%

"%PERL_HOME%bin\perl" InstallOption.pl ShortCut %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto checkActivateDeactivate

echo Creating CSD ShortCut using %InstallOptionXML%
echo Creating CSD ShortCut using %InstallOptionXML% >> %outfile%
call creshort.bat %WebPort%

:checkActivateDeactivate
echo Checking if ActivateDeactivate Tool is requested.
echo Checking if ActivateDeactivate Tool is requested. >> %outfile%

"%PERL_HOME%bin\perl" InstallOption.pl ActDeactTool %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto checkStandaloneAgentConfig

echo Installing ActDeactTool in the bin directory
echo Installing ActDeactTool in the bin directory >> %outfile%
copy /y Utils\ActDeactTool.exe "%INSITE2_HOME%\bin" >> %outfile%
copy /y Utils\ActDeactToolConfig.xml "%INSITE2_HOME%\bin" >> %outfile%
copy /y Utils\ActDeactToolDictionary.xml "%INSITE2_HOME%\bin" >> %outfile%
"%INSITE2_HOME%\bin\ActDeactTool.exe" /regeventsrc

:checkStandaloneAgentConfig
echo Checking if StandaloneAgentConfig is configured to be installed
echo Checking if StandaloneAgentConfig is configured to be installed >> %outfile%

"%PERL_HOME%bin\perl" InstallOption.pl StandaloneAgentConfig %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto checkBackupRestore

echo Installing AgentConfig files
echo Installing AgentConfig files >> %outfile%
xcopy /y /q /e "AgentConfig" "%INSITE2_HOME%\AgentConfig\" >> %outfile%


:checkBackupRestore
echo Checking if BackupRestore is configured to be installed
echo Checking if BackupRestore is configured to be installed >> %outfile%

"%PERL_HOME%bin\perl" InstallOption.pl BackupRestore %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto checkDisruptiveMode

echo Installing BackupRestore files
echo Installing BackupRestore files >> %outfile%
copy /y BackupRestore\CSBackupRestore.bat "%INSITE2_HOME%\bin" >> %outfile%
rem xcopy /y /s "%INSITE2_HOME%\BackupRestore" "%INSITE2_HOME%\BackupRestore\" >> %outfile%
xcopy /y /q /e BackupRestore "%INSITE2_HOME%\BackupRestore\" >> %outfile%
del /q /f "%INSITE2_HOME%\BackupRestore\CSBackupRestore.bat" > nul 2>&1


:checkDisruptiveMode
@echo off

rem Check if Disruptive Mode is configured to be used or not
"%PERL_HOME%bin\perl" InstallOption.pl NoDisruptiveMode %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto configQuestra
echo Disruptive Mode not used. > "%WebAppsDir%\modality-csd\usapps\diagLogs\.noDisruptiveMode"

:configQuestra
"%PERL_HOME%bin\perl" InstallOption.pl QuestraAgent %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto configComponents

rem Check if INSITE2_ROOT_DIR variable is set. If not set, Questra Agent cannot be configured.
if "%INSITE2_ROOT_DIR%"=="" (
	echo Questra Agent is not installed or not installed properly. Questra Agent cannot be configured.
	echo Questra Agent is not installed or not installed properly. Questra Agent cannot be configured. >> %outfile%
	goto errorEnd 
)

echo Configuring Questra Agent using %InstallOptionXML%
echo Configuring Questra Agent using %InstallOptionXML% >> %outfile%
rem Create the log directory used for Custom Logger and possibly for Virtual Directory (if it's not changed from default), if it doesn't exist
if not exist "%LogDir%" md "%LogDir%"
rem If INSITE2_DATA_DIR environment variable is not set, just use INSITE2_ROOT_DIR as INSITE2_DATA_DIR
if "%INSITE2_DATA_DIR%"=="" (
	SetEnv.exe -a INSITE2_DATA_DIR "%INSITE2_ROOT_DIR%" >> %outfile%
	set INSITE2_DATA_DIR=%INSITE2_ROOT_DIR%
)
rem Create the custom directory to store the agent configuration.
if not exist "%INSITE2_DATA_DIR%\etc" md "%INSITE2_DATA_DIR%\etc"
rem Create a back_up directory in the default agent configuration directory.
if not exist "%INSITE2_ROOT_DIR%\etc\back_up" md "%INSITE2_ROOT_DIR%\etc\back_up"
rem If the original agent configuration files were not backed up,
if not exist "%INSITE2_ROOT_DIR%\etc\back_up\sitemap.xml" (
	rem Backup the original agent configuration files and folders from the default agent configuration directory to the back_up directory.
	rem Move instead of Copy to lessen the developer's confusion, so they would see empty "%INSITE2_ROOT_DIR%\etc" directory .
	move /y "%INSITE2_ROOT_DIR%\etc\*.*" "%INSITE2_ROOT_DIR%\etc\back_up" > nul 2>&1
	move /y "%INSITE2_ROOT_DIR%\etc\templates" "%INSITE2_ROOT_DIR%\etc\back_up" > nul 2>&1
)	else (
	rem If reached here, it means that the Service Platform was not uninstalled before this installation.
	rem Delete anything in "%INSITE2_ROOT_DIR%\etc" since this default agent configuration directory might have been used instead of defining INSITE2_DATA_DIR in previous installation
	rem and we don't want to overwrite the original sitemap.xml backed up with the modified one in the next step if INSITE2_DATA_DIR is not being used again. (ie. INSITE2_DATA_DIR==INSITE2_ROOT_DIR)
	del /q /f "%INSITE2_ROOT_DIR%\etc\*.*" > nul 2>&1
	rd /q /s "%INSITE2_ROOT_DIR%\etc\templates" > nul 2>&1
)
rem If sitemap.xml file exists in the custom agent configuration directory, back it up, so it can be restored later
if exist "%INSITE2_DATA_DIR%\etc\sitemap.xml" (
	rem Create a back_up directory in the InSite2 Data directory.
	if not exist "%INSITE2_DATA_DIR%\etc\back_up" md "%INSITE2_DATA_DIR%\etc\back_up"
	copy /y "%INSITE2_DATA_DIR%\etc\sitemap.xml" "%INSITE2_DATA_DIR%\etc\back_up" >> %outfile%
	rem Delete all old agent configurations and tesmplates directory
	del /q /f "%INSITE2_DATA_DIR%\etc\*.*" > nul 2>&1
	rd /q /s "%INSITE2_DATA_DIR%\etc\templates" > nul 2>&1
)
echo Copy the default agent configuration files and folders to the InSite2 Data directory. >> %outfile%
xcopy /y /q /e "%INSITE2_ROOT_DIR%\etc\back_up" "%INSITE2_DATA_DIR%\etc" >> %outfile%

echo Extracting AgentConfig.xml from %InstallOptionXML% >> %outfile%
"%PERL_HOME%bin\perl" ExtractSitemap.pl %InstallOptionXML% "%INSITE2_HOME%\Questra\AgentConfig.xml" >> %outfile%
if ERRORLEVEL 1 goto errorEnd
echo Updating versions.txt using %InstallOptionXML% >> %outfile%
"%PERL_HOME%bin\perl" UpdateVersionsTxt.pl %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto errorEnd
rem Use UpdateAgentConfig.bat to update the Questra Agent Configuration files
call UpdateAgentConfig.bat "%INSITE2_HOME%\Questra\AgentConfig.xml" >> %outfile%
if ERRORLEVEL 1 goto errorEnd
rem Copy all the files needed to run UpdateAgentConfig.bat and RestoreService.bat to Questra folder, so the batch files can be used for restoring agent configs and also for refreshing agent configs with the auto-generated DeviceName and SerialNumber
copy /y UpdateAgentConfig.bat "%INSITE2_HOME%\Questra" >> %outfile%
copy /y ReplaceEnvVars.pl "%INSITE2_HOME%\Questra" >> %outfile%
copy /y GetDeviceInfo.pl "%INSITE2_HOME%\Questra" >> %outfile%
copy /y QSAServiceCreate.bat "%INSITE2_HOME%\Questra" >> %outfile%
copy /y ExtractSitemap.pl "%INSITE2_HOME%\Questra" >> %outfile%
copy /y "%INSITE2_HOME%\InstallEnvVars.bat" "%INSITE2_HOME%\Questra" >> %outfile%
copy /y DeviceNameMatch.pl "%INSITE2_HOME%\Questra" >> %outfile%
copy /y QSAManControl.bat "%INSITE2_HOME%\Questra" >> %outfile%
copy /y checkQSAStatus.pl "%INSITE2_HOME%\Questra" >> %outfile%
rem Copy BackupService.bat and RestoreService.bat to %INSITE2_HOME%\bin folder which are to be used for Backup/Restore of service configurations.
copy /y BackupService.bat "%INSITE2_HOME%\bin" >> %outfile%
copy /y RestoreService.bat "%INSITE2_HOME%\bin" >> %outfile%
rem Copy cacls.exe needed for UpdateAgentConfig.bat (GenQSAcfg.pl) to %INSITE2_HOME%\bin folder

copy /y cacls.exe "%INSITE2_HOME%\bin" >> %outfile%
copy /y TKupdateProperty.pl "%INSITE2_HOME%\Questra"
copy /y TKremCfgProperty.pl "%INSITE2_HOME%\Questra"
copy /y TKreadCfgProperty.pl "%INSITE2_HOME%\Questra"
copy /y TKaddCfgProperty.pl "%INSITE2_HOME%\Questra"
copy /y cfgapi-lib.pl "%INSITE2_HOME%\Questra"

copy /y TKUpdateProperty.bat "%INSITE2_HOME%\bin"
copy /y TKreadCfgProperty.bat "%INSITE2_HOME%\bin"
copy /y TKremCfgProperty.bat "%INSITE2_HOME%\bin"
copy /y TKaddCfgProperty.bat "%INSITE2_HOME%\bin"

rem Unless the custom agent configuration directory is not defined,
if not "%INSITE2_DATA_DIR%"=="%INSITE2_ROOT_DIR%" (
	rem If backed up sitemap.xml file exists, restore it.
	if exist "%INSITE2_DATA_DIR%\etc\back_up\sitemap.xml" (
		echo Restoring Questra Agent Configuration files from "%INSITE2_DATA_DIR%\etc\back_up\sitemap.xml" >> %outfile%
		rem Use RestoreService.bat to restore the Questra Agent Configuration files with the backed up sitemap.xml
		rem Since RestoreService.bat will exit and return an exit code, use cmd.exe
		rem Use -noCheck option since serialNo.txt file might not have been created yet at this point, so the auto-generated DeviceName can't be compared.  The previous agent configurations
		rem remained in the data partition is trustable since they are not backed up by a user. 
		cmd.exe /c RestoreService.bat "%INSITE2_DATA_DIR%\etc\back_up" -noCheck >> %outfile%
		if ERRORLEVEL 2 (
			echo Error restoring Questra Agent Configuration files from "%INSITE2_DATA_DIR%\etc\back_up\sitemap.xml" 
			goto errorEnd
		)
	)
)

:configComponents
echo Configuring installed components using %InstallOptionXML%
echo Configuring installed components using %InstallOptionXML% >> %outfile%

"%PERL_HOME%bin\perl" InstallOption.pl AltInstall %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 (
   goto normConfig
)

echo Alternate component config called.
echo Alternate component config called. >> %outfile%
"%PERL_HOME%bin\perl" AltComponentConfig.pl %InstallOptionXML% >> %outfile%
goto configVNC

:normConfig
echo Configuring components
"%PERL_HOME%bin\perl" ComponentConfig.pl %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto errorEnd

:configVNC
rem UpdateVNCReg.pl has to be called after ComponentConfig.pl is called because default VNC registry settings are created in ComponentConfig.pl.
rem echo Configuring VNC
"%PERL_HOME%bin\perl" InstallOption.pl VNC %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto successEnd
echo Updating VNC registry settings
"%PERL_HOME%bin\perl" UpdateVNCReg.pl %VNCPort% %VNCHttpPort% >> %outfile%

:successEnd
rem Delete custom %TEMP% folder if it exists
if "%TEMP%"=="%INSITE2_HOME%\IS2Temp" (
	if exist "%TEMP%" (
		rd /s /q "%TEMP%" > nul
	)
	set TEMP=%OLDTEMP%
)

echo Installed Service Applications Successfully. 
echo Installed Service Applications Successfully. >> %outfile%
echo.

echo Starting Service Platform components that are configured to start automatically. 
echo Starting Service Platform components that are configured to start automatically. >> %outfile%
echo.

"%PERL_HOME%bin\perl" InstallOption.pl AltInstall %InstallOptionXML% >> %outfile%
if ERRORLEVEL 1 goto normStart

"%PERL_HOME%bin\perl" AltStartComponents.pl %InstallOptionXML%
goto End

:normStart
"%PERL_HOME%bin\perl" StartComponents.pl %InstallOptionXML%
goto End

:errorEnd
call UninstallSvcApps.bat > nul

echo Service Apps Install Failed. Aborting installation of Service Apps. 
echo Service Apps Install Failed. Aborting installation of Service Apps. >> %outfile%
echo.
exit /b 1
:End

