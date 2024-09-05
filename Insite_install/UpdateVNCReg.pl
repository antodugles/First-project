# UpdateVNCReg.pl
#
# Usage: perl UpdateVNCReg.pl [VNCPort] [VNCHttpPort]
#
# Updates the RealVNC registry settings to listen on ports other than the
# default 5900, 5800.  If same as default, it will sklp processing.
#

$newVNCPort = "";
$newVNCHttpPort = "";
($newVNCPort, $newVNCHttpPort) = @ARGV;

print "Arg: $newVNCPort; $newVNCHttpPort\n";

if ($newVNCPort eq "")
{
   $newVNCPort = "5900";
}
if ($newVNCHttpPort eq "")
{
   $newVNCHttpPort = "5800";
}

$newHexPort = sprintf("0x%x", int($newVNCPort));
$newHexHttpPort = sprintf("0x%x", int($newVNCHttpPort)); 

$hklmkey = "reg.exe ADD HKEY_LOCAL_MACHINE\\SOFTWARE\\RealVNC\\WinVNC4 /v ";
$hkcukey = "reg.exe ADD HKEY_CURRENT_USER\\Software\\RealVNC\\WinVNC4 /v ";
$midway = " /t REG_DWORD /d ";

if ($newVNCPort ne "5900")
{
   $cmdtxt = "";
   $cmdtxt = $hklmkey . "PortNumber" . $midway . $newHexPort . " /f";
   print "$cmdtxt\n";
   `$cmdtxt`;

   $cmdtxt = "";
   $cmdtxt = $hkcukey . "PortNumber" . $midway . $newHexPort . " /f";
   print "$cmdtxt\n";
   `$cmdtxt`;
}

if ($newVNCHttpPort ne "5800")
{
   $cmdtxt = "";
   $cmdtxt = $hklmkey . "HTTPPortNumber" . $midway . $newHexHttpPort . " /f";
   print "$cmdtxt\n";
   `$cmdtxt`;

   $cmdtxt = "";
   $cmdtxt = $hkcukey . "HTTPPortNumber" . $midway . $newHexHttpPort . " /f";
   print "$cmdtxt\n";
   `$cmdtxt`;
}
