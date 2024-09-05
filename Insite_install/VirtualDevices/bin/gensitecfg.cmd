@echo off

:: Copyright Questra Corporation. All Rights Reserved.
::
:: $Id: gencfg.cmd,v 1.3.2.1 2006/07/20 12:23:59 rsabhlok Exp $
::

verify error 2> nul
setlocal ENABLEEXTENSIONS
if errorlevel 1 echo ERROR: Command extensions are not available. & goto :exit

path %~dp0;%SystemRoot%\system32;%PATH%

set ARGLIST=-template:TEMPLATE -cfgdir:CFGDIR -sitedir:SITEDIR

for %%g in (%*) do (
  call :processarg %%g
  if errorlevel 1 (
    call :usage
    verify error 2> nul & goto :exit
  )
)

for %%g in (TEMPLATE CFGDIR SITEDIR) do (
  if not defined %%g (
    echo ERROR: %%g is not defined.
    call :usage
    verify error 2> nul & goto :exit
  )
)

if not exist "%TEMPLATE%" (
  echo ERROR: Template "%TEMPLATE%" does not exist.
  verify error 2> nul & goto :exit
)

call :IsDirectory "%TEMPLATE%"
if errorlevel 1 (
   echo ERROR: Template "%TEMPLATE%" is not a directory or is not accesible.
   verify error 2> nul & goto :eof
)

if not exist "%CFGDIR%" (
  echo ERROR: Configuration directory "%CFGDIR%" does not exist.
  verify error 2> nul & goto :exit
)

if not exist "%SITEDIR%" (
  echo ERROR: Sitemap directory "%SITEDIR%" does not exist.
  verify error 2> nul & goto :exit
)

set SITEMAP=%SITEDIR%\sitemap.xml
if not exist "%SITEMAP%" (
  echo ERROR: Map file "%SITEMAP%" does not exist.
  verify error 2> nul & goto :exit
)

:: possible refinements:
:: * template specific maps
:: * template specific config directories (could be accomplished by caller).

call :shortpath QSADIR_short "%QSADIR%"
call :shortpath TEMPLATE_short "%TEMPLATE%"
call :shortpath CFGDIR_short "%CFGDIR%"
call :shortpath SITEDIR_short "%SITEDIR%"

:: Run through the configuration files in the template, producing a
:: configuration file in %CFGDIR% for each one.

for %%g in (%TEMPLATE_short%\*.*) do (
  set file=%%g
  call set file=%%file:%TEMPLATE_short%\=%%

  (if defined BACKUPDIR call :backup "%CFGDIR%\%%file%%")
  if /i "%%~xg"==".xml" (
    call :mapfile xml "%SITEDIR%\sitemap.xml" "%TEMPLATE%\%%file%%" "%CFGDIR%\%%file%%"
    if errorlevel 1 goto :exit
  ) else if /i "%%~xg"==".txt" (
    call :mapfile txt "%SITEDIR%\sitemap.xml" "%TEMPLATE%\%%file%%" "%CFGDIR%\%%file%%"
    if errorlevel 1 goto :exit
  ) else (
    call echo WARNING: Ignoring template file "%TEMPLATE%\%%file%%".
  )
)

goto :exit

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:mapfile
  setlocal
  set cmd=%1
  set map=%2
  set input=%3
  set output=%4
  echo Generating %output%...
  call map%cmd% -map %map% -%cmd% %input% > %output%
  endlocal
  goto :eof

:backup
  setlocal
  set cfgfile=%~nx1
  set cfgdir=%~dp1#
  set cfgdir=%cfgdir:\#=%
  call set reldir=%%cfgdir:%QSADIR%\=%%
  call set reldir=%%reldir:%QSADIR_short%\=%%
  if not exist "%BACKUPDIR%\%reldir%" (
    mkdir "%BACKUPDIR%\%reldir%"
    echo %reldir%>> "%STAGE%\pkgdirs.txt"
  )
  if exist "%QSADIR%\%reldir%\%cfgfile%" (
    move "%cfgdir%\%cfgfile%" "%BACKUPDIR%\%reldir%"
  )
  echo %reldir%\%cfgfile%>> "%STAGE%\pkgfiles.txt"
  endlocal
  goto :eof

:usage
  setlocal
  echo Usage: gencfg -template ^<template^> -cfgdir ^<config dir^>
  endlocal
  goto :eof

:processarg
  dir > nul
  set arg=%1
  call :dequote arg
  if defined argspec (
    set %argspec%=%arg%
    set argspec=
    goto :eof
  )
  for %%g in (%ARGLIST%) do (
    for /f "tokens=1,2 delims=:" %%h in ("%%g") do (
      if "%arg%"=="%%h" set argspec=%%i
    )
  )
  if not defined argspec (
    echo ERROR: invalid parameter "%arg%".
    verify error 2> nul & goto :eof
  )
  goto :eof

:: Remove the outermost double quotes from a variable's value. If the
:: variable contains no quotes then it's value is left unchanged.
::
::   call :dequote <varname>
::
:: Quotes are nasty in Windows because cmd.exe honors the quotes when
:: evaluating expressions, however the quotes are not removed from the
:: result of the evaluation. For example, handling quotes in this way
:: could cause a conditional that is intended to test for "%var%"=="value"
:: to actually compare against ""%var%"" instead. This subroutine removes
:: the outermost double quotes from a variable's value so the variable can
:: always be referenced with surrounding quotes. 

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

:: Convert a path to it's short form, and store the result in a variable.
::
::   call :shortpath <varname> <path>
::
:: This is an ugly but necessary hack for Windows NT 4.0 support. Some
:: cmd.exe commands have trouble with long paths in Windows NT 4.0.
:: "for /r" and "start /d" are two that I've personally encountered in
:: the course of writing the service agent update scripts, but there are
:: sure to be more commands that don't like long paths.

:shortpath
  setlocal
  set var=%1
  set val=%~sf2
  endlocal & set %var%=%val%
  goto :eof

:IsDirectory
  setlocal
  cd "%1" 2> nul
  endlocal
  goto :eof

:exit
  endlocal
  if errorlevel 1 verify error 2> nul
