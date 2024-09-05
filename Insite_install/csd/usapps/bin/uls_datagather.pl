#!/usr/bin/perl
#use lib qw(//d/projects/ms29484_view2/target/service/insite/perl/lib/);
# INSITE_HOME will be replaced during installation with actual value
BEGIN { unshift(@INC,"#INSITE_HOME#/perl/lib/");}

use Time::Local;

# Creates the destination dirs and corresponding dirs for storing data for this 
# invocation.

sub makeDestination
{
	local($dirName) = $_[0];
	# Convert time in secs to date structure tm
	@inDate = localtime($dirName);
	if ( ! ( -e "$OBT_DATADIR_PATH" ) )
	{
		mkdir ( "$OBT_DATADIR_PATH",0777);
	}
	#Format the date obtained from time in secs to <YYYYMMDDHHMMSS>
	$str_dirName = sprintf( "%04s%02s%02s%02s%02s%02s",$inDate[5]+1900,$inDate[4]+1,$inDate[3],$inDate[2],$inDate[1],$inDate[0]);
	#print "Dir name:$str_dirName";
	$OBT_DATADIR = $OBT_DATADIR_PATH."/$str_dirName";
	if ( ! ( -e "$OBT_DATADIR" ) )
	{
		mkdir("$OBT_DATADIR",0777);
		
		# The sub dirs of curr dir should be the ones that will have 
		# files. As of now only log is being collected.
		if ( ! ( -e "$OBT_DATADIR" ) )
		{
			mkdir( "$OBT_DATADIR",0777);
		}
	}
	return;

} 



# Process the logs. The log file should be in $TEST_ROOT/logs. TEST_ROOT should 
# be set by the time this is called.

sub processLogs
{

	$linenum = 0;
	# Associative array to translate month names to numbers.
	%monthText2Num = ('JAN',1,'FEB',2,'MAR',3,'APR',4,'MAY',5,'JUN',6,'JUL',7,'AUG',8,'SEP',9,'OCT',10,'NOV',11,'DEC',12);

	$logFileName = $_[0];
	
	# Open this file for writing.
	unless ( open(DATA_FILE, ">$OBT_DATADIR/uslog.log" ) )
	{
		$ERRSTRING = $ERRSTRING."Failed to create destination log file: $OBT_DATADIR/uslog.log\n\n";
		$ERRFLAG = 1;
		return;
	}

	# Make the DATA_FILE as the output handle.
	$oldhandle = select(DATA_FILE); 
	
	print "*********** Ultrasound Scanner Logs **************\n\n";
	print "\n\n";
	print "Data Gathered for problem: $ptype\n\n";
	print "Problem reporting time   : $date_time\n\n";
	print "Source Log file for data : $logFileName\n\n";
	@s_str=localtime($starttime);@e_str=localtime($endtime);
	$s_str[4] += 1;$s_str[5] +=1900;	
	$e_str[4] += 1;$e_str[5] +=1900;	
	print "Results of data gathering function:\n\n";	
	# Open the source log file.
	unless ( open(LOG_FILE,$logFileName) )
	{
		$ERRSTRING = $ERRSTRING. "Data Gathering function: Could not find log file $logFileName.\n\n";
		#print "$ERRSTRING";
		$ERRFLAG = 1;
		close(DATA_FILE);
		select($oldhandle);
		return;
	}
	
	# Read the logs and process the time part to do comparisions.
	print "Data gathered between(MM/DD/YYYY HH:MM:SS) ($s_str[4])/$s_str[3]/$s_str[5] $s_str[2]:$s_str[1]:$s_str[0] and ($e_str[4])/$e_str[3]/$e_str[5] $e_str[2]:$e_str[1]:$e_str[0]\n\n";  


	# Use a flag to check for any hits
	
	$hits=0;
	
	#$logFileContent = `cat $logFileName`;
	#@logFileLines=split(/\n/,$logFileContent);
	@logFileLinesArr=<LOG_FILE>;
	#for($i=$#logFileLinesArr;$i=0;$i--)
	$linenum = $#logFileLinesArr;
	while($linenum!=0)
	#while(<LOG_FILE>)
	{
		#$logFileLines=$_;
		$logFileLines=$logFileLinesArr[$linenum];
		chop $logFileLines;
		if($logFileLines ne "")
		{

		($junk,$month,$day,$hour,$min,$sec,$year,$junk2) = split(/[, \:,;]+/,$logFileLines,8);
		#print "$linenum:month--$month:day -- $day:hour -- $hour:mins -- $min:sec -- $sec:Year -- $year\n";
		
		#Make sure the characters that we get for day of the week are correct. The first string (before , in the log file)


		if($junk =~ /Mon|Tue|Wed|Thu|Fri|Sat|Sun/)
		{
	

		# Take only 1st 3 letters of month.
		$month =~ tr/a-z/A-Z/;
		$month = substr($month,0,3);
		# determine the time equiv of the date obtained from logs
		# Need this for comparisions.
		#print "YEAR BEFORE : $year";
		$timequiv = timelocal($sec,$min,$hour,$day,$monthText2Num{$month}-1,$year);
		@tempstr = localtime($timequiv);
		#print "Blah:$tempstr[4]:$tempstr[5]:$tempstr[3]::Time:$tempstr[2]:$tempstr[1]:$tempstr[0]"."\n";
		#print "Time equiv is :$timequiv\n";
		#print "End time : $endtime\n";	
		if ( ($timequiv >= $starttime) && ($timequiv <= $endtime) )
		{
			$hits++;	
			print  $logFileLines."\n";	
		}
		elsif ( $timequiv < $starttime ) 
		{ 
			last; 
		}
		}
		}
		$linenum--;
	}

			if($hits==0)
			{
				print " No information pertaining to the problem found!!\n";
				print " Reason: The problem reporting time might be way back (more than 30 mins prior)\n\n";
			}
			print "\n\n****** END LOGS *****\n";
	close(DATA_FILE);
	close(LOG_FILE);
	select($oldhandle);
	return;
}

