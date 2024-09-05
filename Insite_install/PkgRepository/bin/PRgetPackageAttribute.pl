$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";

require $path;

$usage = "PAgetPackageAttribute [-pkgname=<pname>]|[-revnum=<rnum> -pkgtype=<ptyp>] -attrname=<attrname> [-h]\n";
$usage .= " : Retrieves attribute value of package.\n";
$usage .= "   -pkgname=<pname>   reference to stored package record.\n";
$usage .= "   -revnum=<rnum>     revision of stored package record.\n";
$usage .= "   -pkgtype=<ptyp>    package type of stored package.\n";
$usage .= "   -attrname=<attrname>  record attribute to retrieve.\n";
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
               $attrval = $hash1->{ReleasePackage}->[$rr]->{$Arg_attrname}->[0];
            }
            elsif ($retarray[0] eq "P")
            {
               $rr = $retarray[1];
               $pp = $retarray[2];

               if ($Arg_attrname eq "PkgType")
               {
                  $Arg_attrname = "PatchType";
               }
               $attrval = $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{$Arg_attrname}->[0];
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
   print "$attrval";
   exit 0;
}
else
{
   exit 1;
}
