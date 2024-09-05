@echo off
rem This is a batch file used for the restore of the sitemap.xml from a backup configuration package.
rem 

set mapfile=%1
rem
cd "%INSITE2_HOME%\Questra"

call UpdateAgentConfig.bat %mapfile%
"%INSITE2_HOME%\Questra\QSAManControl.bat"