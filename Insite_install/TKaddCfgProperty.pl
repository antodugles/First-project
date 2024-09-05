$path = $ENV{'INSITE2_HOME'} . "\\Questra\\cfgapi-lib.pl";
require $path;

$usage = "TKaddCfgProperty -propname=<pname> -propvalue=<pvalue> [-h]\n";

$usage .= ": Adds or updates a configuration property value.\n";
$usage .= "    -propname=<pname>     name of configuration property.\n";
$usage .= "    -propvalue=<pvalue>   value of configuration property.\n";
$usage .= "    -h shows usage\n";

if (processArgs($usage, 4)){
      if ($Arg_helpflag)
      {
          # help was requested.  Exit here.
          exit 0;
      }

      if ((!$Arg_propname) || (!$Arg_propvalue))
      {
          print "Both property name and property value must be specified.\n";
          print "$usage\n";
          exit 1;
      }

      if (!(writeCfgProp($Arg_propname, $Arg_propvalue)))
      {
          print "Write property failed.\n";
          exit 1;
      }

      exit 0;
}
else
{
      exit 1;
}