### MAIN Routine ###
$ERRFLAG = 0; # Set if any error occurs. which will prevent program from going 		      #	further
$ERRSTRING = "The following errors occured while executing the data gathering function\n\n\n";
$starttime = 0;
$endtime = 0;
# Log file location. TEST_ROOT/logs

$INSITE_HOME = `cat /etc/.insite.homedir`;
#$INSITE_HOME =~ s/.*://g;
chop $INSITE_HOME;
#$TEST_ROOT = $ENV{'TEST_ROOT'};

# Obtain TARGET_ROOT so that we can find the resource file that will tell us
# about the location of log file.

$TARGET_ROOT="$INSITE_HOME/../..";
#$TARGET_ROOT = `grep TARGET_ROOT '$INSITE_HOME'/.properties`;
#$TARGET_ROOT =~ s/TARGET_ROOT=//g;
#chop $TARGET_ROOT;
$TARGET_ROOT =~ s/\\/\//g;  # Translate any \ to /. 
$TEST_ROOT=$ENV{'TEST_ROOT'};
$TEMPDIR=$ENV{'TEMP'};

if($TEST_ROOT eq "")
{
	$TEST_ROOT=`grep TEST_ROOT $INSITE_HOME/.properties | cut -f2 -d=`;

}

$TEST_ROOT =~ s/\\/\//g;

$resourcefile="$TARGET_ROOT/resources/idunn/setup/log.res";
@linesfromres=`grep -w File $resourcefile`;

($val1,$val2)=split(/[;\n]/,$linesfromres[0]);
($val1,$logvalue)=split(/=/,$val1);
$logvalue =~ s/\\/\//g;
$US_LOG = $logvalue;

