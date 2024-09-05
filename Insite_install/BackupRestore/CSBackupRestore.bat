@echo off

rem  Handles the backup and restore of predefined serivce platform configuration 
rem files defined in SaveFilesConfig.xml.
rem

"%PERL_HOME%bin\perl" "%INSITE2_HOME%\BackupRestore\CSBackupRestoreCfg.pl" %*
if ERRORLEVEL 1 goto errorEnd

goto End

:errorEnd
verify error 2> null

:End