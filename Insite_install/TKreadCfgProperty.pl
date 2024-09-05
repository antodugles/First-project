$path = $ENV{'INSITE2_HOME'} . "\\Questra\\cfgapi-lib.pl";
require $path;

$usage = "TKReadCfgProperty -propname=<pname> [-h]\n";

$usage .= ": returns the specified configuration property value.\n";
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

      $pval = readCfgProp($Arg_propname);
      print "$pval\n";

      exit 0;
}
else
{
      exit 1;
}
