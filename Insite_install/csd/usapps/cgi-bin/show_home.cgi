#!/usr/local/bin/perl

####################
### MAIN PROGRAM ###
####################

# Tell the http server to get ready for text...
print("Content-type: text/html\n\n");



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

sub printNavHeader
{
	print "<html><head><title>GEMS Ultrasound Service Home Page</title></head>";
	# Print Just the first frame. Other frames shall be handled based on the user

	print "<frameset rows=120,* border = 0 framespacing = 0 >";
	print "<frame name=left1  src=/service/CSD/release/htdocs/serviceDesktop/primaryNavigationBar.htm ";
	print "scrolling=no  marginwidth=0  marginheight=0 ></frame>";
}

sub printNavFooter
{
	print "</frameset>";
	print "<noframes><body>Need Frames To Run....</body></noframes>";
	print "</html>";
}

%VAR = &read_input(); 
$user = $VAR{"user"};

$clientIpAddress=$ENV{'REMOTE_ADDR'};
$clientHostName = $ENV{'REMOTE_HOST'};

#if(($clientIpAddress eq "127.0.0.1") || ($clientHostName eq "localhost"))
#{
#	$data = `cat ../htdocs/serviceDesktop/index.htm`;
#	print $data;
#}
#else
#{
#	$data = `cat ../htdocs/serviceDesktop/index.htm`;
#	print $data;
#}

if($user == 4)
{
	#$data = `cat ../htdocs/serviceDesktop/index.htm`;
	#print $data;
	printNavHeader();
	print "<frame name=left  src=/uscgi-bin/us_homepage.cgi   ";

	print "scrolling=auto  marginwidth=0  marginheight=0 ></frame>";
	printNavFooter();


}
else
{
	#print "<p><big><center><blink>This page is still under construction</blink></big><p>";
	printNavHeader();
	print "<frame name=left src=/uscgi-bin/general_user.cgi scrolling=auto marginwidth=0 marginheight=0></frame>";
	printNavFooter();	

}

exit 0;
