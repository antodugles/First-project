#!D:/Program Files/InSite2/Perl/bin/perl.exe
# This is just a wrapper cgi for DiagExecuteIF.exe because Apache kills a cgi process running more than 15 minutes for  CPU resource reservation and 
# RLimitCPU directive doesn't work on Windows. 

use CookieMonster;     

# Get Post data
read( STDIN, $postdata, $ENV{ "CONTENT_LENGTH" }); 
$ExecuteDataPath = $ENV{"INSITE_HOME"} . "\\html\\diags\\ExecuteData.xml";

# Save the Post data in %INSITE_HOME%\html\diags
open ExecuteData, ">$ExecuteDataPath";
print ExecuteData $postdata;
close ExecuteData;

# Run DiagExecuteIF.exe with ExecuteData.xml as STDIN
$cmd = "DiagExecuteIF.exe <\"" . $ExecuteDataPath . "\"";

@response = CookieMonster::runCommand($cmd);
print @response;