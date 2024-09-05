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
@share = CookieMonster::runCommand("net share");
print "<pre> @share </pre></body></html>";
