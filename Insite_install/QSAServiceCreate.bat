@echo off

rem
rem  QSAServiceCreate.bat [-startautoonly]
rem
rem		This batch file will check the install option and create the qsa service or make the Questra 
rem     agent start as an automatic process depending on the install option upon the first checkout.
rem     Then start or restart the service or process whether it's the first or subsquent checkout.
rem	If "-startautoonly" option is set, the Questra agent will be started or restarted only if the agent is configured to be installed as AutoService or AutoProcess. 

set StartAutoOnly=0
set AutoProcess=0
set AltInstall=0
if "%1%"=="-startautoonly" (
	set StartAutoOnly=1
)

if not exist "%INSITE2_HOME%\bin\ComponentControl.exe" (
   set AltInstall=1
)

rem Check the install option
if not "%INSITE2_HOME%" == "" (
	if exist "%INSITE2_HOME%\InstallOption.xml" (
		"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" QuestraAgent "%INSITE2_HOME%\InstallOption.xml" AutoService
		if ERRORLEVEL 1 (
			goto checkManualService
		)
		rem Start/Restart the service
		rem If the service doesn't exist, an automatic service will be created.
		rem If this is called from CSD, ComponentControl doesn't have to be called in Silent Mode, but if this is called from install, restore or refresh (from UpdateAgentConfig.bat), call ComponentControl in Silent Mode and block.
		if "%StartAutoOnly%"=="1" (
                        if "%AltInstall%"=="1" (
                             echo alternate agent service cre mech
                            "%INSITE2_ROOT_DIR%\bin\qsaMain.exe" -service "qsa" -i "Questra Service Agent" -config "%INSITE2_DATA_DIR%\etc\qsaconfig.xml"
                        ) else (
			    ComponentControl.exe -agent -startservice -s
                        )
		) else (
                        if "%AltInstall%"=="1" (
                            rem alternate agent service cre mech
                            "%INSITE2_ROOT_DIR%\bin\qsaMain.exe" -service "qsa" -i "Questra Service Agent" -config "%INSITE2_DATA_DIR%\etc\qsaconfig.xml"
                        ) else (
			    start ComponentControl.exe -agent -startservice
                        )
		)
		goto successEnd
		
:checkManualService
		"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" QuestraAgent "%INSITE2_HOME%\InstallOption.xml" ManualService
		if ERRORLEVEL 1 (
			goto checkAutoProcess
		)
		rem Since the install option is ManualService, start/restart the service only if -startautoonly option is not set that this is called from CSD.
		rem The manual service should have been created during the install.
		if not "%StartAutoOnly%"=="1" (
                        if "%AltInstall%"=="1" (
                            rem alternate agent service cre mech
                            "%INSITE2_ROOT_DIR%\bin\qsaMain.exe" -service "qsa" -i "Questra Service Agent" -config "%INSITE2_DATA_DIR%\etc\qsaconfig.xml"
                        ) else (
			    start ComponentControl.exe -agent -startservice
                        )
		)
		goto successEnd
		
:checkAutoProcess
		"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" QuestraAgent "%INSITE2_HOME%\InstallOption.xml" AutoProcess
		if ERRORLEVEL 1 (
			rem Check if Questra Agent is installed at all
			goto checkInstall
		)
		set AutoProcess=1
		if not exist "%INSITE2_DATA_DIR%\etc\.checkout" (
			rem Check if startloader.exe from the global ultrasound software platform is available
			reg.exe query HKCU\Software\GEVU\StartLoader > nul 2>&1
			
			rem If startloader.exe is available, add the "AutoProcess" applications to RunStart registry key instead of Run registry key.
			rem It means that the system is a closed (no desktop) ultrasound machine and startloader.exe will look in the RunStart registry key and run those applications in the key.
			rem Note that applications in Run registry key will not run unless there is a desktop (explorer.exe is running).
			if not ERRORLEVEL 1 (
				set RegKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunStart
			) else (
				set RegKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
			)
			rem Add to the registry outside of this if statement. Statements in an if statement runs as piped commands that RegKey variable
			rem will not be initialized if it's used here.
			goto addRunRegistry
		)
		goto startProcess
		
:checkInstall
		"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" QuestraAgent "%INSITE2_HOME%\InstallOption.xml"
		if ERRORLEVEL 1 (
			rem Questra Agent is not supposed to be installed.
			rem Then how does %INSITE2_ROOT_DIR% exist? Anyway, do nothing.
			goto END
		)
		goto startProcess
	)
)
goto END

:addRunRegistry
reg.exe add %RegKey% /f /v QuestraAgent /d "%INSITE2_HOME%\bin\ComponentControl.exe -agent -startprocess -nr -s"

:startProcess
rem If Questra Agent is installed as AutoProcess, 
if "%AutoProcess%"=="1" (
	rem If this is called from CSD, ComponentControl doesn't have to be called in Silent Mode, but if this is called from install, restore or refresh (from UpdateAgentConfig.bat), call ComponentControl in Silent Mode and block.
	if "%StartAutoOnly%"=="1" (
		ComponentControl.exe -agent -startprocess -s
	) else (
		start ComponentControl.exe -agent -startprocess
	)
) else (
	rem Since Questra Agent is installed as ManualProcess, start/restart Questra Agent process only if -startautoonly option is not set that this is called from CSD.
	if not "%StartAutoOnly%"=="1" (
		start ComponentControl.exe -agent -startprocess
	)
)

:successEnd
rem Create .checkout file if it doesn't exist and log date and time 
echo %date% at %time% >> "%INSITE2_DATA_DIR%\etc\.checkout"

:END