#!/usr/local/bin/perl.exe

$Target_root=$ENV{"TARGET_ROOT"};
$Target_root =~ s/\\/\//g;

print "Content-type: text/html\n\n";

$accessLog=$ENV{"INSITE_HOME"} . "/../svcpform/accessLog.txt";
$AccText = `tail -1 $accessLog`;
($AccessLevel, $AccessDate, $AccessRes) = split(/;/,$AccText);

$buffer=$ENV{'QUERY_STRING'};
@pairs=split(/&/,$buffer);
foreach $pair (@pairs)
{
    ($name,$value) = split(/=/,$pair);
    $value=~tr/+/ /;
    $value =~ s/%(..)/pack("C",hex($1))/eg;
    $FORM{$name}=$value;
}
if( !(($ENV{'REMOTE_ADDR'} eq "127.0.0.1") || ($ENV{'REMOTE_HOST'} eq "localhost")) ){
    if ( ! DisruptiveMode()) {
        outputError("You must be running locally, or be in disurptive mode before running this diagnostic.");
        exit;
    }
}

# read in html page that will be served
if ( $AccessLevel =~/^Class M$/ ) {
    $fdata = "$Target_root/service/svcpform/cgi-bin/StartStopOP.dat";
} else {
    $fdata = "$Target_root/service/svcpform/cgi-bin/StartStopOPNonProprietary.dat";
}
open(DP, "< $fdata" );

@displayPage=<DP>;
close( DP);

# Check and see if GETestApp.exe is installed
if ( ! (-e "$Target_root/bin/GETestApp.exe") ) {
    SendPage( "<b><font size=5 color=#FF0000>This feature is not installed.</font></b>", @displayPage );
    exit;
}

#branch on value passed in from html page
$KillCmd=$Target_root . "/bin/StopProcess.exe";
if ( ! ( -e $KillCmd ) ) {
   $KillCmd = $Target_root . "/bin/kill.exe -f";
}
$Action = $FORM{"action"};
for ($Action) {
    /start/   and do {#Kill OP before starting it
         `$KillCmd GETestApp`;
          $cmd = "cmd /c $Target_root/bin/GETestApp.exe";
          $cmd =~s/\\/\\\\/g;
          `$cmd`;
                  
          };
    /stop/     and do {
          `$KillCmd GETestApp`;
        
    };
}

$msg = opStatus( );
SendPage( $msg, @displayPage );
exit;

# opStatus
# check to see if vnc is running, return a message string with status
sub opStatus( )
{
    # Check to see if OP is running
    $buffer=`$Target_root/service/insite/bin/tlist | grep GETestApp.exe`;
    @entry=split(/[ \t]/,$buffer);
    my $msg;
    if( $entry[1] eq "GETestApp.exe" )
    {
       $msg = "<b><font size=5 color=#FF0000>Please reboot the system at the end of OP test</font></br>";
    }
    else
    {   
        $msg = "<b><font size=5 color=#FF0000>Please reboot the system at the end of OP test</font></br>";
    }
    return $msg;
}

#########################################
# DisruptiveMode
# this function tests for Disruptive Mode
# Returns:  1 for disruptive mode
#           0 for not disruptive mode
sub DisruptiveMode()
{
    # check for disruptive mode.
    my $dis_file="$Target_root/service/svcpform/diagLogs/.statusFile";
    $dis_file =~ s,\\,/,g;
    my $dis_mode=0;                # default is disruptive mode is disabled
    if(-f $dis_file)
    {
        my $status_str1=`grep Status= $dis_file | cut -f2 -d=`;
        chop $status_str1;
        my @status_str=split(/\n/,$status_str1);
        my $temp_str=$status_str[$#status_str];
        if($temp_str =~ /1/)
        {
            $dis_mode=1;
        }

    }
    #my $msg = "$dis_mode    $dis_file";
    #outputError($msg);
    return $dis_mode;
}

# outputError
# output an error message formatted as a html page
sub outputError()
{
    print "<html>";
    print "<body bgcolor=lightyellow></body>";
    print "<br><br><center><font color=red><h2>";
    print @_;
    print "</h3></font></center>";
    print "</body></html>\n";
}



#SendPage
# This sends the html page.  It replaces the tag XXX in the page with Status
# Inputs:  $Status      Status message that replaces XXX
#          @displayPage HTML page to send
# Returns: nothing
sub SendPage( $Status, @displayPage)
{
    # This function will send the html page out to the server.
    # Inputs:  $Status:  The status message to send
    #          @displayPage:  The page to send.
    # The followind sends the page.  It replaces the tag XXX with Status
    my $Status = shift(@_);
    foreach $line  ( @_ ){
        $line =~ s/XXX/$Status/;
        print $line;
    }
}

