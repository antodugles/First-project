$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";
require $path;

$usage = "PAgetBlob -blobname=<bname> [[-pkgname=<pname>]|[-revnum=<rnum> -pkgtype=<ptype>]][-h]\n";
$usage .= " : Retrieves an auxiliary file or directory stored as a package attribute.\n";
$usage .= "   =blobname=<bname>  = reference of stored blob file/directory.\n";
$usage .= "   -pkgname=<pname>   - name of blob's parent package.\n";
$usage .= "   -revnum=<rnum>     - revision numbe of blob's parent pkg.\n";
$usage .= "   -pkgtype=<ptyp>    - pkg type of blob's parent pkg.\n";
$usage .= "   -h shows usage";

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
               $bb = findBlob($hash1, $Arg_blobname, $rr);
               if ($bb > -1)
               {
                  $bval = $hash1->{ReleasePackage}->[$rr]->{BlobList}->[0]->{Blob}->[$bb]->{BlobPath}->[0];
                  $retval = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $bval;
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
   print "$retval\n";
   exit 0;
}
else
{
   exit 1;
}
