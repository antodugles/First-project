$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";

require $path;

$usage = "PAupdPackageState [-pkgname=<pname>]|[-revnum=<rnum> -pkgtype=<ptyp>][-setpending|-pending|-install|-uninstall][-h]\n";
$usage .= " : Updates attribute of package.\n";
$usage .= "   -pkgname=<pname>   reference to stored package record.\n";
$usage .= "   -revnum=<rnum>     revision of stored package record.\n";
$usage .= "   -pkgtype=<ptyp>    package type of stored package.\n";
$usage .= "   -setpending        <PendingFlag> attr set to TRUE.\n";
$usage .= "   -unsetpending      <PendingFlag> attr set to FALSE.\n";
$usage .= "   -install           <InstallOrder> updated and <InstFlag> attr set to TRUE.\n";
$usage .= "   -uninstall         <InstFlag> attr set to FALSE.\n";
$usage .= "   -h shows usage";

if (processArgs($usage, 4)){
   if (checkIndexMD5())
   {
      if ($Arg_helpflag)
      {
          # help was requested.  Exit here.
          exit 0;
      }
      $hash1 = readXML();

      if ($hash1)
      {
         if ($Arg_pkgname){
            @retarray = findHashPackages($hash1, $Arg_pkgname);       
         }
         elsif (($Arg_pkgtype) && ($Arg_revnum)){
            @retarray = findHashPackages($hash1, $Arg_revnum, $Arg_pkgtype);
         }

         if ($#retarray > 1)
         {
            if ($retarray[0] eq "R")
            {
               $rr = $retarray[1];
               if ($Arg_installflag)
               {
                  $ni = $hash1->{NextInstallCtr}->[0];
                  $hash1->{ReleasePackage}->[$rr]->{InstFlag}->[0] = "TRUE";
                  $hash1->{ReleasePackage}->[$rr]->{InstallOrder}->[0] = $ni;
                  $hash1->{ReleasePackage}->[$rr]->{PendingFlag}->[0] = "FALSE";
                  $hash1->{NextInstallCtr}->[0] = $ni + 1;
               }
               elsif ($Arg_uninstallflag)
               {
                  $hash1->{ReleasePackage}->[$rr]->{InstFlag}->[0] = "FALSE";
               }
               elsif ($Arg_setpendingflag)
               {
                  $hash1->{ReleasePackage}->[$rr]->{PendingFlag}->[0] = "TRUE";
               }
               elsif ($Arg_unsetpendingflag)
               {
                  $hash1->{ReleasePackage}->[$rr]->{PendingFlag}->[0] = "FALSE";
               }
            }
            elsif ($retarray[0] eq "P")
            {
               $rr = $retarray[1];
               $pp = $retarray[2];
               if ($Arg_installflag)
               {
                  $ni = $hash1->{NextInstallCtr}->[0];
                  $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{InstFlag}->[0] = "TRUE";
                  $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{InstallOrder}->[0] = $ni;
                  $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{PendingFlag}->[0] = "FALSE";
                  $hash1->{NextInstallCtr}->[0] = $ni + 1;
               }
               elsif ($Arg_uninstallflag)
               {
                  $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{InstFlag}->[0] = "FALSE";
               }
               elsif ($Arg_setpendingflag)
               {
                  $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{PendingFlag}->[0] = "TRUE";
               }
               elsif ($Arg_unsetpendingflag)
               {
                  $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{PendingFlag}->[0] = "FALSE";
               }
            }
            writeXML($hash1);
            updateIndexMD5();
         }
         else {
            exit 1;
         }
      }
      else {
         exit 1;
      }
   }
   else
   {
      exit 1;
   }
   print "updated package";
   exit 0;
}
else
{
   exit 1;
}
