#!C:\Perl\bin\perl

##############################################################################################################################
#*
#* Copyright (c) 2005 The General Electric Company
#*
#* Author		: Jung Oh
#*
#* File			: StartComponents.pl
#*
#* Objective	:This Perl Script reads specified install option xml and starts various components of the service platform.
#*
#* Modifications:
#*
#*   Date        Programmer         Description
#*   -----------------------------------------------------------------------------------------------------------------------
#*   28MAY2009   R Siddineni        Fix for The process cannot access the file because it is being used by another process
#*									Add Start ActDeact tool depending on it's start mode to this file to aviod process conflictin 
#*									Vista which causing Installer Failure. 							 
##############################################################################################################################

use XML::Simple;
use CookieMonster;
#use Data::Dumper;

$optionfile = $ARGV[0];
if ($optionfile eq "")
{
	$optionfile = "InstallOption.xml";
}

# create object
$xml = new XML::Simple;

# read XML file
$data = $xml->XMLin($optionfile);

#print Dumper($data);

$componentcontrol = '"'.$ENV{"INSITE2_HOME"}."\\bin\\ComponentControl.exe".'"';

# Start Web Server depending on it's start mode
$webserverstarted = 0;
if ($data->{ComponentConfig}->{WebServer}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{WebServer}->{StartMode} eq "AutoService")
	{
		`$componentcontrol -webserver -startservice -nr -s`;
		$webserverstarted = 1;
	} 
	elsif ($data->{ComponentConfig}->{WebServer}->{StartMode} eq "AutoProcess")
	{
		`$componentcontrol -webserver -startprocess -nr -s`;
		$webserverstarted = 1;
	}
}

# Start Questra Agent depending on it's start mode
# Questra Agent will start in UpdateAgentConfig.bat

# Start VNC depending on it's start mode
if ($data->{ComponentConfig}->{VNC}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{VNC}->{StartMode} eq "AutoService")
	{
		`$componentcontrol -vnc -startservice -nr -s`;
	} 
	elsif ($data->{ComponentConfig}->{VNC}->{StartMode} eq "AutoProcess")
	{
		`$componentcontrol -vnc -startprocess -nr -s`;
	}
}
	
# Start Telnet depending on it's start mode
if ($data->{ComponentConfig}->{Telnet}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{Telnet}->{StartMode} eq "AutoService")
	{
		`$componentcontrol -telnet -startservice -nr -s`;
	} 
}

# Start ActDeact tool depending on it's start mode
if ($data->{ComponentConfig}->{ActDeactTool}->{Install} eq "1")
 {
	if ($data->{ComponentConfig}->{ActDeactTool}->{AutoStart} eq "1")
	{
		# Configure it to auto start
		# print "Setting ActDeactTool to autostart and starting ActDeactTool\n"; 
	      `ActDeactTool.exe -autostart`;
		CookieMonster::runCommand("start /B ActDeactTool.exe");
	} 
 }