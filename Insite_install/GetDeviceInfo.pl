# /usr/local/bin/perl.exe

# This Perl Script generates Device Name and CRM Number that are to be used in Questra Agent configuration and returns them respectively separately by a semicolon
# Usage:  GetDeviceInfo [AgentConfigXML]
# Author : Jung Oh 
# Date: October, 2006


# *******History *************
#******************************************************************************************** 
# SL NO    Changed By		Date		Descritpion 
#********************************************************************************************  
# 1      Ramu Siddineni    04-23-2008   Removed CRM Prefix.
#										Don't truncate CRM Number last three characters.
#******************************************************************************************** 	

use CookieMonster;

#########
# MAIN
########
$optionfile = $ARGV[0];
if ($optionfile eq "")
{
	$optionfile = "AgentConfig.xml";
}

# Get DeviceName and SerialNumber (CRM#) from the  input option xml file
unless(open(IN, $optionfile))
{
	print "Error opening " . $optionfile;
	exit 1;
}
while(<IN>)
{
	if ($_ =~ /<text\s*symbol=\"__SA_ASSET_NAME__\"/)
	{
		$devicename= $_;
		$devicename =~ s/.*>(.*)<.*/$1/;
		# trim beginning and ending spaces
		$devicename =~ s/^\s*|\s*$//g;
	} 
	if ($_ =~ /<text\s*symbol=\"__SA_ASSET_SERIAL_NUMBER__\"/)
	{
		$crm= $_;
		$crm =~ s/.*>(.*)<.*/$1/;
		# trim beginning and ending spaces
		$crm =~ s/^\s*|\s*$//g;
	} 
}
close(IN);

# if either one is UNKNOWN, auto-generate them using "GetSerialNumber" command, otherwise, just use them as is since the manually entered values override the auto-generated values.
if ($devicename =~ /^UNKNOWN$/i || $crm =~ /^UNKNOWN$/i)
{
	# try getting the serial number using "GetSerialNumber" command
	$serialnumber = "";
	$serialnumber2 = "";
	@SerialNum = CookieMonster::runCommand("GetSerialNumber");
	$serialnumber = @SerialNum[0];
	if ($serialnumber ne "")
	{
		# trim beginning and ending spaces
		$serialnumber =~ s/^\s*|\s*$//g;
		# GetSerialNumber command worked.  Try "GetSerialNumber -nomanufcode" to the the serial number without manufacturer code, if it's provided.  
		@SerialNum2 = CookieMonster::runCommand("GetSerialNumber -nomanufcode");
		$serialnumber2 = @SerialNum2[0];
		# trim beginning and ending spaces
		$serialnumber2 =~ s/^\s*|\s*$//g;
	}

	# if "GetSerialNumber" command didn't work, just set them "UNKNOWN"
	if ($serialnumber eq "" || $serialnumber=~/Failed|Error/i || $serialnumber2 eq "" || $serialnumber2=~/Failed|Error/i )
	{
		$devicename = "UNKNOWN";
		$crm = "UNKNOWN";
	}
	else
	{
		$prefix = $ENV{"Prefix"};	# if Prefix environment variable is set, use that as the prefix
		
		# generate Device Name
		if ($prefix eq "")
		{
			$devicename = $serialnumber;
		}
		else
		{
			$devicename = $prefix . "_" . $serialnumber;
			# $devicename = $serialnumber;
		}
		# generate CRM Number
		#$crm = $prefix . $serialnumber2;
		$crm = $serialnumber;
		# trim to first 15 characters
		# $crm =~ s/(.{15}).*/$1/;
	}
}
print $devicename . ";" . $crm;
