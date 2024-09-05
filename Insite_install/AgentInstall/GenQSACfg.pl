# GenQSACfg.pl
#

#
# Usage:  perl GenQSACfg.pl
#


##
##  Find the installed asset name.
##
if ($ENV{"INSITE2_ROOT_DIR"} eq "")
{
	print "INSITE2_ROOT_DIR environment variable doesn't exist.\n";
	exit 1;
}
else
{
	if($ENV{"INSITE2_DATA_DIR"} eq "")
	{
		$AgentCfgFile = $ENV{"INSITE2_ROOT_DIR"} . "/etc/qsaconfig.xml";
		$SiteDefsFile =  $ENV{"INSITE2_ROOT_DIR"} . "\\etc\\sitedefs.txt";
	}
	else
	{
		$AgentCfgFile = $ENV{"INSITE2_DATA_DIR"} . "/etc/qsaconfig.xml";
		$SiteDefsFile =  $ENV{"INSITE2_DATA_DIR"} . "\\etc\\sitedefs.txt";
	}
}


open(AGENTFILE, $AgentCfgFile);
@AgentFileLines = <AGENTFILE>;
chop(@AgentFileLines);

close(AGENTFILE);

$AssetName = "";

for $a ( 0..$#AgentFileLines )
{
	if (@AgentFileLines[$a] =~ /MemberName/)
      {
		$AssetName = @AgentFileLines[$a];
	}
}

$AssetName =~ s/<MemberName>//;
$AssetName =~ s/<\/MemberName>//;
$AssetName =~ s/^\s*|\s*$//g;
	
$Checkwin = "";
$Checkwin = "C:/WINDOWS/qsacfg";

if (-d $Checkwin)
{
   $delcmd = "";
   $delcmd = "rmdir /S /Q C:\\WINDOWS\\qsacfg";
   `$delcmd`;
}

$newcmd = "";
$newcmd = "mkdir C:\\WINDOWS\\qsacfg";
`$newcmd`;

print "Copy file into windows.\n";

$newcmd = "";
$newcmd = "mkdir C:\\WINDOWS\\qsacfg\\" . $AssetName;
`$newcmd`;

$cpycmd = "";
$cpycmd = "copy /Y \"$SiteDefsFile\" ";
$cpycmd .= "C:\\WINDOWS\\qsacfg\\" . $AssetName;
`$cpycmd`;

# ... and change permissions to allow users read-execute access
$chmodcmd = "ECHO Y| CACLS C:\\WINDOWS\\qsacfg\\" . $AssetName;
$chmodcmd .= "\\sitedefs.txt /G EVERYONE:F";
`$chmodcmd`;