#!/usr/local/bin/perl

#  #! d:\mks\mksnt\perl.exe



#
# Some date and time arrays
#
@mos = (January,February,March,April,May,June,July,August,September,
        October,November,December);
@days = (Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday);
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;


$logfile = "/tmp/env.pl.out";

#
# get login name
#
$login = getlogin || (getpwuid($<))[0] || "nobody";

#
# open log file for appending
#
if ((open(OUT, ">" . $logfile)) != 1) {
    die "Could not open logfile " . $logfile . "\n";
}

print <<EOD;
Content-type: text/html

<HTML>
<HEAD>
<TITLE>InSite Interactive Platform HTTP Server Environment Settings</TITLE>
</HEAD>


<body bgcolor=ffffff>
  <font size=+2 color=1b7a84><b>Local CGI Test</b></font>
  <p>
  <b>Test Successful!</b>: The presence of this page validates local CGI functionality and connectivity.
  <p><hr size=1><p>
Environment settings are found in:
<br>\$INSITE_HOME/server/conf/httpd.conf

EOD

#
# Header
#
print OUT "\n";
print OUT "<hr>\n";
print OUT "date: " . $days[$wday] . ", " . $mos[$mon] . " " . $mday . ", 19" . 
   $year .  " @ " . $hour . ":" . sprintf("%02d", $min) . "\n";
print OUT "user: " . $login . "\n";
print OUT "<hr>\n";

#
# Print out user's environment
#
foreach $key (sort(keys(%ENV))) {
        printf(OUT "%-20s = %s\n", $key, $ENV{$key});
}
print OUT "<hr>\n";

close OUT;
open(OUT, $logfile);
print "<pre>";
while(<OUT>) {
        print $_ . "<br>";
}
print "</pre>";

print <<END3;
</BODY>
</HTML>
END3
###############################################################################

