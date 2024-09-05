
$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";

require $path;

$usage = "PAgetPendingRelease [-pkgtype=<ptype>][-pkgname | -revnum][-h]\n";
$usage .= "  :Retrieves path to latest release package with pending flag set.\n";
$usage .= "      -pkgtype=<ptype> search releases of type <ptype>\n";
$usage .= "      -pkgname return pkg name\n";
$usage .= "      -revnum return pkg revnum\n";
$usage .= "      -h shows usage";

if (processArgs($usage, 2)){
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
          $maxpkg = -1;
          $retval = "";

          $pt = "AP";
          if ($Arg_pkgtype)
          {
              $pt = $Arg_pkgtype;
          }

          $maxpkg = findPendRelPtr($hash1, $pt);

          if ($maxpkg > -1)
          {
             if ($Arg_pkgnameflag)
             {
                $retval = $hash1->{ReleasePackage}->[$maxpkg]->{PkgName}->[0];
             }
             elsif ($Arg_revnumflag)
             {
                $retval = $hash1->{ReleasePackage}->[$maxpkg]->{RevNum}->[0];
             }
             else
             {
                $attrval = $hash1->{ReleasePackage}->[$maxpkg]->{RepositoryPath}->[0];
                $retval = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $attrval;
             }

             print "$retval";
             exit 0;

          }

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
