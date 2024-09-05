$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";

require $path;

$usage = "PAgetPackage -pkgname=<pname>|[-revnum=<rnum> -pkgtype=<ptyp>][-h]\n";
$usage .= " : Retrieves a ptr (path) to the desired package.\n";
$usage .= "   -pkgname=<pname>   - reference of the stored package.\n";
$usage .= "   -revnum=<rnum>     - revision of the stored package.\n";
$usage .= "   -pkgtype=<ptyp>    - type of the stored package.\n";
$usage .= "   -h shows usage";

if (processArgs($usage, 1)){
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
               $attrval = $hash1->{ReleasePackage}->[$rr]->{RepositoryPath}->[0];
            }
            elsif ($retarray[0] eq "P")
            {
               $rr = $retarray[1];
               $pp = $retarray[2];
               $attrval = $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{RepositoryPath}->[0];
            }
            $retval = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $attrval;
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
   print "$retval";
   exit 0;
}
else
{
   exit 1;
}
