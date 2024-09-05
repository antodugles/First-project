#!D:/Program Files/InSite2/Perl/bin/perl.exe

use CookieMonster;
print "Content-type: text/html\n\n";

print "<html>";
print "<head>";
print "<style type=\"text/css\">";
print "body {color: #000;}";
print "</style>";
print "</head>";
print "<body bgcolor=#b5b5b5>";

@lineData = CookieMonster::runCommand("ipconfig /all");
chop(@lineData);

print "<b><u><h2> $lineData[1] </b></u></h2>";
print "<pre>";
for $i (2 .. $#lineData)
{
	print "$lineData[$i]";
	print "<p>";
}
print "</pre>";
print "</body></html>";

