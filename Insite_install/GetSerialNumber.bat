@echo off
rem Returns the serial number from "serialNo.txt" file
rem Returns the serial number up to the manufacturer code if "-nomanufcode" option is set
set SerialNoFilePath=C:\serialNo.txt
if not exist "%SerialNoFilePath%" (
	echo Failed Finding %SerialNoFilePath% 1>&2
	goto END
)

FOR /F "usebackq tokens=1*" %%a IN ("%SerialNoFilePath%") DO (
	set SerialNumber=%%a
)

if "%SerialNumber%"=="" (
	goto FAILED
)

if "%SerialNumber%"=="-1" ( 
	goto FAILED
)

if "%1"=="-nomanufcode" (
	set SerialNumber=%SerialNumber:~0,-3%
)

if not "%SerialNumber%"=="" (
	echo %SerialNumber%	
	goto END
)

:FAILED
echo Failed Getting the Serial Number 1>&2
:END