#!D:/Program Files/InSite2/Perl/bin/perl.exe

use CookieMonster;

#read input
$buffer=$ENV{'QUERY_STRING'};
@pairs=split(/&/,$buffer);
foreach $pair (@pairs)
{
    ($name,$value) = split(/=/,$pair);
    $value=~tr/+/ /;
    $value =~ s/%(..)/pack("C",hex($1))/eg;
    $FORM{$name}=$value;
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
if ($clientHost eq "localhost")
{
	$cmd = "C:/Program Files/Distinct/Monitor";
	if(!-e $cmd)
	{
	print "This feature is not installed.";
	}
	else
	{
	print "Please use the Distinct Network Monitor interface to monitor the network.";
	@junk = CookieMonster::runCommand("start /D\"".$cmd."\" Monitor.exe");
	}
}
else
{
	print "Remote Execution of Distinct Network Monitor is not allowed";
}
print "</body>";
print "</html>";


