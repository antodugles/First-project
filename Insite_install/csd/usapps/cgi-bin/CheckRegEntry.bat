:: This function will check for the exsitence of a registry key
:: echos 0 if entry exisits.
@echo off
regUtil -q -k %1 2>nul
echo %errorlevel%
