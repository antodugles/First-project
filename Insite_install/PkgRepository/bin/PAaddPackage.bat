@echo off

rem  Adds a package to the package repository
rem

"%INSITE2_PKGREPOS_DIR%\Perl\bin\perl" "%INSITE2_PKGREPOS_DIR%\bin\PRaddPackage.pl" %*
if ERRORLEVEL 1 goto errorEnd

goto End

:errorEnd
verify error 2> null

:End