#!C:\Perl\bin\perl

##############################################################################################################################
#*
#* Copyright (c) 2005 The General Electric Company
#*
#* Author		: Jung Oh
#*
#* File			: StartComponents.pl
#*
#* Objective	: This Perl Script reads specified install option xml and set various configurations of the service platform.
#*
#* Modifications:
#*
#*   Date        Programmer         Description
#*   -----------------------------------------------------------------------------------------------------------------------
#*   08JUN2009   R Siddineni        Fix for The process cannot access the file because it is being used by another process
#*									Add Start ActDeact tool depending on it's start mode to this file to aviod process conflictin 
#*									Vista which causing Installer Failure. Remove the ActDeact Start code block from this file.
#*									Fix for WebServer  Installed on Vista OS as Autopprocess failed to start after reboot.
#*									Orginal Code: ComponentControl.exe -webserver -startprocess -nr -s
#*									Code Change: %INSITE2_HOME%\\bin\\ComponentControl.exe -webserver -startprocess -nr -s								 
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

# Configure Web Server's Start 
if ($data->{ComponentConfig}->{WebServer}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{WebServer}->{StartMode} eq "AutoService")
	{
		# register Web Server to the service manager
		`$componentcontrol -webserver -regservice -s`;
	}
	elsif ($data->{ComponentConfig}->{WebServer}->{StartMode} eq "ManualService")
	{
		# register Web Server to the service manager as a manual service
		`$componentcontrol -webserver -regserviceman -s`;
	}
	elsif ($data->{ComponentConfig}->{WebServer}->{StartMode} eq "AutoProcess")
	{
		`reg.exe add $regkey /f /v Insite2WebServer /d \"%INSITE2_HOME%\\bin\\ComponentControl.exe -webserver -startprocess -nr -s\"`;
	}
}

# Configure Questra Agent's Start Mode
if ($data->{ComponentConfig}->{QuestraAgent}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{QuestraAgent}->{StartMode} eq "ManualService")
	{
		# register Questra Agent to the service manager as a manual service
		`$componentcontrol -agent -regserviceman -s`;
	} 
	# AutoService and AutoProcess will be set during the check out (when DeviceName and SerialNumber are entered the first time) either through CSD or UpdateAgentConfig.bat
}

# Configure VNC's Start Mode
if ($data->{ComponentConfig}->{VNC}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{VNC}->{StartMode} eq "AutoService")
	{
		# register VNC to the service manager
		`$componentcontrol -vnc -regservice -s`;
	} 
	elsif ($data->{ComponentConfig}->{VNC}->{StartMode} eq "ManualService")
	{
		# register VNC to the service manager as a manual service
		`$componentcontrol -vnc -regserviceman -s`;
	} 
	elsif ($data->{ComponentConfig}->{VNC}->{StartMode} eq "AutoProcess")
	{
		`reg.exe add $regkey /f /v VNC /d \"%INSITE2_HOME%\\bin\\ComponentControl.exe -vnc -startprocess -nr -s\"`;
	}

	if ($data->{ComponentConfig}->{VNC}->{RemoveBackground} eq "1")
	{
		# register VNC to remove the desktop background 
		`regedit.exe /s VNCRemoveBackground.reg`;
	} 

	# Set VNC registry settings
	`regedit.exe /s VNC.reg`;
}

# Configure Telnet's Start Mode
if ($data->{ComponentConfig}->{Telnet}->{Install} eq "1")
{
	if ($data->{ComponentConfig}->{Telnet}->{StartMode} eq "AutoService")
	{
		# change startup type to automatic
		`$componentcontrol -telnet -regservice -s`;
	}
	elsif (($data->{ComponentConfig}->{Telnet}->{StartMode} eq "ManualService") or ($data->{ComponentConfig}->{Telnet}->{StartMode} eq "User"))
	{
		# change startup type to manual
		`$componentcontrol -telnet -regserviceman -s`;
	}
	# Set Telnet registry settings
	`regedit.exe /s Telnet.reg`;

	# Add the user account for Telnet
	$user = "GEService";
	$password = "Hel";
	# delete the existing user fisrt
	CookieMonster::runCommand("net user $user \/delete");
	`net user $user $password /add /fullname:\"Service\" /comment:\"Service Account\"`;
	`net localgroup Administrators $user /add`;
	
	# Disable NTLM authentication and enable only Password authentication
	CookieMonster::runCommand("tlntadmn config sec=-ntlm +passwd");
}

# Configure the Activate/Deactivate tool
if ($data->{ComponentConfig}->{ActDeactTool}->{Install} eq "1")
{
	print "CONFIGURING ActDeactTool\n"; 
	$insite2home = $ENV{"INSITE2_HOME"};
        $binPath = '"'.$ENV{"INSITE2_HOME"}."\\bin";
        $uninstallPath = '"'.$ENV{"INSITE2_HOME"}."\\Uninstall";
	$command = "";

	if ($data->{ComponentConfig}->{ActDeactTool}->{DesktopShortcut} eq "1")
	{
		print "Creating ActDeactTool desktop shortcut and copying related files\n"; 
		`echo Creating ActDeactTool desktop shortcut and copying related files`;
		# Run the command to create the shortcut
	        `actdeactshort.bat`;

		# Copy the files for deleting the shortcut
		#CookieMonster::runCommand("copy /Y ".$insite2home."\\install\\delactdeactshortcut.bat ".$uninstallPath);
		#CookieMonster::runCommand("copy /Y ".$insite2home."\\install\\delactdeactshort.vbs ".$uninstallPath);
	        `copy /Y delactdeactshortcut.bat "%INSITE2_HOME%\\Uninstall"`;
	        `copy /Y delactdeactshort.vbs "%INSITE2_HOME%\\Uninstall"`;
	} 
	if ($data->{ComponentConfig}->{ActDeactTool}->{StartMenuShortcut} eq "1")
	{
		print "Creating ActDeactTool startmenu shortcut and copying related files\n"; 
		`echo Creating ActDeactTool sartmenu shortcut and copying related files`;
		# Copy the files for deleting the shortcut
		#CookieMonster::runCommand("copy /Y ".$insite2home."\\install\\delactdeactstartmenu.bat ".$uninstallPath);
		#CookieMonster::runCommand("copy /Y ".$insite2home."\\install\\delactdeactstartmenu.vbs ".$uninstallPath);
	        `copy /Y delactdeactstartmenu.bat "%INSITE2_HOME%\\Uninstall"`;
	        `copy /Y delactdeactstartmenu.vbs "%INSITE2_HOME%\\Uninstall"`;

		# Run the command to create the shortcut
		#CookieMonster::runCommand("actdeactstartmenu.bat");
	        `actdeactstartmenu.bat`;

	} 
}
