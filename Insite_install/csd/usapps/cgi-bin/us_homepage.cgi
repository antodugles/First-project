#!D:/Program Files/InSite2/Perl/bin/perl.exe
###########################################################################

#*
#* Copyright (c) 2000 The General Electric Company
#*
#* Author:    
#*
#* File:       us_homepage.cgi
#* Objective:  Perl program for viewing service desktop homepage
#*
#* Modifications:
#*
#*   Date        Programmer         Description
#*   --------------------------------------------------------------------
#*   
###########################################################################

require "us_homepage-lib.pl";

use CookieMonster;

#####
#
# Subroutine to read CGI input
#
#####
sub readInput
{
    local ($buffer, @pairs, $pair, $name, $value, %FORM);
    # Read in text
    $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;
    if ($ENV{'REQUEST_METHOD'} eq "POST")
    {
        read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    } else
    {
        $buffer = $ENV{'QUERY_STRING'};
    }
    # Split information into name/value pairs
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs)
    {
        ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%(..)/pack("C", hex($1))/eg;
        $FORM{$name} = $value;
    }
    %FORM;
}


#####
#
# Subroutine to print html header
#
#####
sub printHeader
{
print "Content-type: text/html\n";
print "\n";
print "<HTML>\n";
print "<HEAD>\n";
print "<TITLE>\n";
print "$CONSOLE_HOSTNAME Service Home Page\n";
print "</TITLE>\n";
print '<STYLE TYPE="text/css">';
print "\n";
print "<\!--\n";
print '	BODY	{text-align:center; color: #000;}';
print "\n";
print '	TH	{font-size:10pt; color:white; background-color:#008080;}';
print "\n";
print '	TD	{font-size:8pt;}';
print "\n";
print '	.data	{color:black; background-color:#B5B5B5;}';
print "\n";
print "-->\n";
print "</STYLE>\n";
print "<SCRIPT TYPE=\"text/javascript\" LANGUAGE=\"JavaScript\">\n";
print "<!--//hide script from old browsers-->\n";
print "  function updatepage(frequency)\n";
print "     {\n";
print "     if (document.forms.Refresh.AUTO.checked)\n";
print "       {\n";
print "       index = document.Refresh.FREQUENCY.selectedIndex\;\n";
print "       updateTime = document.Refresh.FREQUENCY.options[index].value\;\n";
print "       newLocation = \"/uscgi-bin/us_homepage.cgi\?health=$showHealth\&info=$showInfo\&status=$showStatus\&debug=$debug\&refresh=\" + updateTime\;\n";
print "      }\n";
print "     else\n";
print "       {\n";
print "       newLocation = \"/uscgi-bin/us_homepage.cgi\?health=$showHealth\&info=$showInfo\&status=$showStatus\&debug=$debug\"\;\n";
print "       }\n";
print "     window.location.href=newLocation\;\n";
# Next line causes page to always reload.  May be needed if browser uses cache.
#print "     window.location.reload(1)\;\n";
print "     }\n";
print "<!--//end hiding contents -->\n";
print "</SCRIPT>";
print "</HEAD>\n\n";
return;
}


#####
#
# Subroutine to print html body opening
#
#####
sub printBodyOpen
{
print "<BODY BGCOLOR=#B5B5B5 BACKGROUND=\"C:/insite/server/images/Speckle.gif\" TOPMARGIN=0 LEFTMARGIN=0 BOTTOMMARGIN=0 RIGHTMARGIN=0 ";
if ($refresh)
	{
	print "onLoad=\"timerID=setTimeout(\'updatepage()\',$refresh)\;\""; 
	}
print ">\n";
print "<CENTER>\n";
print "<TABLE WIDTH=100% CELLPADDING=0 CELLSPACING=0 BORDER=0>\n";
print "<TR><TD COLSPAN=2 HEIGHT=5 ALIGN=CENTER VALIGN=TOP>";
if ($debug)
	{
	print "<CENTER><PRE>";
	print "----------------------------------------------------------------\n";
	print " Debugging... Data was gathered on ";
	print `date`;
	print "----------------------------------------------------------------\n";
	print "health = $showHealth, status = $showStatus, info = $showInfo, debug = $debug";
	print "</PRE></CENTER>";
	}
print "</TD></TR>\n";
print "<TR><TD WIDTH=50% ALIGN=CENTER VALIGN=TOP>\n";
print "  <CENTER>\n\n";
return;
}


