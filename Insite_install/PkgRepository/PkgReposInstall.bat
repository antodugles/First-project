@echo off
::
::  Batch file for:
::     Pkg Repository install
::
::


:INSTALLIT
if exist "%INSITE2_PKGREPOS_DIR%" (
   echo Package Repository already exists.
   goto UpdateAPI
)

echo creating Package Repository
md "%INSITE2_PKGREPOS_DIR%"
unzip Perl\myperl.zip -d "%INSITE2_PKGREPOS_DIR%\Perl" >> nul
REM echo Perl unzipped
copy /y reposIndex.xml "%INSITE2_PKGREPOS_DIR%" >> nul

:UpdateAPI
REM echo copy bin dir
xcopy /y /q /e bin "%INSITE2_PKGREPOS_DIR%\bin\" >> nul

REM echo update md5 sum
"%INSITE2_PKGREPOS_DIR%\bin\PAsetMD5.bat"

echo Package Repository created
