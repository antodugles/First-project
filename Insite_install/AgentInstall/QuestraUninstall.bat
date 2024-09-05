@echo off
rem
rem  Batch File for:
rem      Questra Service Agent 5.2 uninstall
rem      Questra Service Agent service uninstall
rem
rem
setlocal

if not "%INSITE2_HOME%"=="" (
	set TargetDir=%INSITE2_HOME%
	goto uninstQuestra
)
if not "%INSITE2_ROOT_DIR%"=="" (
	set TargetDir=%INSITE2_ROOT_DIR%\..\..\..\
)

:uninstQuestra
rem  Stop and Delete the qsa (Questra Service Agent) windows service
rem

echo Removing Questra Service Agent
if exist ..\sc.exe (
	..\sc.exe stop qsa > nul 2>&1
	..\sc.exe delete qsa > nul 2>&1
	goto contUninstall
) 
if exist sc.exe (
	sc.exe stop qsa > nul 2>&1
	sc.exe delete qsa > nul 2>&1
) 

:contUninstall

rem  Check if virtual Agents
rem

if not exist "%INSITE2_ROOT_DIR%\virtuals" (
   echo Dockable Device API not installed.
   goto contAgain
)

if exist "%INSITE2_HOME%\Export" (
   rmdir /s /q "%INSITE2_HOME%\Export"
)

echo Removing Virtual Agents
rem loop through each docked device and delete associated Windows service.
rem
for /f "delims=" %%g in ('dir /b "%INSITE2_ROOT_DIR%\virtuals\qsa*"') do (
   echo remote service %%g removal
   sc.exe stop %%g > nul 2>&1
   sc.exe delete %%g > nul 2>&1
)

:contAgain
if exist "%TargetDir%\Questra" (
    rem  Then remove Questra directory tree
    rmdir /s /q "%TargetDir%\Questra" 
)

rem  cleanup qsacfg directory

if exist C:\WINDOWS\qsacfg (

    rmdir /s /q "C:\WINDOWS\qsacfg"
)


echo Done removing Questra service agent.
