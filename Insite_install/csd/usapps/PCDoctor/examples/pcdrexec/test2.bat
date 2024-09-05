rem Percent Done How-To; 
rem By echoing the string "PERCENT DONE 5%", the textui will read
rem this value in from the script and display it in the textui
for /L %%c in (0,1,50) do echo PERCENT DONE %%c%% 1>&2

rem Any text that is output to stdout is now automatically redirected
rem by the pcdrexec module to a file.  The name of the file by default
rem is pcdrexec.debug.txt.  The file name is specified in the pcdrexec.p5i
rem file and can be changed there.  The key name for this file is
rem szDebugOutputFile.
echo Debug Text

rem This exits the script with the return result
rem if this value is 0 then the textui will display PASS
rem if this value is != 0 then the textui will display FAILED
rem and print the error message found in the p5i file with the name
rem RetCodeError_<error number>_Result and RetCodeError_<error number>_Message

exit 0

