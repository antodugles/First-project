@echo off

rem
rem  QSAManControl.bat - If the agent is configured as a manual service, this control will restart
rem  the agent service only if the agent is currently running.  This is required, for instance, to
rem  apply a new configuration from the config tool or backup/restore operation.
rem
rem  usage:  QSAManControl.bat
rem

rem Check the install option
if not "%INSITE2_HOME%" == "" (
	if exist "%INSITE2_HOME%\InstallOption.xml" (
		"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" QuestraAgent "%INSITE2_HOME%\InstallOption.xml" AutoService
		if ERRORLEVEL 1 (
			goto checkManualService
		)
	
                ComponentControl.exe -agent -startservice -s
		goto successEnd
		
:checkManualService
		"%PERL_HOME%bin\perl" "%INSITE2_HOME%\bin\InstallOption.pl" QuestraAgent "%INSITE2_HOME%\InstallOption.xml" ManualService
		if ERRORLEVEL 1 (
			goto END
		)

                "%PERL_HOME%bin\perl" "%INSITE2_HOME%\Questra\checkQSAStatus.pl"
                if ERRORLEVEL 1 (
                    goto successEnd
                )

		rem Since the QSA service is running, stop/restart the service.
                rem

      	        start ComponentControl.exe -agent -startservice

		goto successEnd

       )	
)

goto END

:successEND

:END