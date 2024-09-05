#!C:/PerlInsite2/bin/perl.exe


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
	print "<html><body  bgcolor=\"#FFFFCC\">";
	print "<p>";
	print "<p>";

}


sub printNavFooter
{
	print "</body></html>";
}

sub printBackLink($backLink)
{
	print "<p><a href=$backLink>back</a><p>";
}


%VAR = &read_input(); 
$Cmd = $VAR{"cmd"};
$LogFileDir=$VAR{"LOG_DIR"};

$TestRoot = $ENV{'TEST_ROOT'};
$TargetRoot = $ENV{'TARGET_ROOT'};

$Product = $ENV{"PRODUCT"};
$ResourceFileDir=$TestRoot. "\\". "resources\\idunn\\userdefs\\";

$clientIpAddress=$ENV{'REMOTE_ADDR'};
$clientHostName = $ENV{'REMOTE_HOST'};

sub ShowInitPage
{
	
	printNavHeader();
	print("<center><h2>User Defined Resource Files</h2>");
	print("<table border=5 cellpadding=10 cellspacing=1 bordercolor=\"gray\">");
	
	print("<tr><td>globalconfig.res</td><td><a href=/uscgi-bin/ResourceFileUtil.cgi?cmd=ShowResFile&file=globalconfig.res>View</a></td><td><a href=/uscgi-bin/ResourceFileUtil.cgi?cmd=SaveResFile&file=globalconfig.res>Save</td></tr></table>");
	if($Product eq "Radiology.Musashi")
	{
		
		print "<br><center><h2>LOGIQ9 Application Software Specific files</h2>";
		print("<table border=5 cellpadding=10 cellspacing=1 bordercolor=\"gray\"><tr><td>GhostInfo.txt</td><td><a href=/uscgi-bin/ResourceFileUtil.cgi?cmd=ShowResFile&file=GhostInfo.txt>View</a></td><td><a href=/uscgi-bin/ResourceFileUtil.cgi?cmd=SaveResFile&file=GhostInfo.txt>Save</td></tr>");
		print("<tr><td>swversion-Musashi.res</td><td><a href=/uscgi-bin/ResourceFileUtil.cgi?cmd=ShowResFile&file=swversion-Musashi.res>View</a></td><td><a href=/uscgi-bin/ResourceFileUtil.cgi?cmd=SaveResFile&file=swversion-Musashi.res>Save</td></tr>");
		print("<tr><td>swbuild-musashi.res</td><td><a href=/uscgi-bin/ResourceFileUtil.cgi?cmd=ShowResFile&file=swbuild-musashi.res>View</a></td><td><a href=/uscgi-bin/ResourceFileUtil.cgi?cmd=SaveResFile&file=swbuild-musashi.res>Save</td></tr></table>");
	}
	#print "</table>";
	$ResFile= $ResourceFileDir . "\\" . "globalconfig.res";
	
	printNavFooter();


}

if($Cmd eq "init")
{
	ShowInitPage();
}
elsif($Cmd eq "ShowResFile")
{
	print("Content-type: text/html\n\n");
	$ResFileName =$VAR{"file"};
	if($Product eq "Radiology.Musashi")
	{
		if($ResFileName eq "GhostInfo.txt")
		{
			$ResourceFileDir="c:";
		}
		elsif($ResFileName eq "swversion-Musashi.res" || $ResFileName eq "swbuild-musashi.res")
		{
			$ResourceFileDir="$TargetRoot\\resources\\idunn\\setup";
		}
	}
		$ResFile= $ResourceFileDir . "\\" . $ResFileName;
	print $ResFile;
	$data = `cmd /c \" type $ResFile\"`;
	print "<pre> $data </pre>";
	print "<center><a href=/uscgi-bin/ResourceFileUtil.cgi?cmd=init>Go Back</i></a></center>";
	printNavFooter();
}
elsif($Cmd eq "SaveResFile")
{
	
	$ResFileName =$VAR{"file"};
	print("Content-type: userdef/resource\r\nContent-disposition: attachment;filename=$ResFileName\n\n");
	if($Product eq "Radiology.Musashi")
	{
        	if($ResFileName eq "GhostInfo.txt")
        	{
                	$ResourceFileDir="c:";
        	}
	elsif($ResFileName eq "swversion-Musashi.res" || $ResFileName eq "swbuild-musashi.res")
        	{
                	$ResourceFileDir="$TargetRoot\\resources\\idunn\\setup";
        	}
	}
	$ResFile= $ResourceFileDir . "\\" . $ResFileName;
	$data = `cmd /c \" type $ResFile\"`;
	
	
	print ("$data");


	#printNavFooter();

}

else
{
	printNavHeader();
	ShowInitPage();
	
	printNavFooter();	

}

exit 0;
