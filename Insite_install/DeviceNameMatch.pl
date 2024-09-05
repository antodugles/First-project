# /usr/local/bin/perl.exe

# This Perl Script compares the existing DeviceName or auto-generated DeviceName (using GetDeviceInfo.pl which uses "GetSerialNumber" command)
# to the one in the Questra Agent configuration in the restore source directory and returns 0 if they match and returns 1 if they don't
# This script is provided to prevent restoring service configurations backedup from a different machine.
# Usage:  DeviceNameMatch [RestoreSourceDir]
# Example: DeviceNameMatch "D:\export\GEMS_BACKUP\LOGIQ9\Service"
# Author : Jung Oh 
# Date: October, 2006

use CookieMonster;
#use Data::Dumper;

# Get the the existing DeviceName or auto-generated DeviceName using GetDeviceInfo.pl
$getdeviceinfo = "\"\"" . $ENV{"PERL_HOME"} . "bin\\Perl\"" . " GetDeviceInfo.pl \"" . $ENV{"INSITE2_DATA_DIR"} . "\\etc\\sitemap.xml\"\"";
@DeviceInfo = CookieMonster::runCommand($getdeviceinfo);
$deviceinfo = @DeviceInfo[0];
if (!($deviceinfo =~ /^Error/))
{
	$devicename = $deviceinfo;
	$devicename =~ s/(.*);.*/$1/;
}

if ($devicename eq "")
{
	exit 1;
}

$sitemap = $ARGV[0] . "\\sitemap.xml";

# Get DeviceName from the Questra Agent configuration in the restore source directory.
unless (open(IN,"$sitemap"))
{
	exit 1;
}

while(<IN>)
{
	if ($_ =~ /<text\s*symbol=\"__SA_ASSET_NAME__\"/)
	{
			$restoredevicename= $_;
			$restoredevicename =~ s/.*>(.*)<.*/$1/;
			# trim beginning and ending spaces
			$restoredevicename =~ s/^\s*|\s*$//g;
	} 
}
#print $devicename . " " . $restoredevicename;
if ($devicename ne $restoredevicename)
{
	exit 1;
}
exit 0;