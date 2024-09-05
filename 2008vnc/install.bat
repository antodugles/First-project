:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Description: Removes UltraVNC 1.0.2 and replaces it with 1.0.9.5
::              For use on Windows Server 2008
::
:: 2011.03.01 - WRC - Original.
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@ECHO OFF
IF "%TEMP%" == "" SET TEMP=C:\
IF NOT EXIST %SystemRoot%\system32\choice.exe GOTO CHOICE
IF NOT EXIST %SystemRoot%\system32\findstr.exe GOTO FINDSTR
IF NOT EXIST %SystemRoot%\system32\sc.exe GOTO SERVICE
IF NOT EXIST C:\InSite2\UltraVNC\winvnc.exe GOTO VNC_NOT_FOUND
ECHO.
ECHO Verifying Windows Version...
ECHO.
VER > %temp%\vncup.tmp
findstr /C:"Version 6" %temp%\vncup.tmp > NUL
if %errorlevel% == 1 GOTO WIN_VER_FAIL
ECHO Stopping VNC Server service if necessary...
ECHO.
SC STOP WINVNC > NUL
CHOICE /N /C Y /T 10 /D Y > NUL
SC QUERY WINVNC > %temp%\vncup.tmp
findstr /C:"STOPPED" %temp%\vncup.tmp > NUL
if %errorlevel% == 1 GOTO VNC_SERVICE
ECHO Renaming old UltraVNC folder...
ECHO.
ren c:\InSite2\UltraVNC old_UltraVNC
IF EXIST C:\InSite2\UltraVNC\winvnc.exe GOTO RENAME_FAIL
ECHO Making new UltraVNC folder...
ECHO.
mkdir c:\InSite2\UltraVNC
IF NOT EXIST c:\InSite2\UltraVNC GOTO NO_FOLDER
ECHO Copying files to new UltraVNC folder...
ECHO.
xcopy /s/e/v .\UltraVNC c:\InSite2\UltraVNC > NUL
IF NOT EXIST C:\InSite2\UltraVNC\winvnc.exe GOTO COPY_FAIL
ECHO Removing old UltraVNC folder...
ECHO.
IF EXIST C:\InSite2\old_UltraVNC\winvnc.exe rd /s /q c:\InSite2\old_UltraVNC
IF EXIST C:\InSite2\old_UltraVNC GOTO REMOVE_FAIL
ECHO Starting VNC Server Service...
ECHO.
SC START WINVNC > NUL
ECHO UltraVNC upgrade process completed without errors.
GOTO DONE

:WIN_VER_FAIL
ECHO.
ECHO ERROR: Windows Server 2008 not found.
GOTO DONE

:VNC_NOT_FOUND
ECHO.
ECHO ERROR: UltraVNC not found.
GOTO DONE

:RENAME_FAIL
ECHO.
ECHO ERROR: Rename of UltraVNC directory failed.
GOTO DONE

:NO_FOLDER
ECHO.
ECHO ERROR: The UltraVNC folder was not created.
GOTO DONE

:COPY_FAIL
ECHO.
ECHO ERROR: One or more expected files did not copy.
GOTO DONE

:REMOVE_FAIL
ECHO.
ECHO ERROR: The old_UltraVNC folder was not removed.
GOTO DONE

:SERVICE
ECHO.
ECHO ERROR: sc.exe not found, aborting!
GOTO DONE

:CHOICE
ECHO.
ECHO ERROR: choice.exe not found, aborting!
GOTO DONE

:FINDSTR
ECHO.
ECHO ERROR: findstr.exe not found, aborting!
GOTO DONE

:VNC_SERVICE
ECHO.
ECHO ERROR: VNC Server Service did not stop.
GOTO DONE

:DONE
IF EXIST %temp%\vncup.tmp DEL %temp%\vncup.tmp
ECHO.
pause
GOTO :EOF
