$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";

require $path;

$usage = "PAgetCurrentRelease [-pkgtype=<ptype>][-pkgname | -revnum][-h]\n";
$usage = " : Retrieves the currently installed release package.\n"; 
$usage .= "  -pkgtype=<ptype> search releases of type <ptype>\n";
$usage .= "  -pkgname return pkg name\n";
$usage .= "  -revnum return pkg revnum\n";
$usage .= "  -h shows usage";

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

          $currpkg = "";
          $retpkg = -1;
          if ($Arg_pkgtype)
          {
              $currpkg = processInstallList($hash1, 22, $Arg_pkgtype);
          }
          else
          {
              $currpkg = processInstallList($hash1, 22);
          }

          if ($currpkg)
          {
              @retarray = findHashPackages($hash1, $currpkg);
              if ($#retarray > 1)
              {
                 $retpkg = $retarray[1];
              }
          }

          if ($retpkg > -1)
          {
             if ($Arg_pkgnameflag)
             {
                $retval = $hash1->{ReleasePackage}->[$retpkg]->{PkgName}->[0];
             }
             elsif ($Arg_revnumflag)
             {
                $retval = $hash1->{ReleasePackage}->[$retpkg]->{RevNum}->[0];
             }
             else
             {
                $attrval = $hash1->{ReleasePackage}->[$retpkg]->{RepositoryPath}->[0];
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
