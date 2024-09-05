@echo off
rem This batch script compares the auto-generated DeviceName to the one in the Questra Agent configurations in the restore source directory 
rem and restores the configurations only if they match.
rem This script is provided to prevent restoring service configurations backedup from a different machine.
rem If the restore fails because DeviceName doesn't match, the script returns exit code 1.
rem If the restore fails for other reasons, the script will return exit code 2 or higher.
rem The script returns exit code 0 if the restore is successful.
rem Usage: RestoreService [RestoreSourceDir] [-h]
rem [RestoreSourceDir] - The directory where the Questra Agent configurations are going to be restored from.  Required.
rem [-h] - To see the usage
rem Example: RestoreService "D:\export\GEMS_BACKUP\LOGIQ9\Service"
rem Author : Jung Oh 
rem Date: October, 2006

if .%1%==. (
	goto showUsage
)

if .%1%==.-h (
	goto showUsage
)

goto startRestore

:showUsage
echo Usage: RestoreService [RestoreSourceDir] [-nocheck] [-h]
echo.
echo [RestoreSourceDir] - The directory where the Questra Agent configurations 
echo                      are going to be restored from.  Required.
echo [-nocheck] - If provided, it will not check if the current or auto-generated DeviceName matches the DeviceName from the restoring
echo                      Questra Agent configurations.  This is useful when restoring from the previous agent configurations
echo                      remained in the data partition during the install, because serialNo.txt file might not have been created yet
echo                      during the install, so the auto-generated DeviceName can't be compared.  The previous agent configurations
echo                      remained in the data partition is trustable since they are not backed up by a user.  Optional. 
echo [-h] - To see the usage
echo Example: RestoreService "D:\export\GEMS_BACKUP\LOGIQ9\Service"
echo.
goto END

:startRestore
set RestoreSourceDir=%1%

pushd "%INSITE2_HOME%\Questra"
rem Call InstallEnvVars.bat
rem It will set the evnironment variables that were used during the install
call InstallEnvVars.bat

if .%2%==.-noCheck (
	goto startUpdate
)

rem Check if the existing DeviceName or auto-generated DeviceName matches the one in the restore source directory 
"%PERL_HOME%bin\Perl" DeviceNameMatch.pl %RestoreSourceDir%
if ERRORLEVEL 1 (
	popd
	EXIT %ERRORLEVEL%
)

:startUpdate
rem Strip double quotes if there are any
set RestoreSourceDir=%RestoreSourceDir:"=%
rem DeviceName matches.  Use the backedup sitemap.xml file to regenerate the configurations in %INSITE2_ROOT_DIR%\etc directory
call UpdateAgentConfig.bat "%RestoreSourceDir%\sitemap.xml" 
if ERRORLEVEL 1 (
	popd
	EXIT %ERRORLEVEL%
)

rem The following perl script will update %INSITE2_HOME%\Questra\AgentConfig.xml file
rem which will be used with UpdateAgentConfig.bat
"%PERL_HOME%bin\perl" ExtractSitemap.pl "%INSITE2_DATA_DIR%\etc\sitemap.xml" AgentConfig.xml
if ERRORLEVEL 1 (
	popd
	EXIT %ERRORLEVEL%
)
popd
echo Restore Succeeded
:END
EXIT 0