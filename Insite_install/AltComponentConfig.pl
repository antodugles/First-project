#!C:\Perl\bin\perl

# This Perl Script reads specified install option xml and set various configurations of the service platform. 

# Author : Jung Oh Date: November, 2005

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

$componentcontrol = '"'.$ENV{"INSITE2_HOME"} . "\\bin\\ComponentControl.exe".'"';
$cookiemonsterstart = '"'.$ENV{"WIP_HOME"} . "\\ckm.vbs\" \"". $ENV{"WIP_HOME"} . "\" start";
$agentcreatecommand = '"'.$ENV{"INSITE2_ROOT_DIR"} . "\\bin\\qsaMain.exe\" -service \"qsa\" -i \"Questra Service Agent\"";
$agentcreatecommand .= " -config \"" . $ENV{"INSITE2_DATA_DIR"} . "\\etc\\qsaconfig.xml\"";
$tomcat5command = '"'.$ENV{"WIP_HOME"} . "\\tomcat\\bin\\service.bat\" install";
$apache2command = '"'.$ENV{"WIP_HOME"} . "\\Apache\\bin\\Apache.exe\" -n \"Apache2\" -k install";

$vnccreatecommand = '"'.$ENV{"INSITE2_HOME"}."\\VNC\\winvnc4.exe\" -register";

# check if startloader.exe from the global ultrasound software platform is available
$startloader = system("reg.exe query HKCU\\Software\\GEVU\\StartLoader > nul 2>&1");
#print "startloader: " . $startloader;

# if startloader.exe is available, add the "AutoProcess" applications to RunStart registry key instead of Run registry key.
# it means that the system is a closed (no desktop) ultrasound machine and startloader.exe will look in the RunStart registry key and run those applications in the key.
# note that applications in Run registry key will not run unless there is a desktop (explorer.exe is running).
if ($startloader == 0)
{
	$regkey = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunStart";
}
else
{
	$regkey = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run";
}

print "Starting alternate config.\n";
# Configure Web Server's Start 
if ($data->{ComponentConfig}->{WebServer}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{WebServer}->{StartMode} eq "AutoService")
	{
		# register Web Server to the service manager
		`$tomcat5command`;
            `$apache2command`;
	}
	elsif ($data->{ComponentConfig}->{WebServer}->{StartMode} eq "ManualService")
	{
		# register Web Server to the service manager as a manual service
		`$tomcat5command`;
            `$apache2command`;
            `sc.exe config Tomcat5 start= demand`;
            `sc.exe config Apache2 start= demand`;
	}
	elsif ($data->{ComponentConfig}->{WebServer}->{StartMode} eq "AutoProcess")
	{
		`reg.exe add $regkey /f /v Insite2WebServer /d \"$cookiemonsterstart\"`;
	}
}

# Configure Questra Agent's Start Mode
if ($data->{ComponentConfig}->{QuestraAgent}->{Install} eq "1")
{	
	if ($data->{ComponentConfig}->{QuestraAgent}->{StartMode} eq "ManualService")
	{
		# register Questra Agent to the service manager as a manual service
		`$agentcreatecommand`;
            `sc.exe config qsa start= demand`;
	} 
	# AutoService and AutoProcess will be set during the check out (when DeviceName and SerialNumber are entered the first time) either through CSD or UpdateAgentConfig.bat
}

# Configure VNC's Start Mode
if ($data->{ComponentConfig}->{VNC}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{VNC}->{StartMode} eq "AutoService")
	{
		# register VNC to the service manager
		`$vnccreatecommand`;
	} 
	elsif ($data->{ComponentConfig}->{VNC}->{StartMode} eq "ManualService")
	{
		# register VNC to the service manager as a manual service
		`$vnccreatecommand`;
            `sc.exe config WinVNC4 start= demand`;
	} 

	# Set VNC registry settings
	`regedit.exe /s VNC.reg`;
}



