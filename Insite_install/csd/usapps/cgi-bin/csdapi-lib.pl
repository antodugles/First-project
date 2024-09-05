#!D:/Program Files/InSite2/Perl/bin/perl.exe
###########################################################################
#*
#* Copyright (c) 2005 The General Electric Company
#*
#* Author:    A Kuhn
#*
#* File:       csdapi-lib.pl
#* Objective:  Perl functions to gather product and local name info
#*
#* Modifications:
#*
#*   Date        Programmer         Description
#*   --------------------------------------------------------------------
#*   04Dec2005   A Kuhn             Initial Version
###########################################################################
use CookieMonster;
#


#
# Subroutine getProductHospitalName() returns the the name of the system's product and the
# system's installation facility in an array.  Pushes the product name on first, then the
# hospital or facility name.
#
sub getProductHospitalName
{
	my @prodhosparray = ();

	@SysType = CookieMonster::runCommand("SystemStatus -productName");
      push(@prodhosparray, @SysType[0]);
	
	@FacName = CookieMonster::runCommand("SystemStatus -hospitalName");
      push(@prodhosparray, @FacName[0]);

	return @prodhosparray;
}

#
# Subroutine getSerialNumber() returns the serial number of the system.
#
sub getSerialNumber
{
	# try getting the serial number using "GetSerialNumber" command
	$serialnumber = "";
	@SerialNum = CookieMonster::runCommand("GetSerialNumber");
	$serialnumber = @SerialNum[0];
	if ($serialnumber eq "")
	{
		# if that didn't work, try using "SystemStatus -serialNumber" command 
		@SerialNum = CookieMonster::runCommand("SystemStatus -serialNumber");
		$serialnumber = @SerialNum[0];
		if ($serialnumber ne "" && !($serialnumber=~/Failed|Error/i))
		{
			# trim beginning and ending spaces
			$serialnumber =~ s/^\s*|\s*$//g;
		}
	}
	# if still didn't work, just set it to Unknown
	if ($serialnumber eq "" || $serialnumber=~/Failed|Error/i)
	{
		$serialnumber = "Unknown";
	}
	return $serialnumber;
}

