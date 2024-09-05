//
// A simple Jscript program to launch the Event Log Reader Configuration
// tool if not already launched.  It has 2 purposes: bring it forward
// if already running and provide a command line launch for the tool.
//

var WSH = WScript.CreateObject("WScript.Shell");
var msg = "";

var customBrowserRunning = 0;
//var startCommand = "CustomBrowser -configtool \"%INSITE_HOME%/html/events.html\"";
var startCommand = "CustomBrowser -service \"%INSITE_HOME%/html/events.html\"";

// the AppActivate command brings the app with title "Events" forward if
// it is already running
result = WSH.AppActivate("Events");

if (!result)
    WSH.Run(startCommand);
//else
   //WScript.Echo( "The Event Log Reader Config Tool is already running \n" + msg );


