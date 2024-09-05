$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";

require $path;

$usage = "PAgetParentPackage -pkgname=<pname>|[-revnum=<rnum> -pkgtype=<ptyp>][-h]\n";
$usage .= " : Retrieves the parent's package name for the given package.\n";
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

         $retval = "";

         if ($#retarray > 1)
         {
            if ($retarray[0] eq "P")
            {
               $rr = $retarray[1];
               $retval = $hash1->{ReleasePackage}->[$rr]->{PkgName}->[0];
            }
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
