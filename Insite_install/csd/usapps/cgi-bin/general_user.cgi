#!D:/Program Files/InSite2/Perl/bin/perl.exe
print "Content-type:text/html\n\n";

require "csdapi-lib.pl";

use CookieMonster;
sub println
{
	print "@_\n";
}

@retvals = getProductHospitalName();

$SystemType = @retvals[0];
$Facility = @retvals[1];

@info = CookieMonster::runCommand("ipconfig");
chop(@info);

foreach $item (@info) {
    @elems = split(/:/,$item);
    if ( $item =~ m/IP Address/ ){
        $ipAddress = @elems[1];
    }
}

# See if echoloader process is running.
@proclist = CookieMonster::runCommand("tasklist");
chop(@proclist);

$AppStatus = "<font color=red>Stopped</font>";

$ProcessToCheck = getProcessToCheck();

for $m (0 .. $#proclist)
{

   if ( @proclist[$m] =~ /$ProcessToCheck/ )
   {
      $AppStatus = "<font color=green>Running</font>";
   }
}

println("<HTML>");
println("<HEAD><TITLE>GEMS Service Home Page</TITLE>");
println("</HEAD>");
println("&nbsp");
println("&nbsp");
println("&nbsp");
println("<h2><center><u>System Service Section</h2></center></u>");
println("<font size=+1 color=brown>System Information</font>");
println("<TABLE WIDTH=100% CELLPADDING=0 CELLSPACING=0 BORDER=0>\n");
println("<tr><td>System Location</td><td>$Facility</td></tr>");
println("<tr><td>System Type</td><td>$SystemType</td></tr>");
println("<tr><td>System IP Address</td><td>$ipAddress</td></tr>");
println("<tr><td>Application Status</td><td>$AppStatus</td></tr>");
println("</table>");
println("<p>Use the top level buttons to access System Service Utilities<p>");



println("</body>");
println("</html>");







