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
        print "<br>\n";
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
        print("Content-type: text/html\n\n");
	print "<html>\n";
        print "<head>\n";
	print "<style type=\"text/css\">";
	print "body {color: #000;}";
	print "</style>";
        print "<script type=\"text/javascript\" src=\"/service/ImageDelete.js\"></script>\n";
        print "</head><body bgcolor=\"#FFFFCC\">\n";
	print "<p>";
	print "<p>";
}

sub printNavFooter
{
        print "</body>\n";
	print "</html>";
}

%VAR = &read_input(); 
$Cmd = $VAR{"cmd"};
$LogFileDir=$VAR{"LOG_DIR"};

#Temporary log file directory. Get the correct stuff from Israel

if ($ENV{'IMAGE_FILE_PATH'} eq ""){
   $ImageFilePath = "D:\\Export";
}
else
{
   $ImageFilePath = $ENV{"IMAGE_FILE_PATH"};
}

@ImageFileDirs = split(/;/,$ImageFilePath);

if ($ENV{'IMAGE_FILE_EXT'} eq ""){
   $ImageFileExts = ".JPEG;.jpeg;.JPG;.jpg;.GIF;.gif;.DCM;.dcm";
}
else
{
   $ImageFileExts=$ENV{"IMAGE_FILE_EXT"};
}

$ImageFileExts =~ s/;/|/g;

sub ShowInitPage
{
    printNavHeader();

    print "<center><h2>Images available </h2>\n";
	
    my $dir;

    print "<form name=\"input\" onsubmit=\"return false;\" method=\"get\" id=\"DeleteForm\">\n";
    print "<input type=\"hidden\" name=\"cmd\" value=\"delete\" >\n";
    foreach $dir (@ImageFileDirs) {
	my @ImageDirList = CookieMonster::runCommand("cmd /c \" dir /b  $dir\\ \"");
	chop(@ImageDirList);
	

	my $i=0;
	print "<center><h2>Image files in $ImageFileBaseDir$dir </h2>\n";
	print "<table border=5 cellspacing=5 cellpading=5 bordercolor=\"gray\">\n";
	for(@ImageDirList)
	{
	    $AbsPath = $ImageDirList[$i];

		#if(-f $AbsPath)
		{

		    $okay = 0;

	          # Checks for wildcard extension.
		    if ($ImageFileExts =~ /\*/)
		    {

			 # Makes sure the path is not a directory
                   if ($AbsPath =~ /\./)
                   {

                      $okay = 1;
                   }
                }
                else
                {

                   if ($AbsPath =~ /$ImageFileExts/)
                   {

                      $okay = 1;
                   }
                }

                if ($okay == 1)
                {
                        my @st=stat("$dir/$AbsPath");
                        my $date = localtime($st[9]);
			print "<tr>";
                        print"<td><input type=\"checkbox\" onmouseup=\"FileSelect(this)\" name=\"$dir\\$AbsPath\"></td>";
                        print"<td>$date</td>";
                        print"<td>$AbsPath</td>";
                        print "</tr>\n";
		    }
		}
		$i++;

	}
	print "</table></center>\n";
    }
    print "<br /><table border=0>\n";
    print "<tr>\n";
    print "<td><input type=\"button\" onmousedown=\"SubmitForm(\'compress')\" Name=\"Submit\" Value=\"Compress Files\" ></td>\n";
    print "<td>&nbsp&nbsp</td>";
    print "<td><input type=\"button\" onmousedown=\"SubmitForm('delete')\" Name=\"Submit\" Value=\"Delete Files\" ></td>\n";
    print "</tr>\n";
    print "</table>\n";
    print "</form>\n";
    print "</center>\n";
    printNavFooter();


}


if(($Cmd eq  "init")|| ($Cmd eq ""))
{
	ShowInitPage();
}



elsif($Cmd eq "delete")
{
        printNavHeader();

        my $file;
        my %form = read_input();
        print "<h3><center>The following files were deleted:</center><br>\n";
        foreach $file (keys %form) {
            if ($file =~ /^cmd/ ) {
                next;
            }
            $file =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg; # convert any hexcodes back to ASCII

            unlink $file;
            print("$file<br>\n");
        }
        print "</h3>\n";
       	print "<br><a href=/uscgi-bin/ImageCompressDelete.cgi?cmd=init><i>Go Back</i></a></center>\n";
	printNavFooter();	
}
elsif($Cmd eq "compress")
{
	printNavHeader();

        my $file;

        my $imageziphome = "";
        if ($ENV{'IMAGE_ZIP_HOME'} eq ""){
           $imageziphome = "D:\\Export";
        }
        else
        {
           $imageziphome = $ENV{'IMAGE_ZIP_HOME'};
        }

        my $zipFile = $imageziphome . "\\" . time . ".zip";

        my $CATALINAHOME = $ENV{'CATALINA_HOME'};
        $CATALINAHOME =~ s/\\$//g;  #remove trailing backslash

        my $cmd = "\"$CATALINAHOME\\webapps\\modality-csd\\usapps\\bin\\zip\" -9 $zipFile ";
        my %form = read_input();
        print "<h3><center>The following files were compressed and added to $zipFile:</center><br>\n";
        foreach $file (keys %form) {
            if ($file =~ /^cmd/ ) {
                next;
            }
            $file =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg; # convert any hexcodes back to ASCII
            $cmd .= " \"" . $file . "\"";
        }
        $cmd =~ s/\\\.\\/\\/g; # replace:  '\.\'  with '\'
        #$cmd = "sleep 10 & $cmd";
        PrintDebug($cmd);
        my @res = CookieMonster::runCommand("\"".$cmd."\"");
        chop(@res);

        print "<br />";
        for $i (0..$#res)
        {
           print "$res[$i]<br> ";
        }
   
        print "\n";
        print "</h3>\n";
       	print "<br><a href=/uscgi-bin/ImageCompressDelete.cgi?cmd=init><i>Go Back</i></a></center>\n";
	printNavFooter();	
}

else
{
	printNavHeader();
	printNavFooter();	

}

exit 0;
