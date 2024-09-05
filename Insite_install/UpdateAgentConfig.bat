@echo off
rem This is a batch file for updating Questra Agent Config Files (qsaconfig.xml and hscds.xml files) with a sitemap xml file 
rem This batch file is used for initializing agent configs with the auto-generated DeviceName and SerialNumber during the install 
rem or after the install using RunOnce registry key if "GetSerialNumber" command is not ready to return the serial number of the system during the install time. 
rem If the auto-generation of DeviceName and SerialNumber using "GetSerialNumber" command is not desired,
rem manually update AgentConfig.xml file with unique DeviceName and SerialNumber and run this batch file, then
rem Questra Agent Config Files will be updated with the manually entered values.
rem This batch file is also used in RestoreService.bat to restore the agent configs from a backed up sitemap xml file.
rem Refer to the install manual for the usage detail.
rem

set AgentConfigXML=AgentConfig.xml
if not %1.==. (
	set AgentConfigXML=%1
)

echo Modifying Questra Agent Config Files...

rem If InstallEnvVars.bat exists, call it
rem It will set the evnironment variables that were used during the install
if exist InstallEnvVars.bat (
	call InstallEnvVars.bat
)

rem Merge sitemap.xml with AgentConfig.xml or specified xml
set RestartAgent=0
"%PERL_HOME%bin\perl" "%INSITE2_DATA_DIR%\etc\MergeSiteMap.pl" "%INSITE2_DATA_DIR%\etc\sitemap.xml" %AgentConfigXML%
if ERRORLEVEL 2 (
	echo Error running MergeSiteMap.pl script.
	goto END
)
if ERRORLEVEL 1 (
	rem Run QSAServiceCreate.bat to create service and restart the agent at the end
	set RestartAgent=1
)

rem Replace environment variables in sitemap.xml
ren "%INSITE2_DATA_DIR%\etc\sitemap.xml" newsitemap.xml
"%PERL_HOME%bin\perl" ReplaceEnvVars.pl "%INSITE2_DATA_DIR%\etc\newsitemap.xml" "%INSITE2_DATA_DIR%\etc\sitemap.xml"
if ERRORLEVEL 1 (
	echo Error running ReplaceEnvVars.pl script.
	goto END
)
del /f "%INSITE2_DATA_DIR%\etc\newsitemap.xml"
rem Generate the actual Questra Agent configuration files using gencfg.cmd tool
pushd %INSITE2_ROOT_DIR%\bin
call "%INSITE2_ROOT_DIR%\bin\gencfg" -template "%INSITE2_DATA_DIR%\etc\templates\qsa" -cfgdir "%INSITE2_DATA_DIR%\etc"
if ERRORLEVEL 1 (
	popd
	echo Error running gencfg tool.
	goto END
)
popd

rem Copy sitedefs.txt file to the Windows directory
"%PERL_HOME%bin\perl" "%INSITE2_DATA_DIR%\etc\GenQSAcfg.pl"
if ERRORLEVEL 1 (
	echo Error copying sitedefs.txt.
	goto END
)

if "%RestartAgent%"=="1" (
	echo Running QSAServiceCreate.bat to create service and restart the agent depending on the install option...
	call QSAServiceCreate.bat -startautoonly
)

echo Successfully completed.
:END