# This script reads InstallSvcAppsOption.xml file or specified XML file and sets or delete the system environment 
# variables defined in <SystemEnvVars> node.
# Usage:
# SystemEnvVars.pl [set|delete] <XML file path>
#
# Example:
# SystemEnvVars.pl set 
# SystemEnvVars.pl delete C:\Test.xml
# If the XML looks like this,
# <XML>
#	<SystemEnvVars>
#		<EnvVar varname="Env1">This is Env1</EnvVar>
#		<EnvVar varname="Env2">This is Env2</EnvVar>
#	</SystemEnvVars>
# </XML>
# Env1 and Env2 system environment variables will be set or deleted
#
# Author : Jung Oh Date: November, 2005

use XML::Simple;
#use Data::Dumper;

$option = $ARGV[0];
$inputxml = $ARGV[1];

if ($option ne "set" and $option ne "delete")
{
	print "Usage: SystemEnvVars.pl [set|delete] <XML file path>\n";
	exit 1;
}

if ($inputxml eq "")
{
	$inputxml = "InstallOption.xml";
}

# create object
$xml = new XML::Simple;

# read XML file
$data = $xml->XMLin($inputxml, ForceArray=>["EnvVar"]);

#print Dumper($data);

# iterate each child node of <SystemEnvVars> node and create system environment variables
foreach $env (@{$data->{SystemEnvVars}->{EnvVar}})
{
	if ($option eq "set")
	{
		`SetEnv -a $env->{varname} \"$env->{content}\"`;
		#print $env->{varname};
	}
	else
	{
		`SetEnv -d $env->{varname}`;
	}
} 
