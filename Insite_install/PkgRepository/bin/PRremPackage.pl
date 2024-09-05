$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";

require $path;

$usage = "PAremPackage -pkgname=<pname> | -revnum=[rnum] -pkgtype=<ptype>] [-h]\n";
$usage .= " : Removes package from Repository.\n";
$usage .= "   -pkgname=<pname>   reference to stored package.\n";
$usage .= "   -revnum=<rnum>     revision of stored package.\n";
$usage .= "   -pkgtype=<ptyp>    pkgtype of stored package.\n";
$usage .= "   -h shows usage";

if (processArgs($usage, 1)){
   if (checkIndexMD5())
   {
      if ($Arg_helpflag)
      {
          # help was requested.  Exit here.
          exit 0;
      }
      elsif ((!$Arg_pkgname) && ((!$Arg_revnum) || (!$Arg_pkgtype)))
      {
          print "Not all required arguments are provided.\n";
          print "$usage\n";
          exit 1;
      }

      if (($Arg_revnum) && (!(validRevNum($Arg_revnum))))
      {
          print "$usage\n";
          exit 1;
      }

      if (($Arg_pkgtype) && (!(validPkgType($Arg_pkgtype))))
      {
          print "Invalid pkgtype value entered.\n";
          print "$usage\n";
          exit 1;
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
            $rr = $retarray[1];
            $pth=$hash1->{ReleasePackage}->[$rr]->{PkgName}->[0];

            if ($retarray[0] eq "R")
            {
               $hash1->{ReleasePackage}->[$rr]="";
            }
            elsif ($retarray[0] eq "P")
            {
               $rr = $retarray[1];
               $pp = $retarray[2];
               $pth .= "\\" . $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{PkgName}->[0];
               $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]="";
            }

            $delcmd = "rmdir /s /q " . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pth;
            print "$delcmd\n";
            `$delcmd`;

            writeXML($hash1);
            updateIndexMD5();
         }
         else {
            print "Package could not be found.\n";
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
   print "removed package";
   exit 0;
}
else
{
   print "Invalid command line arguments.\n";
   exit 1;
}
