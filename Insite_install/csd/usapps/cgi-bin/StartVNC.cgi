#!D:/Program Files/InSite2/Perl/bin/perl.exe

use CookieMonster;

$Insite2Home=$ENV{"INSITE2_HOME"};
$InsiteHome=$ENV{"INSITE_HOME"};
$Insite2Home =~ s/\\/\//g;
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
$fdata = "$InsiteHome/cgi-bin/StartStopVNC.dat";
open(DP, "< $fdata" );
@displayPage=<DP>;
close( DP);

# Check if any version of VNC is installed.
$res = system("ComponentControl.exe -vnc -isinstalled -s");
if ( ($res >> 8) == 0 )
{
    SendPage( "<b><font size=5 color=#FF0000>This feature is not installed.</font></b>", "",  @displayPage );
    exit;
}

if ( ! DisruptiveMode() )
{
    SendPage( "<b><font size=5 color=#FF0000>Turn on Disruptive mode before turning on VCO.</font></b>", "", @displayPage );
    exit;
}

#branch on value passed in from html page
$Action = $FORM{"action"};
$Message2="";
for ($Action) {
	$desktopstatus="$InsiteHome/diagLogs/.desktopStatus";
	/start/ and do {
		# startup windows if this is a closed system
		StartDesktop();
		# Use ComponentControl.exe utility to start the VNC server.
		# This utility will set appropriate VNC securities and restart the VNC server if it's already running.
		#print "start VNC as configured\n";
		CookieMonster::runCommand("ComponentControl.exe -vnc -start -s");
		};
	/stop/ and do {
		#print "stop\n";
		# Check if this system's desktop is opened when the VNC started
		# If that's the case, show the reboot message
		if (-e $desktopstatus)
		{
			$reboot=1;
		}
		CookieMonster::runCommand("StopVNC.bat");
		if ($reboot)
		{
			$Message2="<b><font size=5 color=#FF0000>The system must be rebooted before turning it over to the customer</font></b>";
		}
	};
}

$msg = vncStatus( );
SendPage( $msg, $Message2, @displayPage );
exit;

# vncStatus
# check to see if vnc is running, return a message string with status
sub vncStatus( )
{
	# Check to see if VNC is running
	my $msg;
	$res = system("ComponentControl.exe -vnc -isrunning -s");
	if( ($res >> 8) > 0 )
	{
		$msg = "<b><font size=5 color=#00F00FF>VCO is running</font></br>";
	}
	else
	{
		$msg = "<b><font size=5 color=#FF0000>*** VCO is stopped ***</font></br>";
	}
	return $msg;
}

# outputError
# output an error message formatted as a html page
sub outputError( $msg )
{
    print "Content-type: text/html\n\n";

    print "<html>";
    print "<head>";
    print "<style type=\"text/css\">";
    print "body {color: #000;}";
    print "</style>";
    print "</head>";
    print "<body bgcolor=#b5b5b5></body>";
    print "<pre>";
    print $msg;
    print "</pre>";
    print "</body></html>\n";

    exit;
}

#StartDesktop
# Check to see if explorer is runnning,
# if it is not running start it by running userinit.
# This returns when the userinit process terminates.
sub StartDesktop()
{
	# figure out if the desktop is running, if not start it
	@buffer=CookieMonster::runCommand("tasklist /fi \"imagename eq explorer.exe\"");
    $desktop=0;
    chop(@buffer);
    for $n (0 .. $#buffer)
    {
		#print "buffer: " . @buffer[$n] . "\n";
		if( @buffer[$n] =~ /^explorer\.exe /)
		{
			#  the windows desktop is running
			#print "the windows desktop is running\n";
			$desktop=1;
			last;
		}
	}

	# Kill BlockWindowsKeys.exe process used in GE global ultrasound software platform systems, so the system will allow windows hot keys to the VNC user
	CookieMonster::runCommand("taskkill /f /im BlockWindowsKeys.exe");
		
	# If the windows desktop is not running, start it
    if ( ! $desktop  )
    {
		# Backup explorer policy before the policy gets removed
		CookieMonster::runCommand("reg copy HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\ExplorerBackup /s /f");
    
		# Backup Winlogon registry key before "Shell" value is set to "Explorer.exe"
		CookieMonster::runCommand("reg copy \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\" \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\WinlogonBackup\" /s /f");
    
		# Remove the explorer policy so the VNC user will have no windows explorer restrictions
		CookieMonster::runCommand("reg delete HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer /f");
		
		# Set "Shell" value of Winlogon registry key to "Explorer.exe" so userinit will start explorer
		CookieMonster::runCommand("reg add \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\" /v Shell /t REG_SZ /d Explorer.exe /f");
		
        # Start userinit to start explorer
        CookieMonster::runCommand("userinit");
        # Start explorer to My Computer, so that it will read the registry when the restrictions are removed
        CookieMonster::runCommand("explorer.exe /n,/e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}");
        
        # Create Desktop Status file which will be used to close the desktop when VNC stops
        open (DESKTOPSTATUS, ">$desktopstatus") || die "Unable to open desktop status file: $desktopstatus\n";
        print DESKTOPSTATUS "Desktop is opened.";
        close (DESKTOPSTATUS);
        
        # Restore backedup Winlogon registry and explorer policy
        CookieMonster::runCommand("reg copy HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\ExplorerBackup HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer /s /f");
        CookieMonster::runCommand("reg copy \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\WinlogonBackup\" \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\" /s /f");
		CookieMonster::runCommand("reg delete HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\ExplorerBackup /f");
		CookieMonster::runCommand("reg delete \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\WinlogonBackup\" /f");
    }
    return;
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

# DisruptiveMode
# this function tests for Disruptive Mode
# Returns:  1 for disruptive mode
#           0 for not disruptive mode
sub DisruptiveMode()
{
    # check for disruptive mode.
    my $dis_file="$InsiteHome/diagLogs/.statusFile";
    my $nodis_file="$InsiteHome/diagLogs/.noDisruptiveMode";
    my $dis_mode=0;                # default is disruptive mode is disabled
    # print "dis file: $dis_file<br>";
    # If .noDisruptiveMode file exists, don't check disruptive mode. It's assumed that it's always in disruptive mode.
    if(-f $nodis_file)
	{
		$dis_mode=1;
	}
	elsif(-f $dis_file)
    {
        # print "found file<br>";
        open (DISFILE, $dis_file) || die "Unable to open disruptive mode status file: $dis_file\n";
		while ( <DISFILE> )
		{
			if($_ =~ /^Status=1/)
			{
				$dis_mode=1;
			}
		}
		close DISFILE;
    }
    return $dis_mode;
}
