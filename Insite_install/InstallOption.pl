#!C:\Perl\bin\perl

# This Perl Script reads the specified install option xml and returns 0 if the requested component is
# configured to be installed.  It returns 1 if the requested component is not configured to be installed.
# The following example checks if the Web Server is configured to be installed in InstallOption.xml file:
# Example: Perl InstallOption.pl WebServer InstallOption.xml 

# If the optional StartMode parameter is provided, it will check on the start mode and return 0 if the start mode
# matches and 1 if it doesn't match.
# Example: Perl InstallOption.pl QuestraAgent InstallOption.xml AutoService

# Author : Jung Oh Date: Feb, 2006

use XML::Simple;
#use Data::Dumper;

if( $#ARGV < 1 )
{
    print "Usage: Perl InstallOption.pl [Component Name] [Install Option XML] [StartMode]\n";
    exit 2;
}

($componentname,$optionfile,$startmode) = @ARGV;

# create object
$xml = new XML::Simple;

# read XML file
$data = $xml->XMLin($optionfile);

#print Dumper($data);

# Check the install option
if ($data->{ComponentConfig}->{$componentname}->{Install} eq "1")
{	
	if ($startmode ne "")
	{
		if ($data->{ComponentConfig}->{$componentname}->{StartMode} eq $startmode)
		{
			#print "YesStart\n";
			exit 0;
		}
		else
		{
			#print "NoStart\n";
			exit 1;
		}
	}
	#print "YesInstall\n";
	exit 0;
} 
#print "NoInstall\n";
exit 1;

