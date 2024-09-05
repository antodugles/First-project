@echo off
rem  Batch file for:
rem    Insite2 Install which includes:
rem      Perl Install 
rem      Java Install 
rem      Web Server Install 
rem      Questra Agent Install 
rem    Service Apps which includes:
rem      Utilities Install
rem      VNC Install
rem      CSD Install 
rem      RFS Install

set InstallOptionPath=
set prodType=
set Prefix=
set UniqueID=
set TargetDir=C:\InSite2
set WebPort=
set VNCPort=
set VNCHttpPort=
set TelnetPort=
set HTMLPort=
set TomcatPort=
set DeviceType=
set ProductName=
set outfile="Install.log"
set Precheck=
set errorlvl=0

set firstarg=

if not .%1%==. (
   set firstarg=%1%

   rem Strip double quotes if there are any 
   call :dequote firstarg    
)

if "%firstarg%"=="-h" (
   call :usage
   goto End
)

if "%firstarg%"=="-help" (
   call :usage
   goto End
)

if "%firstarg%"=="-Precheck" goto PRECHECK

if "%firstarg%"=="-WebPort" goto LOOP
if "%firstarg%"=="-VNCPort" goto LOOP
if "%firstarg%"=="-VNCHttpPort" goto LOOP
if "%firstarg%"=="-TelnetPort" goto LOOP
if "%firstarg%"=="-telnetPort" goto LOOP
if "%firstarg%"=="-HTMLPort" goto Loop
if "%firstarg%"=="-UniqueID" goto LOOP
if "%firstarg%"=="-ProductType" goto LOOP
if "%firstarg%"=="-Prefix" goto LOOP
if "%firstarg%"=="-TomcatPort" goto LOOP
if "%firstarg%"=="-tomcatPort" goto LOOP
if "%firstarg%"=="-DeviceType" goto LOOP
if "%firstarg%"=="-ProductName" goto LOOP

if not "%firstarg%"=="" (
   set TargetDir=%firstarg%\InSite2
   SHIFT
)

rem Process '-Precheck' switch (must be first).
:PRECHECK
if "%1%"=="-Precheck" (
   set Precheck=Yes
   SHIFT
)

rem Process the optional <-option value> pairs.
:LOOP
if .%1%==. ( goto CONTINUE )

   call :processArgs %1 %2
   SHIFT
   SHIFT 
   GOTO LOOP
    
:CONTINUE

rem ====================================
rem Done processing arguments.  Proceed.
rem ====================================

if not exist "%TargetDir%" (
	md "%TargetDir%"
)

set outfile="%TargetDir%\Install.log"

if exist %outfile% (
	del /f %outfile%
)

rem ================================
rem Do Precheck first (if selected).
rem ================================

if "%Precheck%"=="Yes" (
   call InstallPreChecks.bat %outfile%
   if ERRORLEVEL 1 (
      echo Pre-installation failures detected - Aborting installation.
      echo Pre-installation failures detected - Aborting installation. >> %outfile%
      goto errorEnd
   )
)

rem Set environment variables for the questra config scripts
if not .%UniqueID%==. (
      echo %UniqueID% > C:\serialNo.txt
)

rem Set the proper InstallOption file
if .%prodType%==. (
   set InstallOptionXML=InstallOption.xml
) else (
   set InstallOptionXML=%InstallOptionPath%%prodType%InstallOption.xml
)

rem Set Prefix environment variable if it's not set but prodType is set
if .%Prefix%==. (
	if not .%prodType%==. (
		set Prefix=%prodType%
	)
)

rem Set ProductName environment variable if it's not set but DeviceType is set
if .%ProductName%==. (
	if not .%DeviceType%==. (
		set ProductName=%DeviceType%
	)
)

echo Welcome to Clinical Systems Service Platform Software Install
echo.
echo Service Platform Software Shall be installed in %TargetDir% directory
echo.

echo Service platform installation began on %date% at %time% >> %outfile% 

echo TargetDir %TargetDir% >> %outfile%
echo prodType %prodType% >> %outfile%
echo InstallOptionPath %InstallOptionPath% >> %outfile%
echo Prefix %Prefix% >> %outfile%
echo VNCPort %VNCPort% >> %outfile%
echo VNCHttpPort %VNCHttpPort% >> %outfile%
echo WebPort %WebPort% >> %outfile%
echo TelnetPort %TelnetPort% >> %outfile%
echo HTMLPort %HTMLPort% >> %outfile%
echo TomcatPort %TomcatPort% >> %outfile%
echo UniqueID %UniqueID% >> %outfile%
echo DeviceType %DeviceType% >> %outfile%
echo ProductName %ProductName% >> %outfile%

echo Install Option XML %InstallOptionXML% >> %outfile%

