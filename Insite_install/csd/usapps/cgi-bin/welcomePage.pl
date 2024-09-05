#!D:/Program Files/InSite2/Perl/bin/perl.exe
print "Content-type:text/html\n\n";

use CookieMonster;

require "csdapi-lib.pl";

sub println
{
	print "@_\n";
}

# Get the CRM# (SerialNumber) from the agent's qsaconfig file.
$AgentCfgFile = $ENV{"INSITE2_DATA_DIR"} . "/etc/qsaconfig.xml";
$CRMNo = "";

# Check if the expected agent file exists.  If so, parse for the SerialNumber attribute.
#
if (-e $AgentCfgFile)
{
    open(AGENTFILE, $AgentCfgFile);
    @AgentFileLines = <AGENTFILE>;
    chop(@AgentFileLines);
    close(AGENTFILE);

    # Search for Member name in the qsaconfig xml.
    for $a ( 0..$#AgentFileLines )
    {
        if (@AgentFileLines[$a] =~ /SerialNumber/)
        {
            $CRMNo = @AgentFileLines[$a]; 
        }	
    }

    # Strip off the xml container
    $CRMNo =~ s/<SerialNumber>//;
    $CRMNo =~ s/<\/SerialNumber>//;
    $CRMNo =~ s/ //g;
}

# No SerialNumber found, default to unknown
#
if (($CRMNo eq "") || ($CRMNo =~ /^unknown$/i)) {
		$CRMNo = "Unknown";
}

@NameRetVals = getProductHospitalName();

$SystemType = @NameRetVals[0];
$HospitalName = @NameRetVals[1];

println("<HTML>");
println("<HEAD><TITLE>GEMS Service Home Page</TITLE>");
println("<style type=\"text/css\">");
println("body {color: #000;}");
println("</style>");
println("</HEAD>");
println("&nbsp");
println("&nbsp");
println("&nbsp");
println("<body background=\"/usimages/content_brnd.gif\">");
println("<div align=center><center>");
println("<table border=5 cellpadding=10 cellspacing=0");
println("background=\"/usimages/ctrl_bkrd.gif\"><tr>");
println("<td background=\"/usimages/ctrl_bkrd.gif\">");

println("<p align=center><big><font face=Arial><strong><u>Service Login</u></strong></font></big></p>");
println("<div align=center> <center><table border=0 cellpadding=3 cellspacing=0>");
println("<tr><td><strong>Hospital Name: </strong></td>");
println("<td>$HospitalName </td>");
println("</tr><tr>");
println("<td><strong>System Type:</strong></td><td>$SystemType</td></tr>");
println("<tr><td><strong>CRM Number: </strong></td><td>$CRMNo</td></tr>");
println("</table></center></div>");
println("&nbsp");
println("&nbsp");
println("&nbsp");
println("&nbsp");
println("<CENTER>");



println("<FORM METHOD=\"POST\" ACTION=\"/modality-csd/servlets/MainServlet\"><Table border=\"1\">");
println("<input type=\"hidden\" name=HANDLE value=com.ge.med.uls.UserAuth.HandleUserRequest><input type=\"hidden\" name=whatToDo value=Authenticate>");
println("<tr><th align=\"left\">Select User Level <th align=\"left\"><select size=\"1\" name=\"username\">");
println("<option VALUE = \"0\">Select User Level");
println("<option VALUE = \"1\">Operator");
println("<option VALUE = \"2\">Administrator");
println("<option VALUE = \"3\">External Service");
println("<option VALUE = \"4\">GE Service");
println("</select></tr><tr>");
println("<th align=\"left\">Enter Password &nbsp;&nbsp;&nbsp; <th align=\"left\"><INPUT TYPE=\"PASSWORD\" NAME=\"password\" SIZE=14\"></tr><tr>");
println("<th>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<INPUT TYPE=\"SUBMIT\" VALUE=\"Okay\"> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
println("<th><INPUT TYPE=\"RESET\" VALUE=\"Clear\"></tr><tr>");
println("</table>");
println("</FORM>");
println("</CENTER>");
println("</TABLE>");


println("</body>");
println("</html>");







