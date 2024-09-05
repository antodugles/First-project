#!D:\InSite2\Perl\bin/perl.exe
###########################################################################
#*
#* Copyright (c) 2000 The General Electric Company
#*
#* Author:    Aaron Schmidt
#*
#* File:       homepage-lib.pl
#* Objective:  Perl functions to gather, debug, and print system info
#*
#* Modifications:
#*
#*   Date        Programmer         Description
#*   --------------------------------------------------------------------
#*   22Jun2000   Aaron J. Schmidt   Creation date
#*   06Jun2009   R.Siddineni        IP Address support added to display both IP4 and IP6
#*									Hide IP6 address row if no data			
#*   18 Jun2009  Sindhu Gangisetty  IP Address support added to display both IP4 and IP6     
###########################################################################
use Time::Local;
use CookieMonster;

require "csdapi-lib.pl";

#####
#
# Subroutine to gather SYSTEM INFORMATION
#
#####
sub getInfo
{

	# Acquire the product and hospital from the api implementation.
	#
	@NameRetVals = getProductHospitalName();
	$Facility = @NameRetVals[1];
	$SystemType = @NameRetVals[0];
	
	# Acquire the serial number of the system from the api implementation.
	#
	$SerialNumber = getSerialNumber();

	# Get the DeviceName and CRM# (SerialNumber) from the agent's qsaconfig file.
	$AgentCfgFile = $ENV{"INSITE2_DATA_DIR"} . "/etc/qsaconfig.xml";
	$DeviceID = "";
	$CRMNo = "";

	# Check if the expected agent file exists.  If so, parse for the Membername and SerialNumber attributes.
	#
	if (-e $AgentCfgFile)
	{
		open(AGENTFILE, $AgentCfgFile);
		@AgentFileLines = <AGENTFILE>;
		chop(@AgentFileLines);
		close(AGENTFILE);

		# Search for Member name in the qsaconfig xml.
		for $a ( 0..$#AgentFileLines )
		{
			if (@AgentFileLines[$a] =~ /MemberName/)
			{
				$DeviceID = @AgentFileLines[$a];
			}
			if (@AgentFileLines[$a] =~ /SerialNumber/)
       		{
				$CRMNo = @AgentFileLines[$a]; 
			}	
		}

		# Strip off the xml container
		$DeviceID =~ s/<MemberName>//;
		$DeviceID =~ s/<\/MemberName>//;
		$DeviceID =~ s/ //g;
		$CRMNo =~ s/<SerialNumber>//;
		$CRMNo =~ s/<\/SerialNumber>//;
		$CRMNo =~ s/ //g;
	}

	# No Device name found, default to unknown
	#
	if (($DeviceID eq "") || ($DeviceID =~ /default/i) || ($DeviceID =~ /unknown/i)) {
		$DeviceID = "Unknown";
	}
	
	# No SerialNumber found, default to unknown
	#
	if (($CRMNo eq "") || ($CRMNo =~ /^unknown$/i)) {
		$CRMNo = "Unknown";
	}

	@info = CookieMonster::runCommand("ipconfig");
	chop(@info);

	foreach $item (@info) {
    		
	    @elems = split(/:/,$item, 2);      # Added by Sindhu 
	    if ( $item =~ m/IP Address/ ) { 
                  $IPAddress .= @elems[1];
    		}

		if ( $item =~ m/IPv4 Address/ ) {
           	      $IPAddress .= @elems[1];
    		}
		
		if ( $item =~ m/IPv6 Address/ ) {
        		$IP6Address .= @elems[1];
    		}
    		
   		if ( $item =~ m/Subnet Mask/ ) {
        		$Netmask .= @elems[1];
   		}
    		if ( $item =~ m/Default Gateway/ ) {
                 $Gateway .= @elems[1];
    		}
	}

	$SoftwareInstallDate = getSWInstallDate();

	$accessLog=$ENV{"WIP_HOME"} . "/tomcat/webapps/modality-csd/accessLog.txt";

	open(MYALFILE, $accessLog);
	@allines = <MYALFILE>;
	chop(@allines);
	close(MYALFILE);

	$ALtext=@allines[$#allines];

	@LastEntry=split(/;/,$ALtext);	
	$AccessLevel=$LastEntry[0];
	$AccessExpiration=$LastEntry[1];

	return;
}

#####
#
# Subroutine to gather CURRENT SYSTEM STATUS
#
#####
sub getStatus
{
	$lt = localtime();
	@dt = split(/\s+/, "$lt");
	$product=$ENV{"PRODUCT"};
	$SystemDate = "$dt[0], $dt[1] $dt[2] $dt[4]";
	$SystemTime = "$dt[3] ";

	# get Application SW version and build date from API impl.
	@myApplRetVals = getSWVersionBuildDate();
	$ApplicationSoftware = @myApplRetVals[0];
	$ApplicationBuild = @myApplRetVals[1];

	$ProcessToCheck = getProcessToCheck();

	# See if product's main process (ProcessToCheck) is running.

	@proclist = CookieMonster::runCommand("tasklist");
	chop(@proclist);

	$ApplicationSoftwareStatus = "<font color=red>Stopped</font>";
	for $m (0 .. $#proclist)
	{

   		if ( @proclist[$m] =~ /$ProcessToCheck/ )
   		{
      		$ApplicationSoftwareStatus = "<font color=green>Running</font>";
   		}
	}

	$NextPatientExamInfo="69";
	$ArchiveStatus="N/A";
	$NetworkStatus="N/A";
	$FilmingStatus="N/A";

	return;
}



#####
#
# DEBUG INFO
#
#####
sub debugInfo
{
&getInfo;
print "\n";
print "<CENTER><PRE>";
print "*****  SYSTEM INFORMATION  *****";
print "</PRE></CENTER>\n<PRE>";
print " Facility:                   $Facility\n";
print " Suite Name:                 $SuiteName\n";
print " System Type:                $SystemType\n";
print " Serial Number:              $SerialNumber\n";
print " InSite ExC Device Name:     $DeviceID\n";
print " CRM Number:                 $CRMNo\n";
print " IP Address:                 $IPAddress\n";
print " IP Interface:               $IPInterface\n";
print " Access Level:               $AccessLevel\n";
print " Access Status:              $AccessStatus\n";
print " Access Key Expiration Date: $AccessExpiration\n";
print " Software Installation Date: $SoftwareInstallDate\n";
print " Installed Camera:           $InstalledCamera\n";
print " Camera Interface:           $CameraInterface\n";
print " Installed Tube:             $InstalledTube\n";
print " Tube Install Date:          $TubeInstallDate\n";
print " Current mAs:                $CurrentmAs\n";
print " Data Acquisition System:    $DataAcquisitionSystem\n";
print " Power Distribution Unit:    $PowerDistributionUnit";
print "</PRE>\n\n";
return;
}


#####
#
# DEBUG STATUS
#
#####
sub debugStatus
{
&getStatus;
print "\n";
print "<CENTER><PRE>";
print "*****  CURRENT SYSTEM STATUS  *****";
print "</PRE></CENTER>\n<PRE>";
print " System Date:                $SystemDate\n";
print " System Time:                $SystemTime\n";
print " OC Application Software:    $OCApplicationSoftware\n";
print " OC CUP Status:              $OC_CUPSTATUS\n";
print " SRU Application Software:   $SRUApplicationSoftware\n";
print " SRU CUP Status:             $SRU_CUPSTATUS\n";
print " Next Patient Exam:          $NextPatientExam\n";
print " Archive Information:        $ArchiveInfo\n";
print " Archive Status:             $ArchiveStatus\n";
print " Network Information:        $NetworkInfo\n";
print " Network Status:             $NetworkStatus\n";
print " Filming Information:        $FilmingInfo\n";
print " Filming Status:             $FilmingStatus";
print "</PRE>\n\n";
return;
}


#####
#
# Subroutine to PRINT SYSTEM HEALTH INFORMATION
#
#####
sub printHealth
{
$PowerOnHours = getPowerOnTime();

print "    <TABLE CLASS=\"data\" border=1 cellpadding=0 cellspacing=0 WIDTH=98%>\n";
print "    <TR>\n";
print "    <TH COLSPAN=10 ALIGN=CENTER>System Health Information</TH>\n";
print "    </TR><TR>\n";
print "    <TH>Item</TH><TH COLSPAN=9>Information</TH>\n";
print "    </TR><TR>\n";
if($PowerOnHours ne "0.000")
{
print "    <TD NOWRAP>Power On Hours </TD><TD COLSPAN=9>$PowerOnHours  Hours</TD>\n";
}
else
{
print "    <TD NOWRAP>Power On Hours</TD><TD COLSPAN=9>Not Available</TD>\n";
}
print "    </TR><TR>\n";

## Not implemented for Ultrasound


# Temperature monitoring is different for each product. Use the PRODUCT  env var to 
# determine temperature for specific product


##print "    <TD NOWRAP>Date of Last PM</TD><TD COLSPAN=3>N/A</TD><TD COLSPAN=3>N/A</TD>\n";
##print "    </TR><TR>\n";
##print "    <TD NOWRAP>Date of Next PM</TD><TD COLSPAN=3>N/A</TD><TD COLSPAN=3>N/A</TD>\n";
##print "    </TR><TR>\n\n";
&getTemperature;
return;
}
# Obtain ProDiag information

sub getProDiagInfo
{
	$INSITE_HOME=$ENV{"INSITE_HOME"};
	$PRODIAGS_PATH="$INSITE_HOME/ProDiags/SendLogsToASC";
	$Sched_path="$INSITE_HOME/ProDiags/schedule/bg_schedule_data";
	@proinfo=("init");
	$proinfo[1]="SendLogsToASC";
	$ResultsFile="$PRODIAGS_PATH/results/results.log";
	if(!-f $ResultsFile)
	{ 
	   $proinfo[2]="Not Executed";
	}
	else
      {
	   $rescmd = "dir " . $ResultsFile;

	   # make it DOS friendly.
         $rescmd =~ s/\//\\/g;
         @reslines = CookieMonster::runCommand($rescmd);
         chop(@reslines);
 
	   $fileline = "";
         for $a (0..$#reslines)
         {
            if (@reslines[$a] =~ /results/)
            {
               $fileline = @reslines[$a];
            }
         }
         
         $proinfo[2] = substr($fileline,12,9);
	}

      $sched = "";

	open(SCHEDFILE, $Sched_path);
      @schedlines = <SCHEDFILE>;
      chop(@schedlines);
      close(SCHEDFILE);

	$sched = "";
      for $d (0..$#schedlines)
      {
         if (@schedlines[$k] =~ /SendLogsToASC/)
         {
	      $sched = @schedlines[a];
         }
      }
      
	if($sched eq "")
	{
		$proinfo[3]="NOT SCHEDULED";
	}
	else
	{
		$proinfo[3]="Scheduled as Background Process";
	}
	return;
		
}

# Subroutine to PRINT PRODIAG INFORMATION
sub printProDiag
{
&getProDiagInfo;
print "	<TABLE CLASS=\"data\" border=1 cellpadding=0 cellspacing=0 WIDTH=98%>\n";
print " <TH COLSPAN=3>ProDiag Information</TH>\n";
print " </TR><TR>\n";
print " <TH>Task Name</TH><TH>Last Executed</TH><TH>Status</TH>\n";
print " </TR><TR>\n";
print " <TD NOWRAP>$proinfo[1]</TD><TD>$proinfo[2]</TD><TD>$proinfo[3]</TD>\n";
print " </TABLE>\n";
return;
}

#####
#
# Subroutine to PRINT SYSTEM INFORMATION
#
#####
sub printInfo
{
    &getInfo;
    print "    <TABLE CLASS=\"data\" border=1 cellpadding=0 cellspacing=0 WIDTH=98%>\n";
    print "    <TR>\n";
    print "    <TH COLSPAN=3>System Information</TH>\n";
    print "    </TR><TR>\n";
    print "    <TH>Item</TH><TH>Information</TH><TH>Status</TH>\n";
    print "    </TR><TR>\n";
    print "    <TD NOWRAP>Facility</TD><TD>$Facility</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    print "    <TD NOWRAP>System Type</TD><TD>$SystemType</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    print "    <TD NOWRAP>Serial Number</TD><TD>$SerialNumber</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    print "    <TD NOWRAP>InSite ExC Device Name</TD><TD>$DeviceID</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    print "    <TD NOWRAP>CRM Number</TD><TD>$CRMNo</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    print "    <TD>IP Address (IP4)</TD><TD>$IPAddress</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    
    if($IP6Address ne ""){
    print "    <TD NOWRAP>IP Address (IP6)</TD><TD>$IP6Address</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    } 
    
    print "    <TD NOWRAP>Netmask</TD><TD>$Netmask</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    print "    <TD NOWRAP>Gateway</TD><TD>$Gateway</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    print "    <TD NOWRAP>Hostname</TD><TD>$CONSOLE_HOSTNAME</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    print "    <TD NOWRAP>Access Level</TD><TD>$AccessLevel</TD><TD>Login Since: $AccessExpiration";
    print "</TD>\n";
    print "    </TR><TR>\n";

	&getServConnectivity();

    #
    #
    $SvcPformVer = "";
    $FilePformVer = $ENV{"WIP_HOME"} . "/tomcat/webapps/modality-csd/usapps/resources/SVCPFORMVERSION";
    if (-e $FilePformVer)
    {
       open(MYFILE_PFORMVER, $FilePformVer);

       @pfverlines=<MYFILE_PFORMVER>;
       chop(@pfverlines);
       close(MYFILE_PFORMVER);

       ($svcpformlabel, $SvcPformVer) = split(/:/,@pfverlines[0]);
       $SvcPformVer =~ s/ //g;
    }

    #  Get the apache version
    #
    $webvercmd = "\"" . $ENV{"WIP_HOME"} . "/Apache/bin/Apache.exe\" -v";
    # make it DOS friendly.
    $webvercmd =~ s/\\/\//g;

    @webverlines = CookieMonster::runCommand($webvercmd);;
    chop(@webverlines);

    $apachever = "";
    $tomcatver = "";
    $jvmver = "";
    for $x (0..$#webverlines)
    {
       if (@webverlines[$x] =~ /Server version/)
       {
          ($aplabel,$apachever) = split(/\//, @webverlines[$x]);
       }
    }

    #  Now get the tomcat version
    #
    $tomvercmd = "\"" . $ENV{"WIP_HOME"} . "/tomcat/bin/version\"";
    # make it DOS friendly.
    $tomvercmd =~ s/\\/\//g;

    @tomverlines = CookieMonster::runCommand($tomvercmd);
    chop(@tomverlines);

    for $y (0..$#tomverlines)
    {
       if (@tomverlines[$y] =~ /Server version/)
       {
           ($tomlabel, $tomcatver) = split(/\//, @tomverlines[$y]);
       }
       elsif (@tomverlines[$y] =~ /JVM Version/)
       {
           ($jvmlabel, $jvmver) = split(/:/, @tomverlines[$y]);
           $jvmver =~ s/ //g;
       }
    }

    # Finally, get the PERL and CKM version
    #
    $CKMverfile = $ENV{WIP_HOME} . "/VERSION";
    $CKMver = "";
    if (-e $CKMverfile)
    {
       open(CKMVERSION, $CKMverfile);
       @CKMlines = <CKMVERSION>;
       chop(@CKMlines);
       $CKMver = @CKMlines[0];

       $CKMver =~ s/ //g;
    }

    print "    </TR><TR>\n";
    print "   <td>Version: Apache/Tomcat</td><td>$apachever / $tomcatver</td><td>-</td>";
    print "    </TR><TR>\n";
    print "   <td>Version: Java VM</td><td>$jvmver</td><td>-</td>";
    print "    </TR/<TR>\n";
    print "   <td>Version: CSD/CKM</td><td>$CKMver</td><td>-</td>";
    print "    </TR/<TR>\n";
    print "   <td>Version: SvcPform</td><td>$SvcPformVer</td><td>-</td>";
    print "    </TR><TR>\n";
    print "    <TD NOWRAP>Software Installation Date</TD><TD>$SoftwareInstallDate</TD><TD>-</TD>\n";
    print "    </TR><TR>\n";
    my $SvcHistFile="logfile-SvcHistory.xml";
    if (-e "d:/log/$SvcHistFile") {
        print "    <TD NOWRAP>Server History</TD><TD><a href=\"/log/$SvcHistFile\">Details</a></TD><TD>-</TD>\n";
    } else {
        print "    <TD NOWRAP>Server History</TD><TD>No History available</TD><TD>-</TD>\n";
    }
#    print "    <TD NOWRAP>Peripherals Installation Date</TD><TD>07/19/2000</TD><TD>-</TD>\n";
#    print "    </TR><TR>\n";
    print "    </TR>\n\n";

    &printProbeInfo;
}

sub printProbeInfo
{

    # Acquire the formatted probe list from the api implementation.
    #
    @ProbeInfoList = getProbeInfo();


    $offset=0;

    if ($#ProbeInfoList < 0)
    {
       $NumSockets = 1;
       $ActiveSocket = -1;
    }
    else
    {
       $NumSockets = $ProbeInfoList[$offset++];
       $ActiveSocket = $ProbeInfoList[$offset++];
    }
    print "     <!--//probes Installed -->\n";
    print "     <TR><TH COLSPAN=3>Connected Probes</TH>\n";
    print "     </TR><TR>\n";
    print "     <TH COLSPAN=1>Item</TH><TH COLSPAN=2>Status</TH>\n";
    print "     </TR>";
    if ( $ProbeInfoList[0] eq "Failed to Attach" ) {
        print "     <TR>\n<TD NOWRAP><center>$ProbeInfoList[0]</center></TD><TD COLSPAN=2>-</TD>\n";
    } else {
        for ($line=$offset; $line< @ProbeInfoList; $line++) {
            $conn = $line - $offset;
            print "     <TR>\n";
            print "     <TD NOWRAP><center>$ProbeInfoList[$line]</center>";
            if ( $conn == $ActiveSocket ){
                print " </TD><TD COLSPAN=2><center>Active</center></TD>\n";
            } else {
                print "</TD><TD COLSPAN=2>-</TD>\n";
            }
        }
        # print any remaining rows
        $val = "-";
        if ( $offset == @ProbeInfoList ) {
            $val = "Not Avaliable";
        }
        for ($i =0; $i < $NumSockets - (@ProbeInfoList - $offset); $i++ ) {
            print "     <TR>\n<TD NOWRAP><center>$val</center></TD><TD COLSPAN=2>-</TD>\n";
        }
    }
    print "		</TR><TR>\n\n";
    print "		<!--//Options Installed-->\n";
    print "		<TH COLSPAN=3>Options Installed</TH>\n";
    print "		</TR><TR>\n";
    print "		<TH COLSPAN=1>Option Name</TH><TH COLSPAN=2>Option Status</TH>\n";
    print "		</TR>\n";

    @pairs = getOptionStatusPairs();

    foreach $pair (@pairs)
{
    ($option,$statusval)=split(/;/,$pair);
    if(!($option =~ /EndOfOptions/))
    {

        if($statusval =~ /Disabled/)
        {
            $statusval="<font color=brown>$statusval</font>";

        }
        elsif($statusval =~ /Expired/)
        {
            $statusval="<font color=red>$statusval</font>";
        }
        elsif($statusval =~ /Permanent/)
        {
            $statusval="<font color=green>$statusval</font>";


        }
        elsif($statusval =~ /Valid/)
        {
            $statusval="<font color=yellow>$statusval</font>";


        }
        elsif($statusval =~ /Count/)
        {
            $statusval="<font color=blue>$statusval</font>";

        }

        print "<tr><TD NOWRAP> $option </TD><TD colspan=2><center>$statusval</center></TD></tr>\n";
    }

}
    print "		</TR>\n";	
    print "    </TABLE>\n\n";
    return;
}


#####
#
# Subroutine to PRINT CURRENT SYSTEM STATUS
#
#####
sub printStatus
{
&getStatus;
print "    <TABLE CLASS=\"data\" border=1 cellpadding=0 cellspacing=0 WIDTH=98%>\n";
print "    <TR>\n";
print "    <TH COLSPAN=7>Current System Status</TH>\n";
print "    </TR><TR>\n";
print "    <TH>Item</TH><TH COLSPAN=3>Information</TH><TH COLSPAN=3>Status</TH>\n";
print "    </TR><TR>\n";
print "    <TD NOWRAP>System Date</TD><TD COLSPAN=3>$SystemDate</TD><TD COLSPAN=3>-</TD>\n";
print "    </TR><TR>\n";
print "    <TD NOWRAP>System Time</TD><TD COLSPAN=3>$SystemTime</TD><TD COLSPAN=3>-</TD>\n";
print "    </TR><TR>\n";

if($product eq "Radiology.Musashi")
{

	$GhostInfo="C:\\GhostInfo.txt";

	open(GHOSTFILE, $GhostInfo);
      @ghostlines = <GHOSTFILE>;
      chop(@ghostlines);
	close(GHOSTFILE);

	$ghostdate = "";
      $ghostname = "";
      for $u (0..$#ghostlines)
      {
          if (@ghostlines[$u] =~ /GhostBuildDate/)
          {
              $ghostdate = @ghostlines[$u];
          }
          elsif (@ghostlines[$u] =~ /GhostName/)
          {
              $ghostname = @ghostlines[$u];
          }
      }

      $ghostinfo="$ghostdate <br> $ghostname";

}

if($product eq "Radiology.Musashi")
{

   print "    <TD NOWRAP>Application Software</TD><TD colspan=3><table class=\"data\" border=1 cellpadding=0 cellspacing=0 WIDTH=98%><tr><th>Version</th><th>Build Date</th><th>Ghost Information</th></tr><tr><td align=center>$ApplicationSoftware</td><td>$ApplicationBuild</td><td colspan=1>$ghostinfo</td></tr></table></TD><TD COLSPAN=3>$ApplicationSoftwareStatus</TD>\n";
}
else
{
   print "    <TD NOWRAP>Application Software</TD><TD colspan=3><table class=\"data\" border=1 cellpadding=0 cellspacing=0 WIDTH=98%><tr><th>Version</th><th>Build Date</th></tr><tr><td align=center>$ApplicationSoftware</td><td>$ApplicationBuild</td></tr></table></TD><TD COLSPAN=3>$ApplicationSoftwareStatus</TD>\n";

}
print "    </TABLE>\n\n";
return;
}



##########
#	Procedure to obtain temperatures based on the modality.
#
##########
sub getTemperature
{

    ## Hash to convert month names (from log files) to corresponding numbers

    %MontoNum = ('JAN',1,'FEB',2,'MAR',3,'APR',4,'MAY',5,'JUN',6,'JUL',7,'AUG',8,'SEP',9,'OCT',10,'NOV',11,'DEC',12);

    $currtime=time;
    $todayslines=0;
    $latesttime=0;
    $product=$ENV{'PRODUCT'};
    $default=0;


    ## May have to replace the retrieval of the temperature log file if the product is 
    #  not built on the Ultrasound global SW platform.
    #

    @SystemStatusLogFile = CookieMonster::runCommand("SystemStatus -getTemprLogFile");
    $LogFileDetails = @SystemStatusLogFile[0];
    @LogFileItems = split(/;/,$LogFileDetails);
    $LogFile = $LogFileItems[0];

    # The product name will tell how many types of temperatures are needed.
    # based on that the 'tempstrings' array is set. All the calculations will depend
    # upon this array

    if(!-f $LogFile)
    {
        $default=1;
        # No log file to obtain info from. Show N/A
    }
    else
    {
        # also check for empty file

        open(MYTEMPLOG, $LogFile);

        @TemprLogLines = <MYTEMPLOG>;
        chop (@TemprLogLines);
        close(MYTEMPLOG);

        if ($#TemprLogLines < 0)
        {
            $default=1;
        }
    }

    if($product eq "Cardiology.Idunn")
    {
        @tempstrings=("Upper Sensor on FEC","Lower Sensor on FEC");
    }
    elsif($product eq "Radiology.Pegasus")
    {
        @tempstrings=("Rack Temperature(1)","Rack Temperature(2)","HV Temperature");
    }elsif($product eq "Cardiology.Dolphin")
    {
        @tempstrings=("Temperature 1","Temperature 2");
    }
    elsif($product eq "Radiology.Musashi")
    {
        @tempstrings=("Average","TD0","TD1","TD2","TD3","TD4","TD5","TD6","TD7","EQ Out","EQ In","RFI");
    }

    else
    {
        # Could not obtain product name. Display default N/A
        $default=1;
    }
    if($default == 1)
    {
	  printDefaultTemperatureInfo();
        
        return ;
    }

    %headings=('avg','max','min');
    $numtempvalues=$#tempstrings;

    ## This may not be the case always. TODO : Mechanism to detect where the temperatures start.

    $firsttempindex=3;
    for($k=0;$k<=$numtempvalues;$k++)
    {
        $min[$k]=999;$max[$k]=-999;$avg[$k]=0;$sum[$k]=0;
        $tmin[$k]=999;$tmax[$k]=-999;$tavg[$k]=0;$tsum[$k]=0;
    }

    # setup array for serverity of temperature
    for($k=0;$k<=$numtempvalues;$k++)
    {
        $TempServerity[$k]=0;
    }


    $totallines=$#TemprLogLines+1;
    $i=0;

    ($junk,$month,$day,$hour,$min,$sec,$year,$junk2) = split(/[, \:,;]+/,$TemprLogLines[$totallines-1],8);
    $month =~ tr/a-z/A-Z/;
    $month = substr($month,0,3);
    $latesttime=timelocal($sec,$min,$hour,$day,$MontoNum{$month}-1,$year);

    for(@TemprLogLines)
    {
        @TemprLogFields = split(/;/,$TemprLogLines[$i]);
  
        ($junk,$month,$day,$hour,$min,$sec,$year,$junk2) = split(/[, \:,;]+/,$TemprLogLines[$i],8);
        $month =~ tr/a-z/A-Z/;
        $month = substr($month,0,3);
        $timeequiv=timelocal($sec,$min,$hour,$day,$MontoNum{$month}-1,$year);

        if($timeequiv==$latesttime)
        {

            $todayslines++;
        }

        for($k=0;$k<=$numtempvalues;$k++)
        {
            #remove characters that are not numbers (flags like @@, !!)
            $tempField = $TemprLogFields[$firsttempindex];
            $SevLvl=0 ;
            for ($tempField) {
                /[\^]/ and do {$SevLvl = 3; last;};
                /[\@]/ and do {$SevLvl = 2; last;};
                /[\!]/ and do {$SevLvl = 1; last;};
            }
            if ( $SevLvl > $TempServerity[$k])
            {
                $TempServerity[$k] = $SevLvl;
             }
            $tempField =~ s/[^0-9.]//g;
            $sum[$k]=$sum[$k]+$tempField;
            if($timeequiv == $latesttime)
            {
                $tsum[$k]=$tsum[$k]+$tempField;
                if($tmin[$k]>$tempField)
                {
                    $tmin[$k]=$tempField;
                }	
                if($tmax[$k]<$tempField)
                {
                    $tmax[$k]=$tempField;
                }

            }
            if($min[$k]>$tempField)
            {
                $min[$k]=$tempField;
            }
            if($max[$k]<$tempField)
            {
                $max[$k]=$tempField;
            }

            $firsttempindex++;
        }
        $firsttempindex=3;
        $i++;
    }
    $headings{max}=@max;
    $headings{min}=@min;
    @TodaysTemp=split(/;/,$TemprLogLines[$index]);

    for($k=0;$k<=$numtempvalues;$k++)
    {
        $avg[$k]=$sum[$k]/$totallines;
        $avg[$k]=sprintf "%2.2f", $avg[$k];

        $tavg[$k]=$tsum[$k]/$todayslines;
        $tavg[$k]=sprintf "%2.2f",$tavg[$k];
        $min[$k]=sprintf "%s",$min[$k];
        $max[$k]=sprintf "%s",$max[$k];
        $tmin[$k]=sprintf "%s",$tmin[$k];
        $tmax[$k]=sprintf "%s",$tmax[$k];
    }
    $headings{avg}=@sum;
    print "    <TH ROWSPAN=2>Temperatures</TH><TH COLSPAN=3>Past Five Days</TH><TH COLSPAN=6>Today</TH>\n";
    print "    </TR><TR>\n";
    print "    <TH>Avg.</TH><TH>Min.</TH><TH>Max.</TH><TH>Avg.</TH><TH>Min.</TH><TH COLSPAN=4>Max.</TH>\n";
    print "</TR>";

    for($k=0;$k<=$numtempvalues;$k++)
    {
        $Color="black";
        for ($TempServerity[$k]) {
            /3/ and do { $Color="#FF0000"; last;};
            /2/ and do { $Color="#FF0099"; last;};
            /1/ and do { $Color="#FFFF00"; last;};
        }
        print "<TR>\n";
        $str="<TD NOWRAP>";
        $str=$str.$tempstrings[$k];
        $str=$str."</TD><TD><FONT COLOR=$Color>".$avg[$k]."</FONT></TD><TD><FONT COLOR=$Color>".$min[$k]."</FONT></TD><TD><FONT COLOR=$Color>".$max[$k]."</FONT></TD><TD><FONT COLOR=$Color>".$tavg[$k]."</FONT></TD>"."<TD><FONT COLOR=$Color>".$tmin[$k]."</FONT></TD><TD COLSPAN=4><FONT COLOR=$Color>".$tmax[$k]."</FONT></TD>";
        print "$str\n";
        print "</TR>\n";
    }
    print "	</TABLE>\n";
    return;
}

sub getServConnectivity {
    $SvcConnectType=   "Not Configured";
    $SvcConnectStatus= "";

# if the agent has a .booted file, then the configuration is valid and the agent
# has been registered successfully in the backoffice (enterprise).
#
    if ( -e $ENV{"INSITE2_DATA_DIR"} . "/etc/qsaconfig.xml.booted") 
    {
        $SvcConnectStatus = "Checked Out";
    } 
    else
    {
        $SvcConnectStatus = "Not Checked Out";
    }

    
# if a valid device name has been entered, then set connectivity to configured.
#

    if ($DeviceID ne "Unknown")
    {
        $SvcConnectType = "Configured";
    }


    print "   <td>Service Connectivity</td><td>$SvcConnectType</td><td>$SvcConnectStatus</td>";
}

#####
#
#	MAIN METHOD
#
#####
MAIN:
{

$clientIpAddress=$ENV{'REMOTE_ADDR'};
$clientHostName = $ENV{'REMOTE_HOST'};
if(($clientIpAddress eq "127.0.0.1") || ($clientHostName eq "localhost") )
	{$remote = 0;}
else
	{$remote = 1;}

1;
}
