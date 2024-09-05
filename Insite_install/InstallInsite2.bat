@echo off
rem        Batch file for:
rem  		    Insite2 Install which includes:
rem             Perl install
rem		    	JRE install 
rem		    	Web Server install
rem             Questra Agent install

if .%1%==. (
	goto showUsage
)

if .%1%==.-h (
	goto showUsage
)

goto startInstall

:showUsage
echo Usage: InstallInsite2 [Target Directory] [Install Option XML]
echo.
echo [Target Directory]: Directory where InSite2 will be installed.
echo [Install Option XML]: Optional. InstallOption.xml will be used as the default if not specified.
echo Install results will be logged in "[Target Directory]\Install.log".
echo Example: InstallInsite2 D:\InSite2
echo.
goto END
	
:startInstall
set TargetDir=%1%

rem Strip double quotes if there are any
set TargetDir=%TargetDir:"=%

rem Make %TEMP% folder if it doesn't exist
if not "%TEMP%"=="%TargetDir%\IS2Temp" (
	if not exist "%TEMP%" (
		set OLDTEMP=%TEMP%
		set TEMP=%TargetDir%\IS2Temp
	)
)
if not exist "%TEMP%" (
	md "%TEMP%" > nul
)

set InstallOptionXML=%2%
if .%InstallOptionXML%==. (
	set InstallOptionXML=InstallOption.xml	
)

set JREVersion=jre1.6.0_11
set JREGUID="{26A24AE4-039D-4CA4-87B4-2F83216011F0}"
set INSITE_JAVA_HOME=%TargetDir%\Java\%JREVersion%
set INSITE_JAVA_PACKAGE=jre-6u11-windows-i586-p.exe
set INSITE_JAVA_ZIP=jre1.6.0_11.zip
set outfile="%TargetDir%\Install.log"

if not exist "%TargetDir%" (
	md "%TargetDir%"
)

echo Installing InSite2
echo Installing InSite2 in %TargetDir% >> %outfile%

if not "%PERL_HOME%"=="" (
   if exist "%PERL_HOME%bin\perl.exe" (
	echo Perl is already installed in %PERL_HOME%. Perl install is skipped.
	echo Perl is already installed in %PERL_HOME%. Perl install is skipped. >> %outfile%
	goto javaInstall
   )
   echo PERL_HOME is set to %PERL_HOME%, but PERL is not installed.  Setup Error.
   echo PERL_HOME is set to %PERL_HOME%, but PERL is not installed.  Setup Error. >> %outfile%
   goto perlError 
)
echo Installing Perl in %TargetDir%\Perl
echo Installing Perl in %TargetDir%\Perl >> %outfile%
cd Perl
call perl.bat install "%TargetDir%" >> %outfile%
copy /y perl.bat "%TargetDir%\Perl" > nul
cd ..
if ERRORLEVEL 1 goto perlError

if not exist "%TargetDir%\Perl\bin\perl.exe" (
   echo Perl failed to install.  Check install log for details.
   echo Perl failed to install.  Check install log for details. >> %outfile%
   goto perlError
)

rem Remove %PERL_HOME%\bin from PATH. It might conflict with SW only products that already have Perl.
rem All codes have to use %PERL_HOME% to explicitly run perl.exe.
rem Because 2007MAR15_ENGG release of agent install seems to call perl.exe not using the full path, the following code is commented out. 
rem SetEnv.exe -d PATH ~"%TargetDir%\Perl\bin" > nul
set PATH=%TargetDir%\Perl\bin;%PATH%
set PERL_HOME=%TargetDir%\Perl\


goto javaInstall

:perlError
if exist "%TargetDir%\Perl" (
	rd /S /Q "%TargetDir%\Perl"
)
SetEnv.exe -d PERL_HOME
set PERL_HOME=

SetEnv.exe -d PATH ~"%TargetDir%\Perl\bin"

goto errorEnd

:javaInstall
"%PERL_HOME%bin\perl" InstallOption.pl WebServer %InstallOptionXML%
if ERRORLEVEL 1 (
	echo Web Server is not configured to be installed. JRE and Apache/Tomcat Web Server installs are skipped.
	echo Web Server is not configured to be installed. JRE and Apache/Tomcat Web Server installs are skipped. >> %outfile%
	goto questraInstall
)

rem
rem    The following code chunk, added 8/2/06, handles unzipping Java JRE instead of installing Java JRE
rem    for the products that need a different version of Java than CSD needs (so 2 JREs can peacefully coexist)
"%PERL_HOME%bin\perl" InstallOption.pl unzipJava %InstallOptionXML%
if ERRORLEVEL 1 (
	goto normalJava
)

rem  If the environment var is not set, set it
if  "%CKM_JAVA_HOME%"=="" (
	SetEnv.exe -a CKM_JAVA_HOME "%INSITE_JAVA_HOME%"
	set CKM_JAVA_HOME=%INSITE_JAVA_HOME%
)