#  Subroutine getSWInstallDate() retrieves the application installation date from the
#  AppInstall file if product is
#  on the U/S global SW platform.  If the file is not present, the routine retrieves the
#  default NOT AVAILABLE string or allows for a product-specific plug-in.
#
sub getSWInstallDate
{

	my $SoftwareInstallDt = "Not Available";

	# Get software install time/date if part of the U/S global SW platform.
	# Expecting an entry like:  ************** The time now is: 15:09:28.23 on: Tue 03/30/2004 **************
	if ( -e "d:/log/AppInstall.txt" ){

    		open (APPFILE, "d:/log/AppInstall.txt");
    		@applines = <APPFILE>;
    		chop(@applines);
    		close(APPFILE);

    		my $AppInstall = "";
    		for $h (0..$#applines)
    		{
       		# Finds the last instance.
       		if (@applines[$h] =~ /The time now/)
       		{	
           			$AppInstall = @applines[$h];
       		}
    		}

    		$AppInstall =~ s/^.*The time now is: //;  # remove prefix
    		$AppInstall =~ s/\*.* *\n//;              #remove trailing *'s
    		$AppInstall =~ s/\.[0-9][0-9]//;          # remove the decimal part of time
    		$AppInstall =~ s/[ \t\n*]*$//;            # remove trailing whitespace and new line
    		$AppInstall =~ s/on: //;  
    		$AppInstall =~ s/[A-za-z][A-za-z][A-za-z]//;
    		$SoftwareInstallDt = $AppInstall;
	}

	return $SoftwareInstallDt;
}


#  Subroutine getSWVersionBuildDate() Retrieves the application version number and
#  build date from the resource files if product is
#  on the U/S global SW platform.  Else, the routine retrieves the
#  default string or allows for a product-specific plug-in.
#
sub getSWVersionBuildDate
{
      my $SwBldResFile = "";
      my $ApplSWVer = " ";
	my $SwVerResFile=$ENV{"TARGET_ROOT"} . "/resources/idunn/setup/swversion.res";


	## Attempt to retrieve the software build date from the global SW platform resources directories.
	#
	if($product eq "Radiology.Musashi")
	{
            $SwBldResFile=$ENV{"TARGET_ROOT"} . "/resources/idunn/setup/swbuild-Musashi.res";
		$SwVerResFile=$ENV{"TARGET_ROOT"} . "/resources/idunn/setup/swversion-Musashi.res";
	}
	if($product eq "Radiology.Pegasus")
	{
            #$SwBldResFile=$ENV{"TARGET_ROOT"} . "/resources/idunn/setup/swbuild-Pegasus.res";
		#$SwVerResFile=$ENV{"TARGET_ROOT"} . "/resources/idunn/setup/swversion-Pegasus.res";
	}
      if ($product eq "Radiology.Dragon")
      {
            $SwBldResFile=$ENV{"TARGET_ROOT"} . "/resources/idunn/setup/swbuild-Dragon.res";
            $SwVerResFile=$ENV{"TARGET_ROOT"} . "/resources/idunn/setup/swversion-Dragon.res";
      }

      my $ApplBuildDt = " ";
   	if (($SwBldResFile ne "") && (-e $SwBldResFile))
	{
		open(SW_BLD_FILE, $SwBldResFile);
            #SwBldLines = <SW_BLD_FILE>;
            chop(@SwBldLines);
            close(SW_BLD_FILE);

            for $k (0 .. $#SwBldLines)
            {
   			if (@SwBerLines[$j] =~ /BuildDate/ )
   			{
      			$SwBuildDateLine = @SwVerLines[$j];
   			}
		}

            ($junkheader22, $ApplBuildDt) = split(/=/,$SwBuildDateLine);
            $ApplBuildDt =~ s/ //g;
	}

	#  Extract the SW Version for this product.
	# 
	open(SW_VER_FILE, $SwVerResFile);
	@SwVerLines = <SW_VER_FILE>;
	chop(@SwVersionLines);
	close(SW_VER_FILE);

	$SwVersionLine = "";
	$SwBuildDateLine = "";
	for $j (0 .. $#SwVerLines)
	{
   		if (@SwVerLines[$j] =~ /SwVersion/ )
   		{
      		$SwVersionLine = @SwVerLines[$j];
   		}
      }

	($junkheader1, $ApplSWVer) = split(/=/,$SwVersionLine);
      $ApplSWVer =~ s/ //g;

	my @ApplValReturns = ();

	push(@ApplValReturns, $ApplSWVer);
	push(@ApplValReturns, $ApplBuildDt);

	return @ApplValReturns;
}


# Overwrite the name of the main process here with product-specific identifier.
# If the product is based on the global platform, the default is okay.
#
sub getProcessToCheck
{
	my $ptocheck = "echoloader|EchoLoader|ECHOLOADER";

	return $ptocheck;
}


# Subroutine getProbeInfo() Places a number of current connected probes,
# the index of the active probe, and
# the list of probe names in an array.

# The @probelist will contain
#     @probelist[0] = <the number of probes in list>
#     @probelist[1] = <the number or index of the active probe in list>
#     @probelist[2..] = <names of connected probes>
#
sub getProbeInfo
{
	# Places a number of current connected probes, the index of the active probe, and
	# the list of probe names in an array.

	# The @probelist will contain
	#     @probelist[0] = <the number of probes in list>
	#     @probelist[1] = <the index (0 thru N-1) of the active probe in list>
	#     @probelist[2..] = <names of connected probes>

	# SystemStatus getProbesList is used to in SW platform to return the array in the
	# correct format expected by the home page.
	my @probelist = ();

	@probelist = CookieMonster::runCommand("SystemStatus -getProbesList");
	chop(@probelist);

	return @probelist;
}


# Subroutine printDefaultTemperatureInfo prints the temperature table if a platform product
# is not recognized.
#
sub printDefaultTemperatureInfo
{
	# Here, replace the default temperature table with desired content.
	#
	print "  <TH ROWSPAN=2>Temperatures</TH><TH COLSPAN=3>Past Five Days</TH><TH COLSPAN=6>Today</TH>\n";
      print "    </TR><TR>\n";
      print "    <TH>Avg.</TH><TH>Min.</TH><TH>Max.</TH><TH>Avg.</TH><TH>Min.</TH><TH COLSPAN=4>Max.</TH>\n";
      print "    </TR><TR>\n";
      print "		<TD NOWRAP>Input Temperatures</TD><TD><FONT COLOR=GREEN>N/A</FONT></TD><TD><FONT COLOR=GREEN>N/A</FONT></TD><TD><FONT COLOR=GREEN>N/A</FONT></TD><TD><FONT COLOR=GREEN>N/A</FONT></TD><TD><FONT COLOR=GREEN>N/A</FONT></TD><TD COLSPAN=4><FONT COLOR=GREEN>N/A</FONT></TD>\n";
      print "    </TR><TR>\n";
      print "		<TD NOWRAP>Output Temperatures</TD><TD><FONT COLOR=GREEN>N/A</FONT></TD><TD><FONT COLOR=GREEN>N/A
</FONT></TD><TD><FONT COLOR=GREEN>N/A
</FONT></TD><TD><FONT COLOR=GREEN>N/A</FONT></TD><TD><FONT COLOR=GREEN>N/A
</FONT></TD><TD COLSPAN=4><FONT COLOR=GREEN>N/A
</FONT></TD>\n";
      print "		</TR><TR>\n";
      print "		<TD NOWRAP>Core Temperatures</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD COLSPAN=4>N/A</TD>\n";
      print "		</TR><TR>\n";
      print "		<TD NOWRAP>CPU Temperatures</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD COLSPAN=4>N/A</TD>\n";
      print "		</TR><TR>\n";
      print "		<TD NOWRAP>Power Supply Temperatures</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD COLSPAN=4>N/A</TD>\n";
      print "		</TR>\n";
      print "		</TABLE>\n";

	return;
}


#  Subroutine getPowerOnTime returns the power on hours of the product.
#
#
sub getPowerOnTime
{
	my @PowHours = ();
	my $POnHours = "";

	# U/S SW Platform utility that returns the run hours of the product.
      # 
	@PowHours = CookieMonster::runCommand("SystemStatus -getPowerOnTime");
      $POnHours = @PowHours[0];
      $POnHours = $POnHours/3600;
      $POnHours = sprintf"%2.3f", $POnHours;

	return $POnHours;
}


#  Subroutine getOptionStatusPairs Returns a list of SW Options / status pairs.
#
#  The pairs should have the format  "<option>;<status>", delimited by semi-colon.
#
#  If the status string contains Expired, Disabled, Permanent, Valid, or Count, the
#  status value will be displayed in a colored font.  Otherwise, black font.
#
sub getOptionStatusPairs
{
	my @optionpairs = ();

	#U/S SW Platform utility that returns the options/status pairs in proper format.
      #
	@optionpairs = CookieMonster::runCommand("SWOptionIf.exe -OptionDetails");
	chop(@optionpairs);

	return @optionpairs;
}


MAIN:
{
  1;
}
