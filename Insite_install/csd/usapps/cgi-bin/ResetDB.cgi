#!/usr/local/bin/perl

use CookieMonster;

$debug = 0;
print "Content-type:text/html \n\n";
print "<body bgcolor=#FFFFCC>";
$buffer=$ENV{'QUERY_STRING'};
@pairs=split(/&/,$buffer);
foreach $pair (@pairs)
{
	($name,$value) = split(/=/,$pair);
	$value=~tr/+/ /;
	$value =~ s/%(..)/pack("C",hex($1))/eg;
	$FORM{$name}=$value;
}
$status=1;
$PRODUCT=$ENV{'PRODUCT'};
$PRODUCT=~s/^[^\.]*\.//;
if ( $PRODUCT eq "Pegasus" ){
    $DataDir="E:/Idunn";
} elsif ( -e "C:/$PRODUCT"){
    $DataDir="E:/$PRODUCT";
} else {
    $DataDir="E:/Data";
}
$TARGET_ROOT=$ENV{"TARGET_ROOT"};
$TARGET_ROOT=~ s?\\?/?g;
$BackupDB=$TARGET_ROOT. "/resources/idunn/EchoArchive/RemovableArchive/PatientArchive";
if ( ! -e $BackupDB ) {
    $BackupDB=$TARGET_ROOT. "/resources/idunn/EchoArchive/LocalArchive/PatientArchive";
}
$INSITE_HOME = $ENV{"INSITE_HOME"};
$INSITE_HOME=~ s?\\?/?g;
$PERL_HOME = $ENV{"PERL_HOME"};
$PERL_HOME=~ s?\\?/?g;

if ($debug) {
print "$DataDir<br>\n";
print "$BackupDB<br>\n";
}

$bkup=$FORM{"bkup"};
if($bkup ne "")
{
    	if (! -e $DataDir ) {
            print "<H2>ERROR:  Unable to find data directory\n";
            print "</body>";
            exit;
    	}
    	if ($DataDir eq "" ) {
            print "<H2>ERROR:  DataDir var is empty\n";
            print "</body>";
            exit;
    	}
        if ( ! -e $BackupDB ) {
            print "<H2>ERROR:  Unable to find backup database directory\n";
            print "</body>";
            exit;
    	}
 	open RDBREG, ">rdb.reg" or die "Not able to open rdg.reg file\n";
	print RDBREG "REGEDIT4\n\n";
	print RDBREG "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunOnce]\n";
	$RegData = "\"ResetDB\"=\"\\\"" . $PERL_HOME . "bin/perl\\\" \\\"$INSITE_HOME/cgi-bin/ResetDB.cgi\\\"\"";
	print RDBREG "$RegData\n";
	close RDBREG;
	`regedit /s rdb.reg`;
	$status=$? >> 8;
	if($status ne 0)
	{
		print "<b>Database reset failed</b>\n";
	}
	else
	{
		print "<b> Database will be reset the next time system is rebooted.<br>";
		print "Please reboot the system to start with a fresh database</b>"; 
	}
	print "</body>";
}
else
{
	$log="d:\\\\log\\\\logfile-ResetDb.txt";
	print "Resetting database...\n";
        `date /t >> $log;echo Start Resetting database >> $log`;
        $dbserver="";
        $count = 0;
        while ( ($dbserver eq "")&& ($count++<10))
        {
	        @buffer=CookieMonster::runCommand("net start");
            for $n (0 .. $#buffer)
		    {
				#print "buffer: " . @buffer[$n] . "\n";
				if( @buffer[$n] =~ /^\s*Adaptive Server Anywhere\s*/)
				{
					$dbserver = @buffer[$n];
				}
			}	
            $dbserver =~ s/^[ ]+//g;
            $dbserver =~ s/[\r\n]//g;
            if ( $count >1) {
                sleep 15;  # no delay on first try
            }
            print "$count $dbserver\n";
            `echo $count $dbserver >> $log`;
        }
	if($dbserver ne "")
	{
		`net stop "$dbserver" >>$log 2>&1`;
    } else {
        `wscript "$INSITE_HOME\\\\html\\\\warning.js" "ResetDb:  Unable to reset database" "Error" 10`;
        `echo Failed to find database to stop >> $log | date /t >> $log`;
        exit;
    }

	# Code to remove curr db files and replace with 0 size ones
	`rd /s /q "$DataDir/GEMS_DB" >>$log 2>&1`;
	`rd /s /q "$DataDir/GEMS_IMG" >>$log 2>&1`;
	`rd /s /q "$DataDir/GEMS_REP" >>$log 2>&1`;
	`md "$DataDir/GEMS_DB" >>$log 2>&1`;
	`md "$DataDir/GEMS_IMG" >>$log 2>&1`;
	`md "$DataDir/GEMS_REP" >>$log 2>&1`;
	
    $CpCmd = "xcopy /s /e /y \"$BackupDB\" \"$DataDir/GEMS_DB\"";
	$res = `$CpCmd  2>&1 >>$log`;
    print "$res\n";
	if($dbserver ne "")
	{			
		$res = `net start "$dbserver" >>$log 2>&1`;
        print $res;
	}
    `echo Completed >> $log | date /t >> $log`;
	sleep 5;
}
