@echo off
REM Example RFS Preprocessor
REM Author: Andy Kant (Andrew.Kant@ge.com)
REM Date:      Sep.14.2006
REM Modified:  FEB.09.2007
REM Usage: preprocessor.bat [problemType] [problemAreas] [rfsFolder]
REM Notes:
REM   [problemAreas] must use ";" for delimiters
REM   [rfsFolder] is where the preprocessed data (ie. log files) to be sent to the backoffice can be stored 
REM   Must return 0 for success:
REM     exit /B 0
REM   Must return a negative integer for failure:
REM     exit /B -1

REM Set debug=true to enable debug mode.
set debug=false

REM Initialize.
:init
cls
set blank=
set tab=  
set err_desc=Unknown error.
set err_code=-1
set err_arg=
set pwd=^&cd
echo.
echo %tab%Example RFS Preprocessor
echo %tab%------------------------

REM Grab parameters.
:grab_params
set problemType=%1
set problemAreas=%2
set rfsFolder=%3

REM Output parameters.
:output_params
if not %debug%==true goto iterate_problemareas
echo %tab%Parameters:
echo %tab%%tab%problemType=%problemType%
echo %tab%%tab%problemAreas=%problemAreas%
echo %tab%%tab%rfsFolder=%rfsFolder%
echo %tab%%tab%pwd=%pwd%
echo.
pause

REM Iterate through problem areas.
:iterate_problemareas
REM Alter tokens=1,2,3 to as many possible problem types that can be selected simultaneously.
echo %tab%Copying files to: %rfsFolder%
for /F "tokens=1,2,3 delims=;" %%A in (%problemAreas%) do (
	REM Each problem area can be accessed as %%A %%B %%C etc...
	set i=%%A
	set j=%%B
	set k=%%C
)
set problemArea=%i%
:process_token
REM A problem area can be detected by:  if not "%problemArea%"=="" SOME_COMMAND
if not "%problemArea%"=="" (
	if %problemArea%==Hardware (
		if not exist hardware.log (
			set err_code=-1
			set err_arg=hardware.log
			goto error
		)
		xcopy /Q /Y hardware.log %rfsFolder%
	)
	if %problemArea%==Network (
		if not exist network.log (
			set err_code=-1
			set err_arg=network.log
			goto error
		)
		xcopy /Q /Y network.log %rfsFolder%
	)
	if %problemArea%==Software (
		if not exist software.log (
			set err_code=-1
			set err_arg=software.log
			goto error
		)
		xcopy /Q /Y software.log %rfsFolder%
	)
)
if not "%j%"=="" (
	set problemArea=%j%;
	set j=
	goto process_token
)
if not "%k%"=="" (
	set problemArea=%k%;
	set k=
	goto process_token
)
echo.

REM Exit preprocessor.
:exit
echo %tab%Finished processing
if %debug%==true pause
exit 0

REM Return error code.
:error
echo.
echo %tab%ERROR: %err_code%
if %err_code%==-1 echo %tab%%tab%Missing input file: %err_arg%
if %debug%==true pause
exit %err_code%