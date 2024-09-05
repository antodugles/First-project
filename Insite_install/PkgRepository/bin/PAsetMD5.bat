@echo off

rem  Sets the MD5 checksum for the reposIndex.xml file.
rem

"%INSITE2_PKGREPOS_DIR%\Perl\bin\perl" "%INSITE2_PKGREPOS_DIR%\bin\PRsetMD5.pl" %*
if ERRORLEVEL 1 goto errorEnd

goto End

:errorEnd
verify error 2> null

:End