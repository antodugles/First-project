#!D:/Program Files/InSite2/Perl/bin/perl.exe

use CookieMonster;

$InsiteHome=$ENV{"INSITE_HOME"};
$InsiteHome =~ s/\\/\//g;

print "Content-type:text/html \n\n";
$buffer=$ENV{'QUERY_STRING'};
@pairs=split(/&/,$buffer);
foreach $pair (@pairs)
{
    ($name,$value) = split(/=/,$pair);
    $value=~tr/+/ /;
    $value =~ s/%(..)/pack("C",hex($1))/eg;
    $FORM{$name}=$value;
}

# read in html page that will be served
$fdata = "$InsiteHome/cgi-bin/StartStopTlnt.dat";
open(DP, "< $fdata" );
@displayPage=<DP>;
close( DP);

# Check and see if Tlnt server is installed
$WinDir=$ENV{'SYSTEMROOT'};
$WinDir =~ s/\\/\//g;
if ( ! (-e "$WinDir/system32/tlntsvr.exe") ) {
    SendPage( "<b><font size=5 color=#FF0000>This feature is not installed.</font></b>", "",  @displayPage );
    exit;
}


#branch on value passed in from html page
$Action = $FORM{"action"};
$Message2="";
for ($Action) {
    /start/   and do {
        CookieMonster::runCommand("ComponentControl.exe -telnet -startservice -s");
    };
    /stop/     and do {
        CookieMonster::runCommand("ComponentControl.exe -telnet -stopservice -s");
    };
}





$msg = tlntStatus( );
SendPage( $msg, $Message2, @displayPage );
exit;

# tlntStatus
# check to see if telnet server is running, return a message string with status
sub tlntStatus( )
{
    # Check to see if telnet server is running
	@buffer=CookieMonster::runCommand("tasklist /fi \"imagename eq tlntsvr.exe\"");
    chop(@buffer);
    my $msg;
    for $n (0 .. $#buffer)
    {
		#print "buffer: " . @buffer[$n] . "\n";
		if( @buffer[$n] =~ /^tlntsvr\.exe /)
		{
			$msg = "<b><font size=5 color=#00F00FF>Telnet Server is running</font></br>";
			return $msg;
		}
	}

    $msg = "<b><font size=5 color=#FF0000>*** Telnet Server is stopped ***</font></br>";
    return $msg;
}

# outputError
# output an error message formatted as a html page
sub outputError( $msg )
{
    print "Content-type: text/html\n\n";

    print "<html>";
    print "<body bgcolor=#b5b5b5></body>";
    print "<pre>";
    print $msg;
    print "</pre>";
    print "</body></html>\n";

    exit;
}



#SendPage
# This sends the html page.  It replaces the tag XXX in the page with Status
# Inputs:  $Status      Status message that replaces XXX
#          @displayPage HTML page to send
#          $Msg2 is a second message displayed after the main message
# Returns: nothing
sub SendPage( $Status, $Msg2, @displayPage)
{
    # This function will send the html page out to the server.
    # Inputs:  $Status:  The status message to send
    #          @displayPage:  The page to send.
    # The followind sends the page.  It replaces the tag XXX with Status
    my $Status = shift(@_);
    my $Msg = shift(@_);
    foreach $line  ( @_ ){
        $line =~ s/XXX/$Status/;
        $line =~ s/YYY/$Msg/;
        print $line;
    }
}

