#!D:/PERL/bin/perl.exe

#

$accessfile = $ENV{"WIP_HOME"} . "tomcat\\webapps\\modality-csd\\AccessLog.txt";

#
# get login name
#
$login = getlogin || (getpwuid($<))[0] || "nobody";

#
# open accessLog for reading
#
if ((open(MYFILE, $accessfile)) != 1) {
    die "Could not open accessfile " . $accessfile . "\n";
}

@ALFile = <MYFILE>;
$accessline = @ALFile[$#ALFile];

print("Content-type: text/html\n\n");
print("<html>");

$level = substr($accessline, 6, 1);
close(MYFILE);

if ($level eq "M")
{
   print ("<meta http-equiv=refresh content=0;url=/uscgi-bin/us_homepage.cgi>");
}
else
{
   print ("<meta http-equiv=refresh content=0;url=/uscgi-bin/general_user.cgi>");
}

print("<body></body>");
print("</html>");