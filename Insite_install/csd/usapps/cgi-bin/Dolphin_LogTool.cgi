#!/usr/local/bin/perl


sub read_input
{
    local ($buffer, @pairs, $pair, $name, $value, %FORM);

    # Read in text
    $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;

    if ( $ENV{'REQUEST_METHOD'} eq "POST" ) {
       read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    } else {
       $buffer = $ENV{'QUERY_STRING'};
    }

    # Split information into name/value pairs
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs) {
        ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%(..)/pack("C", hex($1))/eg;
        $FORM{$name} = $value;
    }
   
    %FORM;
}

sub printNavHeader
{
	
	print "<html>";
	print "<p>";
	print "<p>";

}


sub printNavFooter
{
	print "</html>";
}

sub printBackLink($backLink)
{
	print "<p><a href=$backLink>back</a><p>";
}


%VAR = &read_input(); 
$Cmd = $VAR{"cmd"};
$LogFileDir=$VAR{"LOG_DIR"};

#Temporary log file directory. Get the correct stuff from Israel
$LogFileDir="d:/temp/Dolphin/Log";

$clientIpAddress=$ENV{'REMOTE_ADDR'};
$clientHostName = $ENV{'REMOTE_HOST'};

sub ShowInitPage
{
	print("Content-type: text/html\n\n");
	printNavHeader();
	print "<center><h2>Logs available on system</h2>";
	
	# Print out the first level of Log Hierarchy
	$YearDir = `ls -1 $LogFileDir`;
	@YearDirList = split(/\n/,$YearDir);
	

	$i=0;
	for(@YearDirList)
	{

		$AbsPath = $LogFileDir . "/" . $YearDirList[$i];
		if(-e $AbsPath)
		{
		if(-d $AbsPath)
		{

			@YearMonthSplit = split(/_/,$YearDirList[$i]);
		
			print "<li><a href=/uscgi-bin/Dolphin_LogTool.cgi?cmd=ShowMonths&year_month=$YearDirList[$i]>$YearMonthSplit[1] - $YearMonthSplit[$0]</a><p><p>";
		}
		}
		$i++;
	}
	

	$i=0;
	print "<center><h2>Log File Listing for Current Directory </h2>";
	print "<table border=5 cellspacing=20 cellpading=20>";
	for(@YearDirList)
	{
		$AbsPath = $LogFileDir . "/" . $YearDirList[$i];
		if(!(-d $AbsPath))
		{
			print "<tr><td>$YearDirList[$i]</td><td><a href=/uscgi-bin/Dolphin_LogTool.cgi?cmd=ShowLogFile&year_month=$ReqYear_Month&month=$Month_day&logfile=$YearDirList[$i]>View<a></td><td><a href=/uscgi-bin/Dolphin_LogTool.cgi?cmd=SaveLogFile&year_month=$ReqYear_Month&month=$Month_day&logfile=$YearDirList[$i]>Save</a></td></tr>";
		}
		$i++;

	}
	print "</table></center>";

	print "</center>";
	printNavFooter();


}

sub ShowMonthsPage
{
	print("Content-type: text/html\n\n");
	$ReqYear_Month=$VAR{"year_month"};
	$MonthLogDir=$LogFileDir . "/" . $ReqYear_Month;
	$MonthDir = `ls -1 $MonthLogDir`;
	@MonthDirList = split(/\n/,$MonthDir);
	$j=0;
	@YearMonthSplit = split(/_/,$ReqYear_Month);
	print "<center><h2>Directory Listing for $YearMonthSplit[1] - $YearMonthSplit[0]<h2>";
	for(@MonthDirList)
	{
		print "<li><a href=/uscgi-bin/Dolphin_LogTool.cgi?cmd=ShowLogList&year_month=$ReqYear_Month&month=$MonthDirList[$j]>$MonthDirList[$j]</a><p><p>";
		$j++;
	}	
	print "</center>";
}
if(($Cmd eq  "init")|| ($Cmd eq ""))
{
	ShowInitPage();
}
elsif($Cmd eq "ShowMonths")
{
	ShowMonthsPage();
	print "<center><a href=/uscgi-bin/Dolphin_LogTool.cgi?cmd=init><i>Go Back</i></a></center>";
}

elsif($Cmd eq "ShowLogList")
{
	
	$ReqYear_Month=$VAR{"year_month"};
	
	
	$Month_day =$VAR{"month"};
	if (($Month_day eq "") && ($ReqYear_Mont eq ""))
	{
		ShowInitPage();
		exit;
	}
	
	print("Content-type: text/html\n\n");
	$LogListDir=$LogFileDir . "/" . $ReqYear_Month . "/" . $Month_day;
	$LogList=`ls -1 $LogListDir`;
	@LogListItems=split(/\n/,$LogList);

	print "<center><h2>Log File Listing for $ReqYear_Month , $Month_day </h2>";
	$k=0;
	print "<table border=5 cellspacing=20 cellpading=20>";
	for(@LogListItems)
	{
		print "<tr><td>$LogListItems[$k]</td><td><a href=/uscgi-bin/Dolphin_LogTool.cgi?cmd=ShowLogFile&year_month=$ReqYear_Month&month=$Month_day&logfile=$LogListItems[$k]>View<a></td><td><a href=/uscgi-bin/Dolphin_LogTool.cgi?cmd=SaveLogFile&year_month=$ReqYear_Month&month=$Month_day&logfile=$LogListItems[$k]>Save</a></td></tr>";
	
		$k++;
	}	
	print "</table></center>";
	print "<center><a href=/uscgi-bin/Dolphin_LogTool.cgi?cmd=ShowMonths&year_month=$ReqYear_Month&month=$Month_day><i>Go Back</i></a></center>";
	
}
elsif($Cmd eq "ShowLogFile")
{
	print("Content-type: text/html\n\n");
	$ReqYear_Month=$VAR{"year_month"};
	
	$Month_day =$VAR{"month"};
	$ReqLog = $VAR{"logfile"};
	$LogFile= $LogFileDir . "/" . $ReqYear_Month . "/" . $Month_day . "/" . $ReqLog;

	if ($ReqLog =~ /\.jpg|\.jpeg/ )
	{
		if($ReqYear_Month ne "" && $Month_day ne "")
		{
        		$data="<img src=/dolphinLogs/$ReqYear_Month/$Month_day/$ReqLog>";
		}
		else
		{
        		$data="<img src=/dolphinLogs/$ReqLog>";
		}
	}
	else
	{
        	$data = `cat $LogFile`;
	}
	print "<pre> $data </pre>";
	print "<center><a href=/uscgi-bin/Dolphin_LogTool.cgi?cmd=ShowLogList&year_month=$ReqYear_Month&month=$Month_day><i>Go Back</i></a></center>";
}
elsif($Cmd eq "SaveLogFile")
{
	$ReqYear_Month=$VAR{"year_month"};
	
	$Month_day =$VAR{"month"};
	$ReqLog = $VAR{"logfile"};
	$LogFile= $LogFileDir . "/" . $ReqYear_Month . "/" . $Month_day . "/" . $ReqLog;
	$data = `cat $LogFile`;
	print("Content-type: dolphin/log\r\nContent-disposition: attachment;filename=$ReqLog\n\n");
	print "$data";
	printNavFooter();
	
	
}

else
{
	printNavHeader();
	printNavFooter();	

}

exit 0;
