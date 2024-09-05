$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";
require $path;

$usage = "PAgetChildPackage [-pkgname=<pname>]|[-revnum=<rnum> -pkgtype=<ptype>][-h]\n";
$usage .= " : Retrieves the child full application install package NAME (pkgtype AF) for given parent.\n";
$usage .= "   -pkgname=<pname>   - name of blob's parent package.\n";
$usage .= "   -revnum=<rnum>     - revision numbe of blob's parent pkg.\n";
$usage .= "   -pkgtype=<ptyp>    - pkg type of blob's parent pkg.\n";
$usage .= "   -h shows usage";

$retval = "";

if (processArgs($usage, 3)){
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
               $bb = findChildAppl($hash1, $rr);
               if ($bb > -1)
               {
                  $retval = $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$bb]->{PkgName}->[0];
               }
               else
               {
                  exit 1;
               }
            }
            elsif ($retarray[0] eq "P")
            {
               exit 1;
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
