#!C:\Perl\bin\perl

# This Perl Script reads the specified install option xml and returns 0 if the requested component is
#print Dumper($data);
use CookieMonster;

# grab the tasklist buffer
$runflag = 0;

$tlcmd = "tasklist \/fi \"imagename eq qsamain.exe\"";
@buffer=CookieMonster::runCommand($tlcmd);
chop(@buffer);
for $n (0 .. $#buffer)
{
   if ( @buffer[$n] =~ /qsaMain/ )
   {
      $runflag = 1;
   }
}

if ($runflag)
{
   # print "It is running\n";
   exit 0;
}

# print "Not Running\n";
exit 1;

