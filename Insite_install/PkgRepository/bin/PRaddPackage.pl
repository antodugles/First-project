$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";
require $path;

$usage = "PAaddPackage -pkgpath=<pkpath> -pkgname=<pname> -pkgtype=<ptype> -filetype=<ftype> -revnum=<rnum> [-parentpkg=<parpkg>] [-h]\n";
$usage .= ": Adds a package to the Package Repository.\n";
$usage .= "    -pkgpath=<pkpath>     path of source package file.\n";
$usage .= "    -pkgname=<pname>      unique reference name of package.\n";
$usage .= "    -pkgtype=<ptype>      type of release or patch package.\n";
$usage .= "    -filetype=<ftype>     file format - ZIP, JAR, etc.\n";
$usage .= "    -revnum=<rnum>        revision of package (<major rev #>.<minor rev #>.<patch rev #)\n";
$usage .= "    -parentpkg=<parpkg>   explicit assignment of parent release package (for patches)\n";
$usage .= "    -h shows usage\n";

if (processArgs($usage, 1)){
   if (checkIndexMD5())
   {
      if ($Arg_helpflag)
      {
          # help was requested.  Exit here.
          exit 0;
      }
      elsif ((!$Arg_pkgname) || (!$Arg_pkgtype) || (!$Arg_revnum) || (!$Arg_pkgpath) || (!Arg_filetype))
      {
          print "Not all required arguments are provided.\n";
          print "$usage\n";
          exit 1;
      }

      if (!(-e $Arg_pkgpath))
      {
          print "Package path is not accessible by the API.\n";
          print "$usage\n";
          exit 1;
      }

      if ((!(validPkgType($Arg_pkgtype))) || (!(validRevNum($Arg_revnum))) || (!(validFileType($Arg_filetype))))
      {
          print "$usage\n";
          exit 1;
      }

      $hash1 = readXML();

      if ($hash1)
      {
         # first, check if the pkgname already exists.
         @retarray = findHashPackages($hash1, $Arg_pkgname);
         if ($#retarray > 1)
         {
            print "The package name $Arg_pkgname already exists in the Package Repository.\n";
            exit 1;
         }

         # a release pkg...
         if (($Arg_pkgtype eq "AP") || ($Arg_pkgtype eq "OP") || ($Arg_pkgtype eq "SV"))
         {
            $so = $hash1->{NextStoreCtr}->[0];

            $nn = nextReleaseIndex($hash1);
            $hash1->{ReleasePackage}->[$nn]->{PkgName}->[0] = $Arg_pkgname;
            $hash1->{ReleasePackage}->[$nn]->{PkgType}->[0] = $Arg_pkgtype;
            $hash1->{ReleasePackage}->[$nn]->{RevNum}->[0] = $Arg_revnum;
            $hash1->{ReleasePackage}->[$nn]->{FileType}->[0] = $Arg_filetype;
            $hash1->{ReleasePackage}->[$nn]->{InstFlag}->[0] = "FALSE";
            $hash1->{ReleasePackage}->[$nn]->{InstallOrder}->[0] = "0";
            $hash1->{ReleasePackage}->[$nn]->{PendingFlag}->[0] = "FALSE";
            $hash1->{ReleasePackage}->[$nn]->{StoreOrder}->[0] = $so;
            $hash1->{ReleasePackage}->[$nn]->{BlobList}->[0] = "";
            $hash1->{ReleasePackage}->[$nn]->{PatchList}->[0] = "";

            $filenm = extractFileDir($Arg_pkgpath);
            $pkgrepos_dest = $Arg_pkgname . "\\" . $filenm;

            if (-d $Arg_pkgpath)
            {
                 $mkdircmd = "mkdir " . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pkgrepos_dest;
                 $copycmd = "xcopy \/y \/q \/e \"$Arg_pkgpath\" \"" . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pkgrepos_dest . "\"";
            }
            else
            {
	         $mkdircmd = "mkdir " . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $Arg_pkgname;
                 $copycmd = "copy \/y \"$Arg_pkgpath\" \"" . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pkgrepos_dest . "\"";
            }

            `$mkdircmd`;
            `$copycmd`;

            $hash1->{ReleasePackage}->[$nn]->{RepositoryPath}->[0] = $pkgrepos_dest;

            $hash1->{NextStoreCtr}->[0] = $so + 1;
            writeXML($hash1);
            updateIndexMD5();
         }
         else
         {
            if ($Arg_parentpkg) {
               @retarray = findHashPackages($hash1, $Arg_parentpkg);
            }
            else {
               @retarray = findparentbyrev($hash1, $Arg_revnum, $Arg_pkgtype);
            }

            if ($#retarray > 1)
            {
               if ($retarray[0] eq "P")
               {
                  exit 1;
               }

               $so = $hash1->{NextStoreCtr}->[0];

               $rr = $retarray[1];
               $pp = $retarray[3];

               $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{PkgName}->[0] = $Arg_pkgname;
               $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{PatchType}->[0] = $Arg_pkgtype;
               $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{RevNum}->[0] = $Arg_revnum;
               $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{FileType}->[0] = $Arg_filetype;
               $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{InstFlag}->[0] = "FALSE";
               $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{InstallOrder}->[0] = "0";
               $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{PendingFlag}->[0] = "FALSE";
               $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{StoreOrder}->[0] = $so;
               
               $pkgrepos_dest = $hash1->{ReleasePackage}->[$rr]->{PkgName}->[0];
               $filenm = extractFileDir($Arg_pkgpath);


               $newdir = $pkgrepos_dest . "\\" . $Arg_pkgname;
               $pkgrepos_dest .= "\\" . $Arg_pkgname . "\\" . $filenm;

               # $mkdircmd = "mkdir " . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $newdir;
               # `$mkdircmd`;

               # $copycmd = "copy \/y " . $Arg_pkgpath . " " . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pkgrepos_dest;
               # `$copycmd`;

               if (-d $Arg_pkgpath)
               {
                  $mkdircmd = "mkdir " . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pkgrepos_dest;
                  $copycmd = "xcopy \/y \/q \/e \"$Arg_pkgpath\" \"" . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pkgrepos_dest . "\"";
               }
               else
               {
	          $mkdircmd = "mkdir " . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $newdir;
                  $copycmd = "copy \/y \"$Arg_pkgpath\" \"" . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $pkgrepos_dest . "\"";
               }

               `$mkdircmd`;
               `$copycmd`;

               $hash1->{ReleasePackage}->[$rr]->{PatchList}->[0]->{PatchPackage}->[$pp]->{RepositoryPath}->[0] = $pkgrepos_dest;

               $hash1->{NextStoreCtr}->[0] = $so + 1;
               writeXML($hash1);
               updateIndexMD5();
            }
            else
            {
               print "No parent pkg found for $Arg_pkgname.\n";
               exit 1;
            }
         }
      }
      else {
         print "Corrupted Pkg Repository index.\n";
         exit 1;
      }
   }
   else
   {
      exit 1;
   }
   print "added pkg $Arg_pkgname.\n";
   exit 0;
}
else
{
   print "Invalid command line arguments.\n";
   exit 1;
}
