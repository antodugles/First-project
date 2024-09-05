@echo off
::
::  Batch file for:
::     Insite2 5.2 agent
::
::
setlocal

if .%1%==. (
	goto showUsage
)

if .%1%==.-h (
	goto showUsage
)
goto INSTALLIT

:showUsage
echo USAGE: QuestraInstall [-h] [Target Directory] [-start]
echo. 
echo Target Directory: Agent Install directory. Required.
echo           -start: Optional start switch.  If specified, the Questra Service Agent
echo                   service will be created and started.  Default is no service created.
echo               -h: Optional help switch displays usage
echo.
goto END

:INSTALLIT
set TargetDir=%1%
rem Strip double quotes if there are any
set TargetDir=%TargetDir:"=%

if "%2%"=="-start" (
    set StartQSA=Yes
)

::
::  distribute the agent shell

if exist "%TargetDir%\Questra" (
   echo An Agent is already installed.  Remove %TargetDir%\Questra and re-install.
   goto END
)


rem
rem The following code replaces old code and is intended
rem to make the Questra agent install silent, avoiding the Questra InstallShield
rem

if not exist QuestraInstall.zip (
    echo QuestraInstall.zip install package not found.  Aborting Questra Agent install.
    goto END
 )

unzip QuestraInstall.zip -d "%TargetDir%"

if not exist "%TargetDir%\Questra\GeHealthcare\VERSION" (
   echo Error installing Questra Agent
   goto END
)

rem Set the System Environment Variable
..\SetEnv.exe  -a  INSITE2_ROOT_DIR "%TargetDir%\Questra\GeHealthcare\Agent"

rem Set the Local/user Environment Variable
set INSITE2_ROOT_DIR=%TargetDir%\Questra\GeHealthcare\Agent

::
::  Update templates to reflect modality options


copy ".\templates\*.*" "%INSITE2_ROOT_DIR%\etc\templates\qsa"


::
::  Assign tag fields system specific values for sitemap.xml.

del /Q "%INSITE2_ROOT_DIR%\etc\sitemap.xml" > nul 2>&1

"%PERL_HOME%bin\perl" ..\ReplaceEnvVars.pl AgentOptions.xml "%INSITE2_ROOT_DIR%\etc\sitemap.xml" 

copy /Y ".\versions.txt" "%INSITE2_ROOT_DIR%\etc"
copy /Y ".\MergeSiteMap.pl" "%INSITE2_ROOT_DIR%\etc"

copy /Y ".\AgentConfigMetaData.xml" "%TargetDir%\Questra"

::
::  Generate the actual config files used by the agent

pushd %INSITE2_ROOT_DIR%\bin
call "%INSITE2_ROOT_DIR%\bin\gencfg" -template "%INSITE2_ROOT_DIR%\etc\templates\qsa" -cfgdir "%INSITE2_ROOT_DIR%\etc"
popd

::
::  Now copy the sitedefs.txt into qsacfg WINDOWS directory

"%PERL_HOME%bin\perl" GenQSAcfg.pl

copy /Y ".\GenQSAcfg.pl" "%INSITE2_ROOT_DIR%\etc"

::
::  Remove old qsa service, if any.

..\sc.exe delete qsa >> nul


if "%StartQSA%"=="Yes" (
	"%INSITE2_ROOT_DIR%\bin\qsaMain.exe" -service "qsa" -i "QUESTRA SERVICE AGENT" -config "%INSITE2_ROOT_DIR%\etc\qsaconfig.xml"
)

echo Done Installing Questra service agent.

:END
