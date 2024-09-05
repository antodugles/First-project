# MergeSiteMap.pl -
# This script inserts site-specific values from a restored or old sitemap.xml
# into the schema of a newly installed sitemap.xml.  The NewSiteMap (newly
# installed SiteMap.xml) will be overwritten with the updated file.  A copy
# will be saved in the /etc/ directory.
#
# Usage:
#   perl MergeSiteMap.pl NewSiteMap OldSiteMap
#   
#   
#

use CookieMonster;

sub FiltChar{
	my $datastr = @_[0];

      $datastr =~ s/&/&amp;/g;
      $datastr =~ s/'/&apos;/g;
      $datastr =~ s/"/&quot;/g;
      $datastr =~ s/</&lt;/g;
      $datastr =~ s/>/&gt;/g;
     
	return $datastr;
}

sub CreLine{

     my $fixline = @_[0];
     my $fldvalue = @_[1];

     my $replvalue = FiltChar($fldvalue);

     $fixline =~ s/>.*</>$replvalue</;
     return $fixline;
}

#  Find the corresponding replace directive from the original (old)
#  file.
#  
sub FindReplace{
	my $retval = @_[0];
	my $searchstr = $retval;

	$searchstr =~ s/<text\s*symbol=\"//;
	$searchstr =~ s/\".*>.*>//;
	$searchstr =~ s/^\s*|\s*$//g;
	$searchstr =~ s/\./\\\./g;

	my $m = 0;
	for $m ( 0..$#ResMapLines )
	{
		if (@ResMapLines[$m] =~ /<text\s*symbol=\"$searchstr\"/)
		{
			# replace with the one in the site map file it's merging from
			$newvalue = @ResMapLines[$m];
			$newvalue =~ s/.*>(.*)<.*/$1/;
			# trim beginning and ending spaces
			$newvalue =~ s/^\s*|\s*$//g;
			$retval = CreLine($retval, $newvalue);

			# handle automatic retrieval of device name
			if ($searchstr eq "__SA_ASSET_NAME__")
			{
				# store the old DeviceName
				$oldname = @_[0];
				$oldname =~ s/.*>(.*)<.*/$1/;
				# trim beginning and ending spaces
				$oldname =~ s/^\s*|\s*$//g;
				
				# if the device name is automatically retrieved, replace with the retrieved one
				if ($devicename ne "")
				{
					$retval =~ s/>.*</>$devicename</;
				}
				else
				{
					# get the new DeviceName from the site map file it's merging from
					$devicename = $newvalue;
				}
			}

			# handle automatic retrieval of serial number
			if ($searchstr eq "__SA_ASSET_SERIAL_NUMBER__")
			{				
				# store the old SerialNumber
				$oldnumber = @_[0];
				$oldnumber =~ s/.*>(.*)<.*/$1/;
				# trim beginning and ending spaces
				$oldnumber =~ s/^\s*|\s*$//g;
				
				# if the serial number is automatically retrieved, replace with the retrieved one
				if ($serialnumber ne "")
				{
					$retval =~ s/>.*</>$serialnumber</;
				}
				else
				{
					# get the new SerialNumber from the site map file it's merging from
					$serialnumber = $newvalue;
				}
			}
			
			last;
		}
	}
	return $retval;
}


#  Find the corresponding delete directive from the original (old)
#  file.
#
sub FindDelete{
   my $retval = @_[0];
   my $searchstr = $retval;

   $searchstr =~ s/<node>//;
   $searchstr =~ s/<\/node>//;
   $searchstr =~ s/<!--node>//;
   $searchstr =~ s/<\/node-->//;
   $searchstr =~ s/^\s*|\s*$//g;
  
   my $k = 0;
   for $k ( 0..$#ResMapLines )
   {
      my $compstr = "";

      $compstr = @ResMapLines[$k];
      $compstr =~ s/<node>//;
      $compstr =~ s/<\/node>//;
      $compstr =~ s/<!--node>//;
      $compstr =~ s/<\/node-->//;
      $compstr =~ s/^\s*|\s*$//g;

      if ($compstr eq $searchstr)
      {
         $retval = @ResMapLines[$k];
      }
   }
   return $retval;
}


####################
# Main
####################


if ( $#ARGV < 1 )
{
   print "Not enough input parameters.  Need New and Old SiteMap.xml files.\n";
   print "Usage:\n";
   print "  perl MergeSiteMap.pl <NewSiteMapfile> <OldSiteMapfile>\n";
   exit 2;
}

($myInstalledMap, $myRestoredMap) = @ARGV;

$mypid = $$;
$master = 0;
$lockpath = $ENV{'INSITE2_DATA_DIR'} . "\\etc\\sitemap.xml.locked";
$newmap = $ENV{'INSITE2_DATA_DIR'} . "\\etc\\sitemap" . "$mypid" . ".xml.new";

$roll = int(rand(3)) + 1;
sleep $roll;

# Loop up to 15 seconds waiting for the locked file to disappear.  If
# the locked file continues to exist, then exit with error.
#
for $nn (0..15)
{
   if (!(-e $lockpath))
   {
      open(LOCK, ">$lockpath");

      select(LOCK);
      print "locked\n";
      close(LOCK);
      select(STDOUT);

      $master = 1;
   }

   if ($master)
   {
      last;
   }
   sleep 1;
}

if (!$master)
{
   print "locked out of sitemap.xml update.\n";
   exit 2;
}


# Read the latest install Sitemap.xml file content.
#
if (-e $myInstalledMap)
{
   $myReadMap = $myInstalledMap . ".savedinstall";
   rename($myInstalledMap, $myReadMap);

   open(READMAP, $myReadMap);
   @ReadMapLines = <READMAP>;
   chop(@ReadMapLines);
   close(READMAP);
}
else
{
   print "Can't find the Installed Sitemap file $myInstalledMap.  Exit.\n";
   exit 2;
}


# Read the saved and restored Sitemap.xml file content.
#
if (-e $myRestoredMap)
{
   open(RESMAP, $myRestoredMap);
   @ResMapLines = <RESMAP>;
   chop(@ResMapLines);
   close(RESMAP);
}
else
{
   print "Can't find the Restored Sitemap file $myRestoredMap.  Exit.\n";
   exit 2;
}

# try getting DeviceName and  SerialNumber automatically using GetDeviceInfo.pl
$getdeviceinfo = "\"\"" . $ENV{"PERL_HOME"} . "bin\\Perl\"" . " GetDeviceInfo.pl \"" . $myRestoredMap . "\"\""; 
@DeviceInfo = CookieMonster::runCommand($getdeviceinfo);
$deviceinfo = @DeviceInfo[0];
if (!($deviceinfo =~ /^Error/))
{
	$devicename = $deviceinfo;
	$devicename =~ s/(.*);.*/$1/;
	$serialnumber = $deviceinfo;
	$serialnumber =~ s/.*;(.*)/$1/;
}

#  Place results back in the installed Sitemap.xml.
#

open(OUT, ">$newmap");  
select(OUT);

# if this is not merging a backed up sitemap.xml file (in other words, if this is not called from RestoreService.bat)
$install = 0;
if ($myRestoredMap=~/.*AgentConfig\.xml/i)  
{
	# Set install flag
	$install = 1; 
}
#  If a replace directive, search in restored file for site values.
#  If a delete directive, search in restored file delete/no delete directive.
#  Otherwise, pass through untouched.
#
for $a ( 0..$#ReadMapLines )
{
    $readline = @ReadMapLines[$a];

	if ($readline =~ /symbol/)
    {
		# Unless this is called from installation, only replace user configureable properties.  We don't want to restore static properties set at install time (eg. version properties).
		if ($install == 1 || $readline =~ /userconfig=\"true\"/)
		{
			$restoreline = FindReplace($readline);
		}
		else
		{
			$restoreline = $readline;
		}
        print "$restoreline\n";
	}

    elsif ($readline =~ /node>/)
    {
        $restoreline = FindDelete($readline);
        print "$restoreline\n";
    }
    elsif ($readline =~ /\/Modific/)
    {
        print "<\/ModificationMap>\n";
    }
    else
    {
        print "$readline\n";
    }
 
} 

close(OUT);
rename($newmap, $myInstalledMap);

#
#  Finally, release control by deleting the lockfile

$delcmd = "del /Q \"$lockpath\"";
`$delcmd`;

# if this is not merging a backed up sitemap.xml file (in other words, if this is not called from RestoreService.bat)
if ($install == 1)  
{
	# if the new DeviceName is UNKNOWN, try running this script again during next reboot.   serialNo.txt file might not be ready yet or something.
	if ($devicename =~ /^UNKNOWN$/i )
	{
		$runonce = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunOnce";
		$regvalue = "UpdateAgentConfig" . time();
		# add the batch file that will update the Questra Agent configurations with the auto-generated device name and serial number to the RunOnce registry
		`reg.exe add $runonce /f /v $regvalue /d \"ComponentControl.exe -agent -updateconfig -s\"`;
		# The agent will not be restarted.
		exit 0;
	}
}

# The agent will be restarted
exit 1;