rem Make sure the the local password security policy is configured so that
rem the passwords does not expire (Default is to expire in 42 days)
echo Configuring Local Password security policy >> %outfile%
net accounts /MAXPWAGE:UNLIMITED >> %outfile%

rem Install Insite2 by calling InstallInsite2.bat
call InstallInsite2.bat "%TargetDir%" %InstallOptionXML%

rem If Insite did not get installed correctly, there is no point in install service platform - Bail out!!
if ERRORLEVEL 1 goto errorEnd

rem Install Service Web Apps by calling InstallSvcApps.bat
call InstallSvcApps.bat %InstallOptionXML%
if ERRORLEVEL 1 goto errorEnd

goto SucEnd


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:dequote
  setlocal
  set var=%1
  call set val=%%%var%%%
  set val=####%val%####
  set val=%val:####"=%
  set val=%val:"####=%
  if defined val set val=%val:####=%
  endlocal & set %var%=%val%
  goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:usage
  setlocal
  echo.
  echo.
  echo Usage: InstallSvcPlatform.bat [InstallDir] [Switches] ^<-option values^>
  echo.
  echo         where InstallDir  == optional root install directory.  Default is C:
  echo.
  echo         where possible Switches are:
  echo         -Precheck         == Run InstallPreCheck.bat prior to install.
  echo.
  echo         where possible ^<-option value^> pairs are:
  echo         -WebPort XX       == Apache web server to install on local port XX.
  echo         -VNCPort YYYY     == VNC server will listen for requests on port YYYY.
  echo         -VNCHttpPort YYYY == VNC server will listen for browser requests on port YYYY.
  echo         -TelnetPort ZZ    == port where product's telnet server is configured.
  echo         -HTMLPort HHHH    == alternate port for service agent web extension.
  echo         -TomcatPort SSSS  == alternate port for the tomcat java container comm.
  echo         -ProductType PP   == PP is identifier for the InstallOption.xml file.
  echo                               PP will also be used as the prefix for DeviceName and
  echo                               SerialNumber if -Prefix is not specified.
  echo         -Prefix FF        == FF is the prefix for DeviceName and SerialNumber.
  echo         -UniqueID UU      == UU is the unique identifier to be used for DeviceName and
  echo                               SerialNumber of the agent configuration.
  echo         -DeviceType DD    == DD is DeviceType of ^<AgentType^> section of the agent configuration.
  echo                               DD will also be used as Product if -ProdclsuctName is not specified.
  echo         -ProductName NN   == NN is Product of ^<AgentType^> section of the agent configuration.
  echo.
  endlocal
  goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:processArgs
  set tiv=%1
  set val=%2

  if "%tiv%"=="-WebPort" (
     set WebPort=%val%
  )

  if "%tiv%"=="-VNCPort" (
     set VNCPort=%val%
  )

  if "%tiv%"=="-VNCHttpPort" (
     set VNCHttpPort=%val%
  )

  if "%tiv%"=="-telnetPort" (
     set telnetPort=%val%
  )

  if "%tiv%"=="-TelnetPort" (
     set telnetPort=%val%
  )

  if "%tiv%"=="-tomcatPort" (
     set TomcatPort=%val%
  )

  if "%tiv%"=="-TomcatPort" (
     set TomcatPort=%val%
  )

  if "%tiv%"=="-HTMLPort" (
     set HTMLPort=%val%
  )

  if "%tiv%"=="-UniqueID" (
     set UniqueID=%val%
  )

  if "%tiv%"=="-InstallOptionPath" (
     set InstallOptionPath=%val%
  )
  
  if "%tiv%"=="-ProductType" (
     set prodType=%val%
  )
  
  if "%tiv%"=="-Prefix" (
     set Prefix=%val%
  )
  
  if "%tiv%"=="-DeviceType" (
	 set DeviceType=%val%
  )
  
  if "%tiv%"=="-ProductName" (
	 set ProductName=%val%
  )
  goto :eof

::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:errorEnd
echo Service Setup Failed. Aborting installation of Service Platform.
echo Service Setup Failed. Aborting installation of Service Platform. >> %outfile% 
if not exist %outfile% goto End 
echo See %outfile% for further details.
echo.
set errorlvl=1
goto End

:SucEnd
echo Service Platform installation successfully completed on %date% at %time% >> %outfile%
echo Successfully installed Service Platform. 
echo.
echo ************************************************************************
if not exist %outfile% goto End
echo See the installation details in %outfile%
:End

rem
rem  Delete the install files
rem
echo Removing the install files and directory
echo Removing the install files and directory >> %outfile%
if exist "%INSITE2_HOME%\install" (
     rem cd "%TargetDir%"
     rd /S /Q "%TargetDir%\\install" > nul 2>&1
)
exit %errorlvl%