if  "%JAVA_HOME%"=="" (
	SetEnv.exe -a JAVA_HOME "%INSITE_JAVA_HOME%"
	set JAVA_HOME=%INSITE_JAVA_HOME%
)

rem create the Java directory, if it doesn't exist
if not exist "%CKM_JAVA_HOME%" (
	md "%CKM_JAVA_HOME%"
)

echo uncompressing, instead of installing, JRE/Java.
echo uncompressing, instead of installing, JRE/Java. >> %outfile%

".\AgentInstall\unzip" ".\%INSITE_JAVA_ZIP%" -d "%TargetDir%\Java"

goto websrvInstall

:normalJava
if not "%JAVA_HOME%"=="" (
	echo JRE is already installed in %JAVA_HOME%. JRE install is skipped.
	echo JRE is already installed in %JAVA_HOME%. JRE install is skipped. >> %outfile%
	goto copyTools
)
echo Installing JRE in %INSITE_JAVA_HOME%
echo Installing JRE in %INSITE_JAVA_HOME% >> %outfile%
%INSITE_JAVA_PACKAGE% /s /v /qn IEXPLORER=1 INSTALLDIR=\"%INSITE_JAVA_HOME%\" REBOOT=Suppress STATIC=1 >> %outfile%
if ERRORLEVEL 1 goto javaError

reg add "HKLM\SOFTWARE\JavaSoft\Java Update\Policy" /f /v EnableJavaUpdate /t REG_DWORD /d 0 > nul
rem reg delete "HKLM\SOFTWARE\JavaSoft\Java Update\Policy" /v PromptAutoUpdateCheck /f > nul 2>&1
if ERRORLEVEL 1 goto javaError

echo Setting Java environment variables >> %outfile%
SetEnv.exe -a JAVA_HOME "%INSITE_JAVA_HOME%" >> %outfile%
SetEnv.exe -a PATH "%INSITE_JAVA_HOME%\bin"~ >> %outfile%
set PATH=%INSITE_JAVA_HOME%\bin;%PATH%
if "%JAVA_HOME%"=="" (
	set JAVA_HOME=%INSITE_JAVA_HOME%
	rem copy tools.jar file to JRE's lib directory, so JDK doesn't have to be installed.
	rem also copy jar.exe file to JRE's bin directory.
	copy /y tools.jar "%INSITE_JAVA_HOME%\lib" > nul
	copy /y jar.exe "%INSITE_JAVA_HOME%\bin" > nul
	if ERRORLEVEL 1 goto javaError
	goto websrvInstall
)

:copyTools
rem copy tools.jar file to JRE's lib directory, so JDK doesn't have to be installed.
rem also copy jar.exe file to JRE's bin directory.
copy /y tools.jar "%JAVA_HOME%\lib" > nul
copy /y jar.exe "%JAVA_HOME%\bin" > nul
if ERRORLEVEL 1 goto javaError

goto websrvInstall

:javaError
rem Try uninstalling JRE
msiexec.exe /qn /x %JREGUID%
if exist "%TargetDir%\Java" (
	rd /S /Q "%TargetDir%\Java"
)
SetEnv.exe -d JAVA_HOME
set JAVA_HOME=
goto errorEnd

:websrvInstall
rem Check if Web Server is installed.
if not "%INSITE2_HOME%"=="" (
	if not "%WIP_HOME%"=="" (
		echo Web Server already exists in %INSITE2_HOME%. 
		rem Determine the current version available and the one installed. Error if they don't match.
		"%PERL_HOME%bin\perl" findv.pl webserver "%TargetDir%" >> %outfile% 
		if ERRORLEVEL 1 (
			"%PERL_HOME%bin\perl" findv.pl webserver "%TargetDir%"
			goto errorEnd
		)
		echo WARNING: Web Server already exists in %INSITE2_HOME%. See above lines for details >> %outfile%
		goto questraInstall
	)
)

echo Installing Apache/Tomcat Web Server in %TargetDir%\CKM
echo Installing Apache/Tomcat Web Server in %TargetDir%\CKM >> %outfile%	
echo Modifying platform.xml install configuration file with the target directory >> %outfile%
"%PERL_HOME%bin\perl" UpdatePlatformXML.pl "%TargetDir%" >> %outfile%
if ERRORLEVEL 1 goto errorEnd

echo Running platform.pl to install >> %outfile%
cd Insite2.0
"%PERL_HOME%bin\perl" platform.pl -f "%TEMP%\platform.xml"
cd ..
del /f "%TEMP%\platform.xml"
if ERRORLEVEL 1 goto websrvError

if not exist "%TargetDir%\CKM\VERSION" (
	echo Apache/Tomcat Web Server is not installed properly.
	goto websrvError
)
if "%WIP_HOME%"=="" (
	set WIP_HOME=%TargetDir%\CKM\
)
if "%CATALINA_HOME%"=="" (
	set CATALINA_HOME=%TargetDir%\CKM\tomcat
)

