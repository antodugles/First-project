$path = $ENV{'INSITE2_HOME'} . "\\Questra\\cfgapi-lib.pl";
require $path;

$usage = "TKRemCfgProperty -propname=<pname> [-h]\n";

$usage .= ": deletes the specified configuration property value.\n";
$usage .= "    -propname=<pname>     name of configuration property.\n";
$usage .= "    -h shows usage\n";

if (processArgs($usage, 4)){
      if ($Arg_helpflag)
      {
          # help was requested.  Exit here.
          exit 0;
      }

      if (!$Arg_propname)
      {
          print "Property name must be specified.\n";
          print "$usage\n";
          exit 1;
      }

      if (!(remCfgProp($Arg_propname)))
      {
          print "Delete property failed.\n";
          exit 1;
      }

      exit 0;
}
else
{
      exit 1;
}
