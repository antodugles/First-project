@echo off

rem  Removes auxiliary file or directory as package attribute
rem

"%INSITE2_PKGREPOS_DIR%\Perl\bin\perl" "%INSITE2_PKGREPOS_DIR%\bin\PRremBlob.pl" %*
if ERRORLEVEL 1 goto errorEnd

goto End

:errorEnd
verify error 2> null

:End