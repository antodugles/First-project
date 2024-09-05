@echo off
::
::  Batch file for:
::     Dockable Device components install
::
::


:INSTALLIT
if "%INSITE2_ROOT_DIR%"=="" (
   echo Questra Service agent was not successfully.  Dockable Device component install failed.
   goto ERROREND
)

if exist "%INSITE2_ROOT_DIR%\virtuals" (
   echo Dockable Device Components already installed.
   goto ERROREND
)

if not exist "%INSITE2_HOME%\Export" (
   md "%INSITE2_HOME%\Export"
)

md "%INSITE2_ROOT_DIR%\virtuals"
md "%INSITE2_ROOT_DIR%\virtuals\logs"

if "%INSITE2_PKGREPOS_DIR%"=="" (
   md "%INSITE2_ROOT_DIR%\virtuals\PkgRepository"
)

echo copying bin files
copy /y xml\VirtualIndex.xml "%INSITE2_ROOT_DIR%\virtuals" >> nul
copy /y xml\PkgIndex.xml "%INSITE2_ROOT_DIR%\virtuals" >> nul
copy /y bin\gensitecfg.cmd "%INSITE2_ROOT_DIR%\bin" >> nul

copy /y ..\Utils\DeviceHandler.exe "%INSITE2_HOME%\bin" >> nul

echo copying base templates
xcopy /y /q /e basetemplates "%INSITE2_ROOT_DIR%\virtuals\basetemplates\" >> nul

echo copying device sitemaps
xcopy /y /q /e sitemaps "%INSITE2_ROOT_DIR%\virtuals\sitemaps\" >> nul
copy /y ..\ReplaceEnvVars.pl "%INSITE2_ROOT_DIR%\virtuals\sitemaps" >> nul


rem loop through each sitemap setting up the install directories, etc.
rem
for /f "delims=" %%g in ('dir /ad/s/b "%INSITE2_ROOT_DIR%\virtuals\sitemaps"') do (
   "%PERL_HOME%bin\perl" "%INSITE2_ROOT_DIR%\virtuals\sitemaps\ReplaceEnvVars.pl" "%%g\AgentConfig.xml" "%%g\sitemap.xml"
)

goto END

:ERROREND
echo "Dockable Device components install failed."
exit /b 1

:END
echo Package Repository created