#####
#
# Subroutine to print update buttons
#
#####
sub printUpdateButtons
{
print "    <TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0>\n";
print "    <FORM NAME=\"Refresh\">\n";
print "    <TR>";
#if ($remote)
#	{
#	print "<TD WIDTH=105 HEIGHT=45 ALIGN=CENTER VALIGN=CENTER ID=\"WEB_APP_BTN\">";
#	print "<A HREF=/service/body.html TARGET=\"_blank\">";
#	print "<CENTER><B>Web<BR>Applications</B></CENTER>";
#	print "</A>";
#	print "</TD>\n";
#	}
#print "        <TD WIDTH=15></TD>\n";
print "        <TD ALIGN=CENTER VALIGN=BOTTOM><B>Auto Update</B><INPUT TYPE=CHECKBOX NAME=AUTO ";
if ($refresh)
	{print "CHECKED";}
print " onClick=\"if(!this.checked) {clearTimeout(timerID);} else {updatepage()\;}\"><BR>\n";
print "          <B>Frequency (sec)</B><SELECT NAME=\"FREQUENCY\">\n";
print "          <OPTION ";
if (($refresh eq "10000")||($refresh eq ""))
	{print "SELECTED ";}
print "VALUE=\"10000\">10</OPTION>\n";
print "          <OPTION ";
if ($refresh eq "15000")
	{print "SELECTED ";}
print "VALUE=\"15000\">15</OPTION>\n";
print "          <OPTION ";
if ($refresh eq "20000")
	{print "SELECTED ";}
print "VALUE=\"20000\">20</OPTION>\n";
print "          <OPTION ";
if ($refresh eq "25000")
	{print "SELECTED ";}
print "VALUE=\"25000\">25</OPTION>\n";
print "          <OPTION ";
if ($refresh eq "30000")
	{print "SELECTED ";}
print "VALUE=\"30000\">30</OPTION>\n";
print "          </SELECT></TD>\n";
print "        <TD WIDTH=15></TD>\n";
print "        <TD WIDTH=120 HEIGHT=45 ALIGN=CENTER VALIGN=CENTER ID=\"UPDATE_BTN\">";
print "<CENTER><A HREF=\"javascript:updatepage()\">";
print "<B>Update</B>";
print "</A></CENTER>";
print "</TD></TR>\n";
print "    </FORM>\n";
print "    </TABLE>\n";
return;
}


#####
#
# Subroutine to print html body closing
#
#####
sub printBodyClose
{
print "  </CENTER>\n";
print "</TD></TR>\n";
print "</TABLE>\n";
print "</CENTER>\n";
print "</BODY>\n\n";
return;
}


#####
#
# Subroutine to print html footer
#
#####
sub printFooter
{
print "</HTML>\n";
return;
}

sub println
{
	print "@_\n";
}

#####
#
#	MAIN METHOD
#
#####
MAIN:
{

@CONHOST = CookieMonster::runCommand("hostname");
$CONSOLE_HOSTNAME = @CONHOST[0];

%VAR = &readInput();
($VAR{"health"} == undef) ? $showHealth = 1 : $showHealth = $VAR{"health"};
($VAR{"info"} == undef) ? $showInfo = 1: $showInfo = $VAR{"info"};
($VAR{"status"} == undef) ? $showStatus = 1 : $showStatus = $VAR{"status"};
$refresh = $VAR{"refresh"};
#  debug should be an integer representing a three-bit binary number, ABC,
#  indicating which section(s) to debug.  (A = health, B = info, C = status)
#  (Valid values for debug are 0 through 7.)
#$debug = $VAR{"debug"};
#if (($debug > 7) || ($debug < 0))
#	{$debug = 0;}

printHeader();
&printBodyOpen;
print "  <TABLE WIDTH=100% CELLPADDING=0 CELLSPACING=0 BORDER=0>\n";
print "  <TR><TD WIDTH=100% ALIGN=CENTER VALIGN=TOP>\n";
print "	 <CENTER>\n";
&printInfo;
print "	 </CENTER>\n";
print " </TD></TR>\n";
print " <TR><TD WIDTH=100% HEIGHT=5></TD></TR>\n";
print " <TR><TD WIDTH=50% ALIGN=CENTER VALIGN=TOP >\n";
print " <CENTER>\n";
&printStatus;
print " </CENTER>\n";
print " </TD></TR>\n";
print " </TR>\n";
print " </TABLE>\n";
print " </CENTER>\n";
print " </TD>\n";
print " <TD WIDTH=50% ALIGN=CENTER VALIGN=TOP>\n";
print " <CENTER>\n";
print " <TABLE WIDTH=100% HEIGHT=100% CELLPADDING=0 CELLSPACING=0 BORDER=0>\n";
print " <TR><TD WIDTH=100% ALIGN=CENTER VALIGN=TOP >\n";
print " <CENTER>\n";
&printHealth;
print " </CENTER>\n";
print " </TD></TR>\n\n";
print " <TR><TD WIDTH=100% HEIGHT=5></TD></TR>\n";
print " <TR><TD WIDTH=50% ALIGN=CENTER VALIGN=TOP >\n";
print " <CENTER>\n";
#&printProDiag;
print " </CENTER>\n";
print " </TD></TR>\n\n";
print " <TR><TD WIDTH=100% ALIGN=CENTER VALIGN=BOTTOM>\n";
print " <CENTER>\n";
&printUpdateButtons;
print " </CENTER>\n";
print " </TD></TR>\n";
print " </TABLE>\n\n";
&printBodyClose;
&printFooter;
exit

#print "Content-type: text/html\n\n";
#print "<html>";
#&printStatus;
#$temp=rand(7);
#print "$temp";
#print "</html>";
#exit
}
