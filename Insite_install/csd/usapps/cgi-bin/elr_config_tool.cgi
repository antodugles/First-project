#!c:/test/InSite2/Perl/bin/perl.exe

use CookieMonster;
use Cwd;

sub FixPath {
	my $file = @_[0];
	$file =~ s/\\/\//g;  # convert backslash to slash

    return $file;
}

print "Content-type: text/html\n\n";
print "<html>";
print "<head>";
print "<style type=\"text/css\">";
print "body {color: #000;}";
print "</style>";
print "</head>";
print "<body bgcolor=#b5b5b5>";
$clientHost = $FORM{"clienthost"};
#if ($clientHost eq "localhost")
#{
	$INSITEHOMEDIR=$ENV{'INSITE_HOME'};
	$file= $INSITEHOMEDIR."/cgi-bin/launch_elr_config_tool.js";
	#$cmd="\"".$IEDIR."\""." file:///".$file;

	#my $currentDir=getcwd();
	#$cmd="custombrowser -service \"".$currentDir."/../html/events2.html\"";
	$cmd=$file;

	if(!-f $file)
	{
		print "Failed to start Event Log Reader Utility\n";
		print "File not found ".$file;
	}
	else
	{
		print "The Event Log Reader Configuration Utility should be displayed in a separate browser\n";
		print "Please use the Event Log Reader Configuration Utility to create or modify the config file\n";

		@junk = CookieMonster::runCommand($cmd);
	}
#}
#else
#{
	#print "Remote Execution of Disk Defragmenter utility not allowed";
#}
print "</body>";
print "</html>";


