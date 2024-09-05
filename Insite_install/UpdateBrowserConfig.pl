# /usr/local/bin/perl.exe

# This Perl Script reads the specified install option xml file and updates CustomBrowserConfig.xml
# which contains the configuration of CustomBrowser.exe utility.

# Author : Jung Oh Date: November, 2005

$browserconfig = $ENV{"INSITE2_HOME"} . "\\bin\\CustomBrowserConfig.xml";
$newbrowserconfig = $ENV{"INSITE2_HOME"} . "\\bin\\NewCustomBrowserConfig.xml";
$optionfile = $ARGV[0];
if ($optionfile eq "")
{
	$optionfile = "InstallOption.xml";
}

unless (open(IN,"$optionfile"))
{
	print "Failed to locate file : $optionfile. Exiting.\n";
	exit 1;
}

unless (open(OUT,">$newbrowserconfig"))
{
	print "Could not create output file $newbrowserconfig. Exiting.\n";
	exit 1;
}

select(OUT);
print "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
$configexists=0;
while(<IN>)
{
	if ($_ =~ /<CustomBrowser>/)
	{
		print $_;
		while(<IN>)
		{
			print $_;
			if ($_ =~ /<\/CustomBrowser>/)
			{
				$configexists=1;
				last;
			}
		}
		last;
	} 
}
close(IN);
close(OUT);
if (!$configexists)
{
	unlink($newbrowserconfig);
	link($browserconfig, $newbrowserconfig);
}
rename($browserconfig, $browserconfig . "\.old");
# Replace environment variables
$cmd = "\"" . $ENV{"PERL_HOME"} . "bin\\perl\" ReplaceEnvVars.pl \"" . $newbrowserconfig . "\" \"" . $browserconfig . "\"";
`$cmd`;
unlink($newbrowserconfig);

