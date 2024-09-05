@echo off
rem        Batch file for:
rem  		    Insite2 Uninstall which includes:
rem		    	JRE Uninstall 
rem             Perl Uninstall
rem		    	Web Server Uninstall
rem             Questra Agent Uninstall

if "%1%"=="-h" (
	echo Usage: UninstallInsite2 [-p]
	echo.
	echo -p: JRE and Perl will not be uninstalled
	echo.
	goto END
)
set JREGUID="{26A24AE4-039D-4CA4-87B4-2F83216011F0}"
set CKMGUID="{28EBEADC-3D8A-4DCE-B8F1-9F21DEA7FC12}"

echo Uninstalling InSite2

if not "%INSITE_HOME%"=="" (
	echo Service Web Apps are not uninstalled. Uninstall Service Web Apps first.
	goto errorEnd
)

set CurrentDir=%CD%

if exist "%WIP_HOME%CookieMonster.bat" (
	echo Stopping Apache/Tomcat Web Server
	cd /d "%WIP_HOME%"
	call CookieMonster.bat stop > nul
	cd /d "%CurrentDir%"
)

if exist "%INSITE2_ROOT_DIR%\bin\qsaMain.exe" (
	echo Stopping Questra Agent
	"%INSITE2_ROOT_DIR%\bin\qsaMain" -service "qsa" -stop > nul
	"%INSITE2_ROOT_DIR%\bin\qsaMain" -service "qsa" -u > nul
	taskkill /f /im qsaMain.exe /t > nul 2>&1
)

echo Uninstalling Apache/Tomcat Web Server.
if not "%WIP_HOME%"=="" (
	msiexec.exe /qn /x %CKMGUID%
	if ERRORLEVEL 1 goto errorEnd
	rd /s /q "%WIP_HOME%" > nul 2>&1
	set WIP_HOME=
	set CATALINA_HOME=
	rem Delete Insite2 version file
	if not "%INSITE2_HOME%" == "" (
		if exist "%INSITE2_HOME%\VERSION" (
			del /f /q "%INSITE2_HOME%\VERSION"
		)
	)
	goto uninstQuestra
)
echo Apache/Tomcat Web Server does not exist or not installed properly. Apache/Tomcat Web Server uninstall is skipped.

:uninstQuestra
echo Uninstalling Questra Agent.
if not "%INSITE2_ROOT_DIR%"=="" (
	if exist QuestraUninstall.bat (
		call QuestraUninstall.bat
		if ERRORLEVEL 1 goto errorEnd
		goto uninstQuestra2
	)
	if exist .\AgentInstall\QuestraUninstall.bat (
		call .\AgentInstall\QuestraUninstall.bat
		if ERRORLEVEL 1 goto errorEnd
		goto uninstQuestra2
	)
	echo "QuestraUninstall.bat" file required for Questra Agent uninstall is not found.
	goto errorEnd	
)
echo Questra Agent does not exist or not installed properly. Questra Agent uninstall is skipped.
goto checkPartial

:uninstQuestra2
SetEnv.exe -d INSITE2_ROOT_DIR
set INSITE2_ROOT_DIR=
SetEnv.exe -d DeviceType
set DeviceType=
	
:checkPartial
rem Check for partial uninstall option
set JREUninstalled=No
if not "%1%"=="-p" (
	goto jreUninstall
)
goto successEnd	
	
:jreUninstall
if "%CKM_JAVA_HOME%"=="" (

echo CKM_JAVA_HOME does NOT exist

	if "%JAVA_HOME%"=="" (
		echo JRE does not exist or not installed properly. JRE uninstall is skipped.
		goto perlUninstall
	)
	echo Uninstalling JRE
	
	rem based on http://wpkg.org/Java Mar/18/2009 :"Java Quick Starter ... make java applications start faster...
	rem but ... it must be killed before uninstallation or installation fails..."
	rem tried out both ways, jqs couldn't be turned off like article says, throws error message,
	rem uninstallation works fine without turning jqs off. Line was left commented in code in case of problem reappearance.	
	
	rem "%JAVA_HOME%"\bin\jqs.exe -unregister
	
	msiexec.exe /qn /x %JREGUID% REBOOT=Suppress
	set JREUninstalled=Yes
	rem Delete JAVA_HOME environment variable and remove %JAVA_HOME%\bin from PATH
	SetEnv.exe -d PATH ~"%JAVA_HOME%\bin" > nul
	SetEnv.exe -d JAVA_HOME
	set JAVA_HOME=

	goto perlUninstall
)

echo ok CKM_JAVA_HOME exists and is "%CKM_JAVA_HOME%"

if exist "%TargetDir%/Java" (
	rd /s /q "%TargetDir%/Java" > nul
	SetEnv.exe -d CKM_JAVA_HOME
	set CKM_JAVA_HOME=
)

:perlUninstall
if "%PERL_HOME%"=="" (
	echo Perl does not exist or not installed properly. Perl uninstall is skipped.
	goto deleteEnvVar
)
echo Uninstalling Perl
if exist "%PERL_HOME%perl.bat" (
	call "%PERL_HOME%perl.bat" uninstall > nul
	if ERRORLEVEL 1 goto errorEnd
	set PERL_HOME=
	goto deleteEnvVar
)
echo "perl.bat" file required for Perl uninstall is not found.
goto errorEnd	

:deleteEnvVar
rem Delete INSITE2_HOME environment variable
set TargetDir=%INSITE2_HOME%
SetEnv.exe -d INSITE2_HOME
set INSITE2_HOME=

rem Added following code to delete INSITE2_HOME\Uninstall folder if the 
echo Testing whether there is an Export directory
if exist "%TargetDir%\Export" (
	echo Export dir exists
	if "%CD%"=="%TargetDir%\Uninstall" (
		echo moving to the the targetdir
		pushd "%TargetDir%"
	)
	echo Removing the Uninstall and other directories
	rd /s /q "%TargetDir%\Uninstall" > nul 2>&1
	rd /s /q "%TargetDir%\Install" > nul 2>&1
	rd /s /q "%TargetDir%\Perl" > nul 2>&1
	rd /s /q "%TargetDir%\bin" > nul 2>&1

	if exist "%TargetDir%\Log" (
		rd /s /q "%TargetDir%\Log" > nul 2>&1
	)
) else (
	if not "%TargetDir%" == "" (
		rem Delete INSITE2_HOME folder only if this script is not called from that folder
 		if not "%CD%"=="%TargetDir%\Uninstall" (
 			rd /s /q "%TargetDir%" > nul 2>&1
 		)
	)
)

:successEnd
echo Uninstalled InSite2 Successfully. 
if "%JREUninstalled%" == "Yes" ( 
	echo NOTE: Please RESTART the system to completely uninstall JRE.
)
echo.
goto End

:errorEnd
echo InSite2 Uninstall Failed. Aborting Uninstallation of InSite2. 
echo.
:End
