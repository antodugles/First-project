#!C:\InSite2\Perl\bin/perl.exe
##############################################################
#*
#* Copyright (c) 2005 The General Electric Company
#*
#* Author		: 
#*
#* File			: StartDiskDefragmenter.cgi
#*
#* Objective	:This CGI/Perl Script to launch Disk Defragmenter utility depends on the OS
#*
#* Modifications:
#*
#*   Date        Programmer         Description
#*   ------------------------------------------------------------------
#*   06JUN2009   R Siddineni    Added DiskDefrag support for Vista	
#######################################################################
use CookieMonster;

sub FixPath {
	my $file = @_[0];
	$file =~ s/\\/\//g;  # convert backslash to slash
    return $file;
}

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
 
$WINDIR=FixPath($ENV{'SYSTEMROOT'});

if ( -e "$WINDIR\\system32\\dfrgui.exe")
  {$cmd = $WINDIR."/system32/dfrgui.exe";}
  
if ( -e "$WINDIR\\system32\\dfrg.msc")
  {$cmd = $WINDIR."/system32/dfrg.msc";}

	if(!-f $cmd)
	{
	print "Failed to start Disk Defragmentation Utility";
	}
	else
	{
	print "Please use the disk defragmentation interface to defragment the disks.";
	print "<p><b>Warning: Defragmentation is a huge process requiring lot of system resources. The system performance could be significantly reduced when the disk is being defragmented.</b>";
	@junk = CookieMonster::runCommand("start ".$cmd);
	}
}
else
{
	print "Remote Execution of Disk Defragmenter utility not allowed";
}
print "</body>";
print "</html>";


