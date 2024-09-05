# This script updates the specified Apache configuration file 
# to either open the listening address and port to any address and port or
# to close to only localhost depending on the option switch.
#
# Written by: Jung Oh
# Date: 1/30/06
#
# Usage:
#   perl SetWebServerSec.pl [open | close] [Configuration File]

if( $#ARGV < 1 )
{
    print "Usage: perl SetWebServerSec.pl [open | close] [Configuration File]\n";
    exit 1;
}
$option = $ARGV[0];
$infile = $ARGV[1];
$infile =~ s/\\/\//g;
$input_conf = $infile;
#print $ARGV[1];
unless (open(IN_FILE,"$input_conf"))
{
	print "Failed to locate file : $input_file. Exiting\n";
	exit -1;
}
$out_file = "$input_conf.out";

unless (open(OUT_FILE,">$out_file"))
{
	print "could not create out put file $out_file \n";
	exit -1;
}
$old = select(OUT_FILE);
while(<IN_FILE>)
{
	if ($option eq "open")
	{
		if ($_ =~ /^Listen\s+\d+\.\d+\.\d+\.\d+:\d+/)
		{
			$_ =~ s/\d+\.\d+\.\d+\.\d+://;  # remove the IP bounding
		}
	}
	elsif ($option eq "close")
	{
		if ($_ =~ /^Listen\s+\d+$/)
		{
			$_ =~ s/\s+/ 127\.0\.0\.1:/; # insert the local IP bounding
		}
	}
	print "$_";
}

close(IN_FILE);
close(OUT_FILE);
rename($out_file , $input_conf);
