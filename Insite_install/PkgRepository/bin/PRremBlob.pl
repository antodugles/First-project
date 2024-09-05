$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";

require $path;

$usage = "PAremBlob -pkgname=<pname> | -revnum=[rnum] -pkgtype=<ptype>] -blobname=<bname> [-h]\n";
$usage .= " : Removes blob from package record in Repository.\n";
$usage .= "   -pkgname=<pname>   reference to stored package.\n";
$usage .= "   -revnum=<rnum>     revision of stored package.\n";
$usage .= "   -pkgtype=<ptyp>    pkgtype of stored package.\n";
$usage .= "   -blobname=<bname>  blob name of auxilliary file or directory to remove.\n";
$usage .= "   -h shows usage";

if (processArgs($usage, 3)){
   if (checkIndexMD5())
   {
      if ($Arg_helpflag)
      {
          # help was requested.  Exit here.
          exit 0;
      }

      if ((!$Arg_pkgname) && (!(($Arg_revnum) && ($Arg_pkgtype))))
      {
          print "Not all required arguments are provided.\n";
          print "$usage\n";
          exit 1;
      }

      if (!Arg_blobname)
      {
          print "Not all required arguments are provided.\n";
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
            if ($retarray[0] eq "R")
            {
               $rr = $retarray[1];
               $bb = findBlob($hash1, $Arg_blobname, $rr);
               if ($bb > -1)
               {
                  $bpath = $hash1->{ReleasePackage}->[$rr]->{BlobList}->[0]->{Blob}->[$bb]->{BlobPath}->[0];
                  $pkgrepos_src = $ENV{'INSITE2_PKGREPOS_DIR'} . $bpath;
 
                  if (-d $pkgrepos_src)
                  {
                     $delcmd = "rmdir /s /q " . $pkgrepos_src;
                  }
                  else 
                  {
                     # delete the parent directory of the blob file.
                     $bpath = $hash1->{ReleasePackage}->[$rr]->{PkgName}->[0] . "\\";
                     $bpath .= $hash1->{ReleasePackage}->[$rr]->{BlobList}->[0]->{Blob}->[$bb]->{BlobName}->[0];
                     $pkgrepos_src = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $bpath;

                     $delcmd = "rmdir /s /q " . $pkgrepos_src;
                  }

                  print "$delcmd\n";
                  `$delcmd`;

                  $hash1->{ReleasePackage}->[$rr]->{BlobList}->[0]->{Blob}->[$bb]="";

                  writeXML($hash1);
                  updateIndexMD5();

                  print "removed blob";
                  exit 0;
               }
               else
               {
                  print "Blob $Arg_blobname could not be found.\n";
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
}
else
{
   exit 1;
}
