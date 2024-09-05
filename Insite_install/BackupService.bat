@echo off
rem This batch script backs up all Questra Agent configurations to the restore directory. 
rem If the backup fails for some reasons, the script will return ERRORLEVEL as the exit code.
rem The script returns exit code 0 if the backup is successful.
rem Usage: BackupService [BackupDir] [-h]
rem [BackupDir] - The directory where the Questra Agent configurations are going to be backed up to.  Required.
rem [-h] - To see the usage
rem Example: BackupService  "D:\export\GEMS_BACKUP\LOGIQ9\Service"
rem Author : Jung Oh 
rem Date: November, 2006

if .%1%==. (
	goto showUsage
)

if .%1%==.-h (
	goto showUsage
)

goto startBackup

:showUsage
echo Usage: BackupService [BackupDir] [-h]
echo.
echo [BackupDir] - The directory where the Questra Agent configurations 
echo               are going to be backed up to.  Required.
echo [-h] - To see the usage
echo Example: BackupService "D:\export\GEMS_BACKUP\LOGIQ9\Service"
echo.
goto END

:startBackup
set BackupDir=%1%

rem Copy the configurations in %INSITE2_DATA_DIR%\etc to the back up directory
xcopy /y /q /e "%INSITE2_DATA_DIR%\etc" %BackupDir%
if ERRORLEVEL 1 (
	EXIT %ERRORLEVEL%
)
echo Backup Succeeded
:END
EXIT 0