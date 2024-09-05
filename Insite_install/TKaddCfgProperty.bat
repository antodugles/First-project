@echo off

rem  
rem

"%PERL_HOME%bin\perl" "%INSITE2_HOME%\Questra\TKaddCfgProperty.pl" %*
if ERRORLEVEL 1 goto errorEnd

goto End

:errorEnd
verify error 2> null

:End