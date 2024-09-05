
$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";
require $path;

$usage = "PAaddBlob -blobpath=<bpath> -blobname=<bname> [[-pkgname=<pname>] | [-revnum=<rnum> -pkgtype=<ptype>]] [-h]\n";
$usage .= " : Stores an auxialiary file or directory as a package attribute.\n";
$usage .= "    -blobpath=<bpath> path of source blob file/directory.\n";
$usage .= "    -blobname=<bname> reference for stored blob element.\n";
$usage .= "    -pkgname=<pname> pkg name of parent release package.\n";
$usage .= "    -revnum=<rnum> -pkgtype=<ptype> revision and type of parent release.\n";
$usage .= "    -h shows usage\n";

if (processArgs($usage, 3)){
   if (checkIndexMD5())
   {
      if ($Arg_helpflag)
      {
          # help was requested.  Exit here.
          exit 0;
      }
      elsif ((!$Arg_blobname) || (!$Arg_blobpath))
      {
          print "Not all required arguments are provided.\n";
          print "$usage\n";
          exit 1;
      }

      if ((!$Arg_pkgname) && (!(($Arg_revnum) && ($Arg_pkgtype))))
      {
          print "Not all required arguments are provided.\n";
          print "$usage\n";
          exit 1;
      }

      if (!(-e $Arg_blobpath))
      {
          print "Blob path is not accessible by the API.\n";
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

               # check if blob currently exists.
               #
               $chkbb = findBlob($hash1, $Arg_blobname, $rr);
               if ($chkbb > -1)
               {
                  print "Blob $Arg_blobname already exists for the given release.\n"; 
                  exit 1;
               }
               
               $bb = $retarray[4];
               $hash1->{ReleasePackage}->[$rr]->{BlobList}->[0]->{Blob}->[$bb]->{BlobName}->[0] = $Arg_blobname;

               $pkgrepos_dest = $hash1->{ReleasePackage}->[$rr]->{PkgName}->[0];
               $filenm = extractFileDir($Arg_blobpath);

               if (-d $Arg_blobpath)
               {
                  $pkgrepos_dest .= "\\" . $filenm;
  
                  $mkdircmd = "mkdir \"" . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pkgrepos_dest . "\"";
                  `$mkdircmd`;

                  $copycmd = "xcopy \/y \/q \/e \"$Arg_blobpath\" \"" . $ENV{'INSITE2_PKGREPOS_DIR'} . ":\\" . $pkgrepos_dest . "\"";
               }
               else
               {
                  $pkgrepos_dest .= "\\" . $Arg_blobname;
                  
                  $mkdircmd = "mkdir \"" . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pkgrepos_dest . "\"";
                  `$mkdircmd`;

                  $pkgrepos_dest .= "\\" . $filenm;
                  $copycmd = "copy \/y \"$Arg_blobpath\" \"" . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pkgrepos_dest . "\"";
               }

               `$copycmd`;

               $hash1->{ReleasePackage}->[$rr]->{BlobList}->[0]->{Blob}->[$bb]->{BlobPath}->[0] = $pkgrepos_dest;
               writeXML($hash1);
               updateIndexMD5();
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
   print "Added Blob";
   exit 0;
}
else
{
   exit 1;
}
