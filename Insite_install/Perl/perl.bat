@echo off
::
::  Batch file for:
::     Perl install
::
::

if ""%1"" == ""install"" goto doInstDir
if ""%1"" == ""uninstall"" goto doUninstall

:starterror
echo Perl Installation : Perl.bat install "<targetDir>"
echo Perl Uninstallation :  Perl.bat uninstall
goto end

:doInstDir
if not "%PERL_HOME%" == "" goto alInstall
if ""%2"" == """" goto doSetDir
set INSTALL_DIR=%2
goto doInstall

:doSetDir
set INSTALL_DIR=C:\Perl
goto doInstall

:doInstall

echo Installing Perl to %INSTALL_DIR%
..\AgentInstall\unzip Perl\PerlInstall.zip -d "%INSTALL_DIR%\Perl" >> nul
..\SetEnv.exe -a PERL_HOME "%INSTALL_DIR%\Perl\\"

goto OK

:doUninstall
echo Uninstalling perl

rd /s /q "%PERL_HOME%bin" >> nul
rd /s /q "%PERL_HOME%html" >> nul
rd /s /q "%PERL_HOME%lib" >> nul
rd /s /q "%PERL_HOME%site" >> nul

if exist "%INSITE2_HOME%\Uninstall\SetEnv.exe" (
   "%INSITE2_HOME%\Uninstall\SetEnv.exe" -d PERL_HOME
   goto OK
)

if exist "..\SetEnv.exe" (
   ..\SetEnv.exe -d PERL_HOME
   goto OK
)

goto ERROR

:alInstall
echo PERL is already installed on system.
goto end

:ERROR
echo UnSuccesfull!!! Please check log file in the current directory...
goto end

:OK
echo Successfully Completed!!!!!
goto end

:end

