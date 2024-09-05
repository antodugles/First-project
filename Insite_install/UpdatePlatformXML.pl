#!C:\Perl\bin\perl

# This Perl Script modifies platform.xml (InSite2 Install Option File) file in Insite2.0 folder with the updated install paths and other options.
# The modification is written to %TEMP%\platform.xml.

# Author : Jung Oh Date: November, 2005

use XML::Simple;
#use Data::Dumper;

if( $ARGV[0] eq "" ){
	print "Usage: UpdatePlatform.pl [Install Directory]\n";
	exit 1;
}

$installdir = @ARGV[0];

$config = ".\\Insite2.0\\platform.xml";

# create object
$xml = new XML::Simple (KeyAttr=>'name', RootName=>'Insite2');

# read XML file
$data = $xml->XMLin($config, forcearray => 1);
#print Dumper($data);

# modify install_path attribute of CookieMonster
$data->{software}->{CookieMonster}->{pkg}->[0]->{install_path} = $installdir."\\CKM";

# Unselect Questra Agent install. A different Questra Agent package will be installed.
$data->{software}->{Questra}->{action} = "none";

# disable registering the web server as a service
$data->{software}->{CookieMonster}->{"enable-feature"}->[0] = "php";

# write the modified xml
$newxmlstring = $xml->XMLout($data);
$newconfig = $ENV{"TEMP"} . "\\platform.xml";
unlink($newconfig) if (-f $newconfig);
open CONFIG, ">".$newconfig or die "Not able to open $newconfig file\n";
print CONFIG "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
print CONFIG $newxmlstring;
close CONFIG;
if (! -f $newconfig) {
	die "$newconfig is not created\n";
}




