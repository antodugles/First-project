#!D:/Program Files/InSite2/Perl/bin/perl.exe

use CookieMonster;

# First get the list of drives.
#
@fsdata = CookieMonster::runCommand("fsutil fsinfo drives");
chop(@fsdata);
$fsdata = @fsdata[1];
$fsdata =~ s/\\//g;
$fsdata =~ s/Drives://g;

# Clean up cmd output and parse the drive letters.
#

@drives = split(/:/,$fsdata);

print "Content-type: text/html\n\n";

print "<html>";
print "<head>";
print "<style type=\"text/css\">";
print "body {color: #000;}";
print "</style>";
print "</head>";
print "<body bgcolor=#b5b5b5></body>";

print "<pre>";

for $i (0 .. $#drives)
{
      $rawdrive = $drives[$i] . ":";
      $len = length($rawdrive);

      $thedrive = substr($rawdrive, ($len - 2), $len);

	# Get the disk usage for the drive.
	#
	@dklines = CookieMonster::runCommand("fsutil volume diskfree $thedrive");
      chop(@dklines);

      $denominator = 1.0;
      $numerator = 0.0;

	# Check 1st line if no error.  Error will if not a local drive or CD.
	#
	if (@dklines[0] =~ /Total #/)
	{	
		print "Drive $thedrive statistics:\n";
		print "-----------------------------\n";

		for $j (0 .. $#dklines)
           	{
                  if (!(@dklines[$j] =~ /avail/))
                  {
		 	    if ($j eq 0)
                      {
                         ($junk, $numerator) = split(/:/, @dklines[$j]);
                      }

                      if ($j eq 1)
                      {
                          ($junk, $denominator) = split(/:/, @dklines[$j]);
                      }

			    print "@dklines[$j]";
                  }
            }

		if ($denominator eq 0.0)
            {
               	$capacity = 0.0;
            }
            else
            {
               	$capacity = 1.00 - ($numerator/$denominator);
               	$capacity *= 100.0;
            }

            printf "Capacity                     : %2.2f\%\n", $capacity;

		print "\n\n";
	}

}

print "</pre>";
print "</body></html>";
