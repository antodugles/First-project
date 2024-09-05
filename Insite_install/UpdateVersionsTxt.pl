# UpdateVersionsTxt.pl
# 
# This script reads the specified XML file and add additional parameters to the specified versions.txt. 
# Parameters defined in the XML file are in the following structure: 
# Example:
# If Example.xml looks like this,
# <XML>
# 	<DevicePropertyFile>
#		<ConfigProperty varname="OpSys">WINXP</ConfigProperty> 
#		<ConfigProperty varname="OpSysRev">5.1.2600</ConfigProperty> 
#	</DevicePropertyFile>
# </XML>
# Usage: UpdateVersionsTxt.pl [InputXML] [Input versions.txt Path] [Output versions.txt Path]
# "Example.xml" will add the following lines:
# OpSys: WINXP
# OpSysRev: 5.1.2600

use XML::Simple;
#use Data::Dumper;

($InputXML,$InputVersionsTxt,$OutputVersionsTxt) = @ARGV;

if ($InputXML eq "")
{
	$InputXML = "InstallOption.xml";
}

# If both input and output versions.txt paths are not specified, give the default ones
if ($InputVersionsTxt eq "")
{
	$Insite2DataDir = $ENV{"INSITE2_DATA_DIR"};
	$InputVersionsTxt = $Insite2DataDir . "\\etc\\versions.txt";
	$OutputVersionsTxt = $Insite2DataDir . "\\etc\\templates\\qsa\\versions.txt";
}

# If only input versions.txt path is specified, make it output as well.
if ($OutputVersionsTxt eq "")
{
	$OutputVersionsTxt = $InputVersionsTxt;
}

$TempOut = $OutputVersionsTxt."\.new";

# copy input versions.txt to the output
open (IN, $InputVersionsTxt) || die "Unable to open input file:  $InputVersionsTxt\n";
if ( ! open (OUT, ">$TempOut")) {
	print "Unable to open output file: $TempOut\n";
	exit 1;
}
while ( <IN> )
{
	$line = $_;
	if (!($line =~ /\n$/))
	{
		$line .= "\n";
	}
	print OUT $line;
}
close IN;

# create object
$xml = new XML::Simple;

# read XML file
$data = $xml->XMLin($InputXML, ForceArray=>["ConfigProperty"]);

#print Dumper($data);

# iterate each child node of DevicePropertyFile node and add the property to the output versions.txt file.
foreach $property (@{$data->{DevicePropertyFile}->{ConfigProperty}})
{
	print OUT $property->{varname}.": ".$property->{content}."\n";
} 
close OUT;

rename $TempOut, $OutputVersionsTxt;