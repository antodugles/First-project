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

sub printNavHeader
{
	print("Content-type: text/html\n\n");
	print("<BODY bgcolor = lightyellow ></BODY>");
	print "<html>";
	print "<p>";
	print "<p>";
	print "<center><h2><u>SetDebug <i>Utility</u></h2></i></center>";
	

}


sub printNavFooter
{
	print "</html>";
}

sub printInitLink()
{
	print "<p><a href=/uscgi-bin/SetDebug.cgi?cmd=init>back</a><p>";
}


$clientIpAddress=$ENV{'REMOTE_ADDR'};
$clientHostName = $ENV{'REMOTE_HOST'};



sub ShowInitPage
{
	printNavHeader();
 	print("<center>");
	print("<form action=/uscgi-bin/SetDebug.cgi?cmd=execute>");
	print("<table border=5 cellpadding=10 cellspacing=1>");
	print("<tr><td><b>Variable</b></td><td><input type=text name=Variable></td></tr>");
	print("<tr><td><b>Value</b></td><td><input type=text name=Value></td></tr>");
	print("<input type=hidden name=cmd value=execute><p><p>");
	print("</table>");
	print("<p><p>");
	print("<input type=submit name=submit value=SET>");
	print("</form>");
 	print("</center>");
	printNavFooter();
	

}

%VAR = &read_input(); 
$Cmd = $VAR{"cmd"};

if($Cmd eq "init")
{
	ShowInitPage();
}
elsif($Cmd eq "execute")
{
	printNavHeader();
	$Variable = $VAR{"Variable"};
	$Value = $VAR{"Value"};

	if($Variable eq "")
	{
		print("Enter a valid variable name");
		printInitLink();
		printNavFooter();
		exit(0);
	}
	elsif($Value eq "")
	{
		print("Enter a valid debug value for <b>$Variable</b> ");
		printInitLink();
		printNavFooter();
		exit(0);
	}
	$ret = `SetDebug.exe $Variable $Value`;
	print("Executed SetDebug.exe $Variable $Value<p>");
	print("Execution Status: $ret");
	printNavFooter();
}
else
{
	ShowInitPage();
}


exit 0;
