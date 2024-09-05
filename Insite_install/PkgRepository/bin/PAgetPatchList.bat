@echo off

rem  Returns an ordered list of pending, previous or current patchlists.
rem

"%INSITE2_PKGREPOS_DIR%\Perl\bin\perl" "%INSITE2_PKGREPOS_DIR%\bin\PRgetPatchList.pl" %*
if ERRORLEVEL 1 goto errorEnd

goto End

:errorEnd
verify error 2> null

:End