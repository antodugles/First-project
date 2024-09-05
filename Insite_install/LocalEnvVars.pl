# LocalEnvVars.pl
#
# This script reads the specified XML file and creates a batch file of the specified output name that will set the local environment
# variables defined in the XML file in the following structure: 
# Example:
# If Example.xml looks like this,
# <XML>
#	<LocalEnvVars>
#		<EnvVar varname="Env1">This is Env1</EnvVar>
#		<EnvVar varname="Env2">This is Env2</EnvVar>
#	</LocalEnvVars>
# </XML>
# "LocalEnvVar.pl Example.xml EnvVar.bat" will create a batch file containing the following:
# EnvVar.bat:
# set Env1=This is Env1
# set Env2=This is Env2

use XML::Simple;
#use Data::Dumper;

if( $#ARGV < 1 )
{
    print "Not enough input variables, need input and output file.\n";
    print "Usage: LocalEnvVar.pl [InputXML] [OutputBatch] [EnvVarsElement]\n";
    exit 1;
}

($InputXML,$OutputBatch,$EnvVarsElement) = @ARGV;
if ($EnvVarsElement eq "")
{
	$EnvVarsElement = "LocalEnvVars";
}

# create object
$xml = new XML::Simple;

# read XML file
$data = $xml->XMLin($InputXML, ForceArray=>["EnvVar"]);

#print Dumper($data);

if ( ! open (OUT, ">$OutputBatch")) {
    print "Unable to open output file: $OutputBatch\n";
    exit 1;
}

# iterate each child node of LocalEnvVars (or $EnvVarsElement) node and add "set" statement to the output batch file.
# if the environment variable already exists, use that value instead of the one from the XML file.
foreach $env (@{$data->{$EnvVarsElement}->{EnvVar}})
{
	if ($ENV{$env->{varname}} eq "")
	{
		$batchline = "set ".$env->{varname}."=".$env->{content}."\n";
	}
	else
	{
		$batchline = "set ".$env->{varname}."=".$ENV{$env->{varname}}."\n";
	}
	print OUT $batchline;
} 
close OUT;
