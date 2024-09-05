@echo off
rem
rem This script validates the target PC prior to a platform installation.
rem  It is (optionally) called very early in InstallSvcPlatform.bat.  The
rem  installation can then be immediately aborted if the validation of the
rem  target PC fails.
rem
rem  HW and SW components can be tested.  HW validation typically checks that
rem   the target PC meets minimum requirements (e.g. DRAM, free disk space, etc.)
rem   SW validation checks for the existence of "signatures" of various
rem   software components.  The pre-existence of any software component can
rem   be good or bad.  For example, some software components may be a pre-requisite
rem   to the platform installation and, therefore, must pre-exist.  On the other
rem   hand, the pre-existence of other software components may require that they
rem   be uninstalled first.
rem
rem Calling:
rem  InstallPreCheck.bat [logfile]
rem
rem If a [log file] is not specified, a default log file name is used.
rem  Typically, InstallSvcPlatform.bat calls this script and passes
rem  in the name of the log file it has created and is using.
rem
rem Exit Codes:
rem  0 = success, proceed with the installation.
rem  1 = validation failed, do NOT proceed with the installation.
rem
rem NOTE:
rem  See the "Release 2.5 Remote Docking PC SDD.doc" for a description of the
rem   CheckSystemRequirements.exe and CheckInstalledComponents.exe tools.
rem   Especially note the [-none|-any|-all] switches that can optionally be used
rem   with the CheckInstalledComponents.exe tool.
rem

set checkSystemReqUtil=.\Utils\CheckSystemRequirements.exe
set checkInstalledComponentsUtil=.\Utils\CheckInstalledComponents.exe
set outfile=InstallPreCheck.log
set precheckStatus=ok

rem Delete "our" log file if already there.
if exist %outfile% (
    del /f %outfile%
)

rem Append to callers log file (if provided).
if not .%1%==. (
    set outfile=%1%
)

rem
rem If no pre-installation checks are required, un-comment out the following
rem  line in order to bypass this entire script.  Or better still, simply
rem  do NOT call this script!
rem
goto EndBypass

rem ********************************************************************************
rem Start of pre-installation checks.
rem ********************************************************************************

echo Start of Pre-installation checks.
echo Start of Pre-installation checks. >> %outfile%

rem
rem Check if computer satisfies all HW and SW requirements.
rem
echo Checking HW and SW requirements
echo Checking HW and SW requirements >> %outfile%
%checkSystemReqUtil% .\Utils\SystemRequirements.xml >> %outfile%
if ERRORLEVEL 1 (
    echo FAILED: HW and SW Requirements are NOT satisfied ^(see Log File^).
    echo FAILED: HW and SW Requirements are NOT satisfied. >> %outfile%
    set precheckStatus=FAILED
) else (
    echo PASSED: HW and SW Requirements are satisfied.
    echo PASSED: HW and SW Requirements are satisfied. >> %outfile%
)

rem
rem Check for the following SW component (VNC).
rem
set ThisSW=VNC
echo Checking for existing installation of '%ThisSW%'
echo Checking for existing installation of '%ThisSW%' >> %outfile%
%checkInstalledComponentsUtil% -none ComponentSignature_VNC.xml >> %outfile%
if ERRORLEVEL 1 (
    echo FAILED: Existing version of '%ThisSW%' detected ^(see Log File^).
    echo FAILED: Existing version of '%ThisSW%' detected. >> %outfile%
    echo Remove existing version then retry the installation.
    echo Remove existing version then retry the installation. >> %outfile%
    set precheckStatus=FAILED
) else (
    echo PASSED: '%ThisSW%' not detected.
    echo PASSED: '%ThisSW%' not detected. >> %outfile%
)

rem ********************************************************************************
rem All done.
rem ********************************************************************************
echo End of Pre-installation checks.
echo End of Pre-installation checks. >> %outfile%
goto :EndSetExitCode

rem ********************************************************************************
rem Pre-installation checks have been bypassed.
rem ********************************************************************************
:EndBypass
echo Pre-installation checks bypassed (i.e. not run).
echo Pre-installation checks bypassed (i.e. not run). >> %outfile%

:EndSetExitCode
rem End of script.
if NOT "%precheckStatus%"=="ok" (
    exit /b 1
} else (
    exit /b 0
)
