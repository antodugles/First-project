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
    PrintDebug($buffer);

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
	print "</head>";
        print "</head><body bgcolor=\"#FFFFCC\">\n";
	print "<p>";
	print "<p>";
}

sub printNavFooter
{
        print "</body>\n";
	print "</html>";
}

printNavHeader();
%VAR = &read_input(); 
$Cmd = $VAR{"cmd"};

$clientIpAddress=$ENV{'REMOTE_ADDR'};
$clientHostName = $ENV{'REMOTE_HOST'};

if(($Cmd eq  "init")|| ($Cmd eq ""))
{
    print "<center>\n";
    print "<h3>\n";
    print "This will gather up logs and presets.  It will then place them in the export directory for retrieval by the On Line Center.\n";
    print "</h3 >\n";
    print "<p><p>\n";
    print "<form name=\"FileChooser\" action=\"/uscgi-bin/GatherLogs.cgi\" method=\"GET\" > \n";
    print "   <input type=hidden name=\"cmd\" value=\"compress\" />\n";
    print "   <input type=\"submit\" value=\"Gather Logs\" />\n";
    print "</form>\n";

    print "</center>\n";

}
elsif($Cmd eq "compress")
{

	  if ($ENV{'IMAGE_ZIP_HOME'} eq ""){
           $imageziphome = "D:\\Export";
        }
        else
        {
           $imageziphome = $ENV{'IMAGE_ZIP_HOME'};
        }
        my $zipFile = $imageziphome . "\\Logs_"  . time . ".zip";
        $perlhome = $ENV{'PERL_HOME'};
        my $cmd = "\"\"" . $perlhome . "bin\\perl\" GatherLogs.pl -out \"$zipFile\" 2>&1\"";
        PrintDebug($cmd);
        @res = CookieMonster::runCommand($cmd);
        # print"<pr>@res</pr><br /><br />\n";



        print "<center><h3> Logs are zipped up and located in<br /> $zipFile.</h3></center>\n";


}
printNavFooter();

exit 0;
