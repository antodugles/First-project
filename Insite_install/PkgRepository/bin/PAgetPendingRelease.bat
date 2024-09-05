@echo off

rem  Retrieves latest release with pending flag set.
rem

"%INSITE2_PKGREPOS_DIR%\Perl\bin\perl" "%INSITE2_PKGREPOS_DIR%\bin\PRgetPendingRelease.pl" %*
if ERRORLEVEL 1 goto errorEnd

goto End

:errorEnd
verify error 2> null

:End