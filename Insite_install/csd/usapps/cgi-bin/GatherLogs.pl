#!D:/Program Files/InSite2/Perl/bin/perl.exe
use Getopt::Long;

use CookieMonster;

$res = GetOptions("Out=s" => \$OutputFile, "AddList:s" => \$AdditionFileList, "AddFile:s" => \$AddFile);
#print "$OutputFile\n";
#print "$AdditionFileList\n";

#if ( ! $OutputFile =~ /^$/ ) {
#	print "\n\n\ Usage:    GatherLogs.pl -Out Outfile [-AddList AddFile] [-h]\n\n";
#	print "                -Out  Outfile is the output zip file\n";
#	print "                -AddList  AddFile is an optional file that contains a list of files to zip, one per line\n";
#	print "                -h this help\n";
#	print "\n\n This will gather a bunch of files and zip them up.\n";
#	#exit;
#}

#################################################################

# read in additional files and add them to variable
$AdditionalFiles=" ";
if ( -e $AdditionFileList ) {
	open( ADDFILE, $AdditionFileList);
	while (<ADDFILE>){
		$AdditionalFiles .= $_ . " ";
	}
}

$TESTROOT=$ENV{'TEST_ROOT'};
$TARGETROOT=$ENV{'TARGET_ROOT'};

$WIPHOME=$ENV{'WIP_HOME'};
$WIPHOME =~ s/\\$//g;  #remove trailing backslash
$ApacheLogDir=$WIPHOME. "\\Apache\\logs";

$CATALINAHOME = $ENV{'CATALINA_HOME'};
$CATALINAHOME =~ s/\\$//g;  #remove trailing backslash
$TomcatLogDir=$CATALINAHOME. "\\logs";

$LogDir=" ";
if ( -e "$TARGETROOT\\resources\\idunn\\setup\\log.res" ){
	open (LOGRES, "$TARGETROOT\\resources\\idunn\\setup\\log.res");
	while (<LOGRES>){
		if ( $_ =~ /LogPath *=/) {
			$var =$_;
			$var =~ s/[ \n\r]//g;
			($junk, $LogDir) = split(/[=\#]/, $var);
			$LogDir = "\"".$LogDir."\"";
			last;
		}
	}
}
$LogDir =~ s^/^\\^g;  # replace / with \
#get the eventlog
$TEMPDIR=$ENV{'TEMP'};
$EventLogDir = $TEMPDIR."\\EventLog";
if (  -e $EventLogDir ) {
	@junk1 = CookieMonster::runCommand("cmd /c \"rmdir /s /q $EventLogDir \"");
}
@r1 = CookieMonster::runCommand("EventLogSave $EventLogDir ");

#get insite log dirs, modem log and PPP logs
$WINDIR=$ENV{'SYSTEMROOT'};
$ServiceLogs="\"$ApacheLogDir\" \"$TomcatLogDir\"";

if ( -e  "$WINDIR\\ModemLog*.txt" ) {
    $ServiceLogs .= " $WINDIR\\ModemLog*.txt";
}
if ( -e "$WINDIR\\tracing"){
	$ServiceLogs .= " $WINDIR\\tracing"; 
}
# add minidump dir, blue screen dumps
if ( -e "$WINDIR\\Minidump" )
{
    $ServiceLogs .= " $WINDIR\\Minidump";
}

# Add product specific log paths
#
if ($ENV{'USER_LOG_PATHS'} ne "")
{
    @UserLogs = split(/;/, $ENV{"USER_LOG_PATHS"});
	foreach $UserLog (@UserLogs) {
		$ServiceLogs .=  " \"" . $UserLog . "\""
	}
}

# Add files for L7
$Product=$ENV{'PRODUCT'};
$PegasusFiles="";
if ( $Product eq "Radiology.Pegasus" )
{
    $PegasusFiles="\"$TESTROOT\\resources\\Pegasus\"";
}
$PresetDir="\"$TESTROOT\\resources\\idunn\\userdefs\"";
#################################################################
#   TODO:  add service platform install logs                    #
#################################################################

$FilesToCollect ="$PresetDir $LogDir $EventLogDir $ServiceLogs $AdditionalFiles $AddFile $PegasusFiles";

if ( -e $OutputFile ) {
	@junk2 = CookieMonster::runCommand("del /f $OutputFile");
};

$cmd = "\"\"$CATALINAHOME\\webapps\\modality-csd\\usapps\\bin\\zip\" -r9 $OutputFile $FilesToCollect\"";
print "$cmd\n";

@res= CookieMonster::runCommand($cmd);

#print "@res\n";
