@echo off
cd uninstall
echo This script will un-install Service Platform 
echo.
rem echo Please make sure of the following
rem echo   - The service browser is not running (close all the service platform related browser windows)
echo.

if "%1%"=="-h" (
	echo Usage: UninstallSvcPlatform [-p] [-n]
	echo.
	echo -p: Java and Perl will not be uninstalled
	echo -n: Service Browsers will not be killed
	echo.
	goto END
)

set PartialUninstall=
set KillBrowser=1

:CheckOptions
if "%1%"=="" goto Continue

if "%1%"=="-p" (
	set PartialUninstall=-p
)

if "%1%"=="-n" (
	set KillBrowser=
)

if "%1%"=="-DeviceType" (
	set DeviceType=%2%
	shift
)

if "%1%"=="-TargetDir" (
	set INSITE2_HOME=%2%
	shift
)
shift
goto CheckOptions

:Continue
if "%KillBrowser%"=="1" (
	echo Stopping any Service Browsers currently running         
	rem killing any currently running Service Browsers
	call taskkill /F /IM "IEXPLORE.EXE" > nul 2>&1
)
echo Uninstalling %DeviceType% Device Type from %INSITE2_HOME%
cd %INSITE2_HOME%\Uninstall

rem Call UninstallSvcApps.bat to uninstall Service Web Apps
call UninstallSvcApps.bat 

rem If all components are going to be uninstalled and this script is called from %INSITE2_HOME%\Uninstall folder,
if not "%PartialUninstall%"=="-p" (
	if not "%INSITE2_HOME%" == "" (
		if "%CD%"=="%INSITE2_HOME%\Uninstall" (
			rem Copy UninstallInsite2.bat and required files to temporary folder and run there.
			rem This is to make sure %INSITE2_HOME% folder will get deleted in case this script is ran from %INSITE2_HOME%\Uninstall folder.
			if exist "%TEMP%" ( 
				copy /y UninstallInsite2.bat "%TEMP%" > nul
				copy /y QuestraUninstall.bat "%TEMP%" > nul
				copy /y SetEnv.exe "%TEMP%" > nul
				copy /y taskkill.exe "%TEMP%" > nul
				cd /d "%TEMP%"
				goto DOUNINSTALL
			)
                        
			cd ..
			cd ..
			md IS2Temp > nul
			cd IS2Temp
			copy /y "%INSITE2_HOME%\Uninstall\UninstallInsite2.bat" UninstallInsite2.bat > nul
			copy /y "%INSITE2_HOME%\Uninstall\QuestraUninstall.bat" QuestraUninstall.bat > nul
			copy /y "%INSITE2_HOME%\Uninstall\SetEnv.exe" SetEnv.exe > nul
			copy /y "%INSITE2_HOME%\Uninstall\taskkill.exe" taskkill.exe > nul
		)
	)
)


rem Notice that "call" is not used to call the batch, so the batch will not return.
rem This is to make sure %INSITE2_HOME% folder will get deleted in case this script is ran from %INSITE2_HOME%\Uninstall folder.
:DOUNINSTALL
UninstallInsite2.bat %PartialUninstall%
:END

                                        

