#!D:/Program Files/InSite2/Perl/bin/perl.exe
$debug = 0;
#$debug = 1;

use CookieMonster;

sub PrintDebug {
    if ($debug) {
        print "Debug:  @_<br>\n";
        #`echo @_ >> c:/temp/xxx.txt`;
    }
}
sub PrintDebugArr {
    if ($debug) {
        my $i;
        my @arr = @_;
        my $last = $#arr;
        print "Debug   -:";
        for $i ( 0 .. $last )
        {
            print "[$i]$arr[$i]:";
            if ( $i ==  $last ) {
                print "-";
            }
        }
        print "<br>\n";PrintDebugArr(@ENV);

    }
}


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
	
	print "<html>";
	print "<head>";
	print "<style type=\"text/css\">";
	print "body {color: #000;}";
	print "</style>";
	print "</head>";
	print "<body  bgcolor=\"#FFFFCC\">";
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

if ($ENV{'IMAGE_FILE_PATH'} eq ""){
   $ImageFilePath = "D:\\Export";
}
else
{
   $ImageFilePath = $ENV{"IMAGE_FILE_PATH"};
}


@ImageFileDirs = split(/;/,$ImageFilePath);


if ($ENV{'IMAGE_VIEW_EXT'} eq ""){
   $ImageFileExts = ".JPEG;.jpeg;.JPG;.jpg;.GIF;.gif";
}
else
{
   $ImageFileExts = $ENV{"IMAGE_VIEW_EXT"};
}

$ImageFileExts =~ s/;/|/g;

$clientIpAddress=$ENV{'REMOTE_ADDR'};
$clientHostName = $ENV{'REMOTE_HOST'};

sub ShowInitPage
{
    print("Content-type: text/html\n\n");
    printNavHeader();
    print "<center><h2>Images available </h2>";
	
    my $dir;
    PrintDebugArr(@ImageFileDirs);

    foreach $dir (@ImageFileDirs) {
	my @ImageDirList = CookieMonster::runCommand("cmd /c \" dir /b $dir \"");
      chop(@ImageDirList);

	my $i=0;
	print "<center><h2>Image files in $ImageFileBaseDir$dir </h2>";
	print "<table border=5 cellspacing=5 cellpading=5 bordercolor=\"gray\">";
	for(@ImageDirList)
	{

	    $AbsPath = $ImageDirList[$i];
	    PrintDebug( "$AbsPath");
		#if(-f $AbsPath)
		{
		    if ($AbsPath =~ /$ImageFileExts/ )
		    {
			$AbsPath =~ tr/ /+/;
                        my @st=stat("$dir/$AbsPath");
                        my $date = localtime($st[9]);
                        my $fileUrl = $dir . "/" . $AbsPath;
                        $fileUrl =~ s^\\^/^g;  # for the URL change backslash to forward slash
			print "<tr>\n";
                        print"<td>$date</td>";
                        print"<td>$ImageDirList[$i]</td><td><a href=/uscgi-bin/ImageViewer.cgi?cmd=ShowImage&file=$fileUrl >View<a></td>\n";
                        print "</tr>";
		    }
		}
		$i++;

	}
	print "</table></center>";
    }

    print "</center>";
    printNavFooter();


}


if(($Cmd eq  "init")|| ($Cmd eq ""))
{
	ShowInitPage();
}



elsif($Cmd eq "ShowImage")
{
	print("Content-type: text/html\n\n");
	
	$ReqLog = $VAR{"file"};

# convert the local path to an Apache alias path.
#  i.e.  C:\ becomes \CDrive\.
#
#
#  In the httpd.cfg file, must include alias for each
#  Alias    CDrive   "C:\"
#  Alias    DDrive   "D:\"
#  and others you may need.  The above alias should already
#  exist.

	$ReqLog =~ s/:/Drive/;
      $ImgPath = "/" . $ReqLog;

	    $space=unpack("C"," ");
	    $hex_space=sprintf "%1x",$space;
	    $hex_space="%".$hex_space;
	    $ImgPath =~ s/ /$hex_space/eg;			
	    $data="<img src=$ImgPath>";
	
	print "<center>$data<br><b>Right click and choose save to save the image</b><br><a href=/uscgi-bin/ImageViewer.cgi?cmd=init><i>Go Back</i></a></center>";
	#printNavFooter();
}

else
{
	printNavHeader();
	printNavFooter();	

}

exit 0;