rem Copy Web Server version file
copy /y Insite2.0\VERSION "%TargetDir%" > nul
if ERRORLEVEL 1 goto websrvError
goto questraInstall

:websrvError
rem Remove services
if exist "%TargetDir%\CKM\Service.txt" (
	if exist "%TargetDir%\CKM\Apache\bin\Apache.exe" (
		"%TargetDir%\CKM\Apache\bin\Apache.exe" -k uninstall > nul
	)
	if exist "%TargetDir%\CKM\tomcat\bin\service.bat" (
		call "%TargetDir%\CKM\tomcat\bin\service.bat" remove > nul
	)
)
if exist "%TargetDir%\CKM" (
	rd /S /Q "%TargetDir%\CKM"
)
SetEnv.exe -d WIP_HOME
set WIP_HOME=
SetEnv.exe -d CATALINA_HOME
set CATALINA_HOME=
SetEnv.exe -d PATH ~"%TargetDir%\CKM\php"
if exist "%TargetDir%\VERSION" (
	del /f "%TargetDir%\VERSION"
)
goto errorEnd

:questraInstall
"%PERL_HOME%bin\perl" InstallOption.pl QuestraAgent %InstallOptionXML%
if ERRORLEVEL 1 (
	echo Questra Agent is not configured to be installed. Questra Agent install is skipped.
	echo Questra Agent is not configured to be installed. Questra Agent install is skipped. >> %outfile%
	goto successEnd
)
rem Check if Questra Agent is installed.
if not "%INSITE2_ROOT_DIR%"=="" (
	echo Questra Agent already exists in %INSITE2_ROOT_DIR%. 
	rem Determine the current version available and the one installed. Error if they don't match.
	"%PERL_HOME%bin\perl" findv.pl questra "%TargetDir%\Questra\GeHealthcare\Agent" >> %outfile% 
	if ERRORLEVEL 1 (
		"%PERL_HOME%bin\perl" findv.pl questra "%TargetDir%Questra\GeHealthcare\Agent"
		goto errorEnd
	)
	echo WARNING: Questra Agent already exists in %INSITE2_HOME%. See above lines for details >> %outfile%
	goto successEnd
)

rem Creates UltraVNC Configuration in registry.. (added by Bill Caughey)
call vnc_conf.bat
echo Installing Questra Agent in %TargetDir%\Questra
echo Installing Questra Agent in %TargetDir%\Questra >> %outfile%
pushd .\AgentInstall
call QuestraInstall.bat "%TargetDir%" >> %outfile%
popd
if ERRORLEVEL 1 (
	goto questraError
)

echo Setting INSITE2_ROOT_DIR environment variable >> %outfile%
set INSITE2_ROOT_DIR=%TargetDir%\Questra\GeHealthcare\Agent

rem Remove LANG=en_US environment variable since we are not using the default RFS interface that requires it and this environment variable conflicts with Sybase
SetEnv.exe -d LANG
set LANG=

if not exist "%INSITE2_ROOT_DIR%\etc\versions.txt" (
	echo Questra Agent is not installed properly.
	goto questraError
)
goto successEnd

:questraError
pushd .\AgentInstall
call QuestraUninstall.bat > nul
popd
SetEnv.exe -d INSITE2_ROOT_DIR
set INSITE2_ROOT_DIR=
SetEnv.exe -d LANG
set LANG=
goto errorEnd

:successEnd
echo Setting INSITE2_HOME environment variable >> %outfile%
SetEnv.exe -a INSITE2_HOME "%TargetDir%" >> %outfile%
set INSITE2_HOME=%TargetDir%
if ERRORLEVEL 1 goto errorEnd

rem Copy %InstallOptionXML% file to the install root directory, so we know what options are selected
copy /y %InstallOptionXML% "%INSITE2_HOME%\InstallOption.xml" >> %outfile%

echo Copying Un-install related files
if not exist "%INSITE2_HOME%\Uninstall" (
	md "%INSITE2_HOME%\Uninstall"
)
copy /y UninstallInsite2.bat "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y SetEnv.exe "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y taskkill.exe "%INSITE2_HOME%\Uninstall" >> %outfile%
copy /y .\AgentInstall\QuestraUninstall.bat "%INSITE2_HOME%\Uninstall" >> %outfile%

rem Delete custom %TEMP% folder if it exists
if "%TEMP%"=="%TargetDir%\IS2Temp" (
	if exist "%TEMP%" (
		rd /s /q "%TEMP%" > nul
	)
	set TEMP=%OLDTEMP%
)

echo Installed InSite2 Successfully. 
echo Installed InSite2 Successfully. >> %outfile%
echo.
goto End

:errorEnd
echo InSite2 Install Failed. Aborting installation of InSite2. 
echo InSite2 Install Failed. Aborting installation of InSite2. >> %outfile%
echo.
exit /b 1
:End



