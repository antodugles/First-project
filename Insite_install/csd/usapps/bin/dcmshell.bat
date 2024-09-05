@echo off

::
::  dcmshell.bat
::
::  Batch file executes the Dicom Echo utility for a given
::  aetitle, ip, and port.
::
::  usage: dcmshell <aetitle> <ip address> <port>
::
::  Date               Name                 Comments
::  01-Dec-2005        A Kuhn               Initial
::


:: Check that AETitle, IP, and Port are set.
if ""%1"" == """" goto end
if ""%2"" == """" goto end
if ""%3"" == """" goto end


:: Run the dicom echo utility
DcmEcho2.exe -v %1 %2:%3 2>&1

:end