@logpathsplit=split(/\//,$logvalue);
$LOG_PATH=$logpathsplit[0];
$i=1;
while($i!=$#logpathsplit)
{
	$LOG_PATH=$LOG_PATH."/".$logpathsplit[$i];
	$i++;
}

#$LOG_LOCATION = $TEST_ROOT."/logs";
#$US_LOG = $LOG_LOCATION."/logfile.txt";

# OBT data directory contains all the data gathered for the problems. Its under
# INSITE_HOME/apps/obt/data.
$OBT_DATADIR_PATH = "d:/export/service";

# This points to the place where the extracted log files will be put. Init to
# the OBT data parent dir.

$OBT_DATADIR = $OBT_DATADIR_PATH;

$currtime = time;
#Process the command line arguments and store the values in appropriate vars.

$index = 0;
while ( $ARGV[$index] ne "" )
{
	if( $ARGV[$index] eq "-p" )
	{
		$index++;
		$ptype = $ARGV[$index];
	}
	elsif( $ARGV[$index] eq "-s" )
	{
		$index++;
		$availspace = $ARGV[$index];

	}
	elsif( $ARGV[$index] eq "-t" )
	{
		#-t option has time as <date> <time>
		$index++;
		$date_time = "$ARGV[$index++]";
		$date_time .= " $ARGV[$index]";
	}
	$index++;
}


# If Date part is null then default to current date and time else check the 
# validity of the date

if( $date_time ne "" )
{
	#parse the date string and collect values in different vars.

	($mon,$day,$year,$hour,$mins,$sec)=split(/[ \/\t:]+/,$date_time,6);
	if( ($mon <= 12) && ($mon >=1) && ($day >= 1) && ($day <=31) && ($hour <=23 ) && ($hour >= 0) && ($mins <= 59 ) && ($mins >=0) && ($year >=0) && ($year <=2069) )
	{
	  if ( $year < 100 ) {$year += 2000;} 
		$mon -= 1; # time is struct tm. months begin with 0 instead of 1.
		$mmins = timelocal($sec,$mins,$hour,$day,$mon,$year);
	
	}
	else
	{
		$ERRSTRING = $ERRSTRING."User input; Invalid values for Date. Using current date and time\n\n";
		$mmins = $currtime;
	}
}
else
{
	# Default to current time.
 	$ERRSTRING = $ERRSTRING."User input: Date invalid value\n\n. Using current date and time\n\n";
	$mmins = $currtime;
}

# Make sure the user has not provided a future time value !!

if( $mmins > $currtime )
{
	# Default the input time (mmins) to current
	$mmins = $currtime;
}




# Calculate the time range of log that needs to be grabbed from the log file.

# If the problem occuring time (according to user) is way before current time,
# pick the logs 15 mins before and 15 mins after the occurance of error.
# else pick the last 30 mins of log.

# $timerange defines the time span between which the log falls. Default value
# 30 minutes. 

$timerange = 30;
# if the problem occuring time is 15 mins prior the curr time, then
# grab only last 30 mins of information.


if (($currtime-$mmins) < (15*60)) # we need to know if its less than 15 mins.
			          # times 60 to get seconds.
{
	$starttime = $currtime - ($timerange*60); # Last 30 mins
}
else
{
	$starttime = $mmins - ($timerange*30); # i.e $timerange/2*60. 15 mins
} 


# endtime is always 30 mins after the starttime.
$endtime = ($starttime + ($timerange*60));

# create destination directory/files. The dir name should be <currdate><currtime# >

&makeDestination( $currtime );

# Can collect all the log files in an array (@) and process each of them., if 
# all the logs have same format (i.e date coming in as the first files (seperat-
# ed by ;
#for($i=0;$i<=$numLogs;$i++)
#{

&processLogs( $US_LOG);

#}

# Check for any error.

if ( $ERRFLAG ne 0 )
{
# Error occured open err.log under the OBT_DATADIR and dump ERRSTRING in there.
	open(ERROR_FILE, ">$OBT_DATADIR/err.log" );
	$oldhandle=select(ERROR_FILE);
	print "$ERRSTRING";
	close($ERROR_FILE);
	select($oldhandle);
	print "ERROR: Executing data gathering function."
}
# Application can collect the dir info from this.
else
{
    `ScreenCapture`;
    #`zip -9r $OBT_DATADIR/OBTData_At_$str_dirName.zip $LOG_PATH $TEST_ROOT/resources/idunn/userdefs c:/temp/screendump.bmp`;
    `perl $INSITE_HOME/../svcpform/bin/GatherLogs.pl -Out $OBT_DATADIR/OBTData_At_$str_dirName.zip -AddFile $TEMPDIR/screendump.bmp`;

    print "$OBT_DATADIR\n";
}
exit 0;
