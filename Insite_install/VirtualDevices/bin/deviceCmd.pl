$path = $ENV{'INSITE2_ROOT_DIR'} . "\\virtuals\\bin\\vdapi-lib.pl";
require $path;

$usage = "VDeviceCmd [-xmlpath=<cmdpath> | -start | -stop | -applycfg] [-h]\n";
$usage .= ": Handles a docking protocol cmd file.\n";
$usage .= "   -xmlpath=<cmdpath>\n";
$usage .= "   -start    starts device agents.\n";
$usage .= "   -stop     stops device agents.\n";
$usage .= "   -applycfg applies new master sitemap settings.\n";
$usage .= "   -h shows usage\n";

$debug = 0;

if ($debug)
{
   logException("Started deviceCmd : $ARGV[0], $ARV[1].", "INFORMATION", 002);
}

if (processArgs($usage))
{
   if ($Arg_helpflag)
   {
      exit 0;
   }

   # Start docked device agents
   #
   if ($Arg_startflag)
   {
      $hashdata = readXML();

      startAgents($hashdata);
      exit 0;
   }

   # Stop docked device agents
   #
   elsif ($Arg_stopflag)
   {
      $hashdata = readXML();

      stopAgents($hashdata);
      exit 0;
   }

   # Apply connectivity and location sitemap updates to devices
   #
   elsif ($Arg_applyflag)
   {
      $hashdata = readXML();

      cfgAgents($hashdata);
      exit 0;
   }

   # A command file should be expected.
   #
   if (!$Arg_xmlpath)
   {
      logException( "Not all required arguments provided.", "ERROR", 668);
      print "Not all required arguments provided.\n";
      print "$usage\n";
      exit 1;
   }

   # Make sure the path is valid.
   #
   if (!(-e $Arg_xmlpath))
   {
      logException("Command file is not accessible.", "ERROR", 669);
      print "Command file is not accessible.\n";
      exit 1;
   }

   $cmdhash = readXML($Arg_xmlpath);
   $resppath = getResponsePath($Arg_xmlpath);

   $rmfilecmd = "del /Q \"$Arg_xmlpath\"";

   if ($debug)
   {
      logException("rmcmd: $rmfilecmd.", "INFORMATION", 556);
   }

   `$rmfilecmd`;

   $cmdstr = "";

   #  Determine the command in this file.
   #
   if ($#{$cmdhash->{Start}} > -1)
   {
      $phash = ();
      $phash = genStartRespHash();

      writeResponse($phash,$resppath);
      exit 0;
   }
   elsif ($#{$cmdhash->{Dock}} > -1)
   {
      $cmdstr = "DOCK";
   }
   elsif ($#{$cmdhash->{UnDock}} > -1)
   {
      $cmdstr = "UNDOCK";
   }
   elsif ($#{$cmdhash->{FileSync}} > -1)
   {
      $cmdstr = "FILESYNC";
   }
   elsif ($#{$cmdhash->{StartDeviceAgents}} > -1)
   {
      $cmdstr = "STARTDEVICEAGENTS";
   }
   elsif ($#{$cmdhash->{StopDeviceAgents}} > -1)
   {
      $cmdstr = "STOPDEVICEAGENTS";
   }
   elsif ($#{$cmdhash->{Stop}} > -1)
   {
      $cmdstr = "STOP";
   }
   elsif ($#{$cmdhash->{AddUpdate}} > -1)
   {
      $cmdstr = "ADDUP";
   }
   elsif ($#{$cmdhash->{ApplyConfig}} > -1)
   {
      $cmdstr = "APPLYCFG";
   }

   #
   #  We have the command, so submit to handler below.
   #

   print "CMD: $cmdstr\n";
   if ($debug)
   {
      logException("CMD: $cmdstr.", "INFORMATION", 444);
   }

   if ($cmdstr eq "DOCK")
   {
      @docdata = getDockData($cmdhash);
      print "$docdata[0]\n";
      print "$docdata[1]\n";

      $hashdata = readXML();

      $retval = dockDevice($hashdata, $docdata[0], $docdata[1], $docdata[2], $docdata[3], $docdata[4]);
      print "retval: $retval\n";

      @fdata = getFileData($cmdhash, 1);
      print "$fdata[0]\n";
      print "$fdata[1]\n";
      print "$fdata[2]\n";
      print "$fdata[3]\n";
      print "$fdata[4]\n";
      fileHandler($hashdata, @fdata);

      $dhash = ();
      $dhash = genDockRespHash($hashdata, @docdata, @fdata);

      writeResponse($dhash, $resppath);
   }
   elsif ($cmdstr eq "UNDOCK")
   {
      @udocdata = getUnDockData($cmdhash);
      print "$udocdata[0]\n"; 
      print "$udocdata[1]\n"; 

      $hashdata = readXML();
      $retval = undockDevice($hashdata, $udocdata[0], $udocdata[1]);

      print "retval: $retval\n";
   }
   elsif ($cmdstr eq "FILESYNC")
   {
      @fdata = getFileData($cmdhash, 2);
      print "$fdata[0]\n";
      print "$fdata[1]\n";
      print "$fdata[2]\n";
      print "$fdata[3]\n";
      print "$fdata[4]\n";

      $hashdata = readXML();
      fileHandler($hashdata, @fdata);

      $fhash = ();
      $fhash = genFilesRespHash(@fdata);

      writeResponse($fhash, $resppath);
   }
   elsif ($cmdstr eq "ADDUP")
   {
      @revdata = getNewUpdateData($cmdhash);

      $hashdata = readXML();
      handleUpdateCmd($hashdata, @revdata);

      $fhash = ();
      $fhash = genAddUpdateRespHash(@revdata);

      writeResponse($fhash, $resppath);
   }
   elsif ($cmdstr eq "STARTDEVICEAGENTS")
   {
      $hashdata = readXML();
      startAgents($hashdata);
   }
   elsif (($cmdstr eq "STOPDEVICEAGENTS") || ($cmdstr eq "STOP"))
   {
      $hashdata = readXML();
      stopAgents($hashdata, $resppath);
   }
   elsif ($cmdstr eq "APPLYCFG")
   {
      $hashdata = readXML();
      cfgAgents($hashdata);
   }
}
else
{
   logException("Error parsing arguements.", "ERROR", 671);
   exit 1;
}

if ($debug)
{
   logException("Normal completion.", "INFORMATION", 001);
}
exit 0;
