#!/usr/local/bin/perl


sub read_input
{
    local ($buffer, @pairs, $pair, $name, $value, %FORM);

    # Read in text
    $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;

    if ( $ENV{'REQUEST_METHOD'} eq "POST" ) {
       read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    } else {
       $buffer = $ENV{'QUERY_STRING'};
    }

    # Split information into name/value pairs
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs) {
        ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%(..)/pack("C", hex($1))/eg;
        $FORM{$name} = $value;
    }

    %FORM;
}



print "Content-type: text/html\n\n";

print "<body bgcolor=#b5b5b5></body>";


$clientIpAddress=$ENV{'REMOTE_ADDR'};
$clientHostName = $ENV{'REMOTE_HOST'};

if(($clientIpAddress eq "127.0.0.1") || ($clientHostName eq "localhost"))
{
	%VAR = &read_input();
	$Cmd = $VAR{"cmd"};
	if($Cmd eq "init") 
	{
	
		print "<center>Network And Dial-up Connection</center>";
		print "<p><p>This configuration is required to set the incoming connection for iLinq/InSite";
		print "<p><p>This should not be used to change any other network configuration";
		print "<p><a href=/uscgi-bin/StartNetworkControl.cgi?cmd=start>Click here to start</a>";

	}
	elsif($Cmd eq "start")
	{
		`Network.lnk`;
		print "Started Network and Dialup Connection";
		print "<p><li>Select the incoming connection";
		print "<p><li>Double click the mouse or hit return on keyboard";
		print "<p><li>Check the box next to the modem listed. Make sure that the box is checked by a tick mark";
		print "<p><li>Click on OK button";
		print "<p><li>Close the Network and Dialup Connection Window";
		print "<p><li>You are now done with this part of configuration";
	
	}

}
else
{
	print "Remote Execution of Network Control Configuration is NOT allowed";
}
print "</html>";

