#!C:\Perl\bin\perl

# This Perl Script reads specified install option xml and starts various components of the service platform. 

# Author : Jung Oh Date: December, 2005

use XML::Simple;
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

$cookiemonsterstart = '"'.$ENV{"WIP_HOME"} . "\\ckm.vbs\" \"" . $ENV{"WIP_HOME"} . "\" start";

# Start Web Server depending on it's start mode
$webserverstarted = 0;
if ($data->{ComponentConfig}->{WebServer}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{WebServer}->{StartMode} eq "AutoService")
	{
            `net start Apache2`;
            `net start Tomcat5`;
		$webserverstarted = 1;
	} 
	elsif ($data->{ComponentConfig}->{WebServer}->{StartMode} eq "AutoProcess")
	{
		`$cookiemonsterstart`;
		$webserverstarted = 1;
	}
}

# Start Questra Agent depending on it's start mode
if ($data->{ComponentConfig}->{QuestraAgent}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{QuestraAgent}->{StartMode} eq "AutoService")
	{
		`net start qsa`;
	} 
}

# Start VNC depending on it's start mode
if ($data->{ComponentConfig}->{VNC}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{VNC}->{StartMode} eq "AutoService")
	{
		`net start WinVNC4`;
	} 
}
	
# Start Telnet depending on it's start mode
if ($data->{ComponentConfig}->{Telnet}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{Telnet}->{StartMode} eq "AutoService")
	{
		`net start tlntsvr`;
	} 
}