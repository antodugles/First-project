#!D:\Program Files\InSite2\Perl\bin/perl.exe
$debug = 0;
#$debug = 1;

use CookieMonster;

@driveletter=CookieMonster::runCommand("GetDriveLetter");
$cd_drive_letter=@driveletter[0];

$edocs_html=$cd_drive_letter."gedocumentation.html";
$bError=0;
open(INFILE, $edocs_html) or $bError = 1;
if( $bError == 1)
{
    showError("Error: Unable to locate documentation interface.\\nPlease insert the correct disk");
}
else
{       
    $line = <INFILE>;
    close(INFILE);
    if ( $line =~ /\<\! For GE Medical Systems Use Only >/ ){
        showeDocsInterface();
    }
    else {
        &showError("File Not Found");
    }
	
}
sub showError
{
	print "Content-type:text/html \n\n";
	print "<html><head>";
	print "<style type=\"text/css\">";
	print "body {color: #000;}";
	print "</style>";
	print "<script>function showerr(){alert(";
	print "\'@_[0]\')}</script></head><body bgcolor=\"#FFFFCC\" onLoad=showerr()>Unable to load the scanner documentation interface <br> Click on the \'Scanner Documentation\' link to retry";

        PrintDebug("<br> $edocs_html<br>  $bError <br>");

        print"</body>";
	print "</html>";
}
sub showeDocsInterface()
{
	$cd_drive_letter =~ tr/[a-z]/[A-Z]/;
	$cd_drive_letter =~ s/:[\\\/]//;
	$href = "/" . $cd_drive_letter . "Drive/gedocumentation.html";
	print "Content-type:text/html \n\n";
	print "<html><head>";
	print "<style type=\"text/css\">";
	print "body {color: #000;}";
	print "</style>";
	print "<script>function showpage(){";
	print "window.location.href=\"" . $href . "\"}</script></head><body bgcolor=\"#FFFFCC\" onLoad=showpage()></body>";
	print "</html>";
}

sub PrintDebug {
    if ($debug) {
        print "Debug:  @_<br>\n";
        #`echo @_ >> c:/temp/xxx.txt`;
    }
}
