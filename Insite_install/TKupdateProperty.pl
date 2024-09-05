$path = $ENV{'INSITE2_HOME'} . "\\Questra\\cfgapi-lib.pl";
require $path;

$usage = "TKUpdateProperty -propname=<pname> -propvalue=<pvalue> [-gencfg] [-restart] [-h]\n";

$usage .= ": updates the specified registration property value in agent config.\n";
$usage .= "    -propname=<pname>     name of configuration property.\n";
$usage .= "    -propvalue=<pvalue>   value of configuration property.\n";
$usage .= "    -gencfg               regens the agent config files.\n";
$usage .= "    -restart              restarts the agent service, if necessary.\n";
$usage .= "    -h shows usage\n";

if (processArgs($usage, 4)){
      if ($Arg_helpflag)
      {
          # help was requested.  Exit here.
          exit 0;
      }

      if ((!$Arg_gencfgflag) && (!(($Arg_propname) && ($Arg_propvalue))))
      {
          print "Property name and value or gencfg flag must be specified.\n";
          print "$usage\n";
          exit 1;
      }


      if ($Arg_propname)
      {
        # first, find the sitemap tag within the template for the given property.
        #
        $tempath = $ENV{'INSITE2_DATA_DIR'} . "\\etc\\templates\\qsa\\qsaconfig.xml";
        if (-e $tempath)
        {
          open(TEMFILE, $tempath);
          @TemLines = <TEMFILE>;
          chop(@TemLines);
          close(TEMFILE);

          $tagline = "";

          for $a ( 0..$#TemLines )
          {
             if ((@TemLines[$a] =~ /Property/) && (@TemLines[$a] =~ /$Arg_propname/))
             {
                $tagline = @TemLines[$a];
             }
          }

          if ($tagline ne "")
          {

             @prts=split(/\"/,$tagline);
             $reptag = @prts[3];
          }


          # Found the sitemap tag to update.  Check the presence of the locked
          # file.        
          if ($reptag ne "")
          {
             $roll = int(rand(3));
             sleep $roll;

             my $master = 0;
             $sitepath = $ENV{'INSITE2_DATA_DIR'} . "\\etc\\sitemap.xml";
             $lockpath = $sitepath . ".locked";

             # If the wait flag was provided, loop up to 10 seconds waiting for
             # the locked file to disappear.  If no wait flag and the locked file
             # exists, just exit now.
             #
             if (-e $sitepath)
             {
                for my $nn (0..10)
                {
                   if (!(-e $lockpath))
                   {

                      # grab control immediately by generating a new
                      # locked file.
                      #
                      open(LOCK, ">$lockpath");

                      select(LOCK);
                      print "locked\n";
                      close(LOCK);
                      select(STDOUT);
                      
                      $master = 1;
                   }

                   if (($master) || (! $Arg_waitflag))
                   {
                      last;
                   }
                   sleep 1;
                }

                if (!$master)
                {
                   print "locked out of sitemap.xml update.\n";
                   exit 1;
                }

#
#   Update the master sitemap.xml file with the new property value.
#
                open(SITEFILE, $sitepath);
                @SiteLines = <SITEFILE>;
                chop(@SiteLines);
                close(SITEFILE);

                $mypid = $$;
                $newpath = $ENV{'INSITE2_DATA_DIR'} . "\\etc\\sitemap" . "$mypid" . ".xml.new";
                open(OUT, ">$newpath");

                select(OUT);

                for $b (0..$#SiteLines)
                {
                   $siteln = @SiteLines[$b];
                   if (($siteln =~ /symbol/) && ($siteln =~ /$reptag/))
                   {
                       $newln = "            <text symbol=\"" . $reptag;
                       $newln .= "\">$Arg_propvalue</text>";
                       print "$newln\n";
                   }
                   else 
                   {
                       print "$siteln\n";
                   }
                }
                close(OUT);

                rename($newpath, $sitepath);

#
# There are situations where a MergeSiteMap.xml will execute after the property
# update, overwriting the new values.  Update the AgentConfig as well with the new
# property values.

                $cfgpath = $ENV{'INSITE2_HOME'} . "\\Questra\\AgentConfig.xml";
                open(CFGFILE, $cfgpath);
                @CfgLines = <CFGFILE>;
                chop(@CfgLines);
                close(CFGFILE);

                $newcfg = $ENV{'INSITE2_HOME'} . "\\Questra\\AgentConfig" . "$mypid" . ".xml.new";
                open(CFG, ">$newcfg");
         
                select(CFG);

                for $b (0..$#CfgLines)
                {
                   $siteln = @CfgLines[$b];
                   if (($siteln =~ /symbol/) && ($siteln =~ /$reptag/))
                   {
                       $newln = "            <text symbol=\"" . $reptag;
                       $newln .= "\">$Arg_propvalue</text>";
                       print "$newln\n";
                   }
                   else 
                   {
                       print "$siteln\n";
                   }
                }
                close(CFG);

                rename($newcfg, $cfgpath);
                select(STDOUT);

             }
          }
        }
      }

      if ($Arg_gencfgflag)
      {
        $gencfgcmd = "call \"" . $ENV{'INSITE2_ROOT_DIR'} . "\\bin\\gencfg.cmd\"";
        $gencfgcmd .= " -template \"" . $ENV{'INSITE2_DATA_DIR'};
        $gencfgcmd .= "\\etc\\templates\\qsa\" -cfgdir \"";
        $gencfgcmd .= $ENV{'INSITE2_DATA_DIR'} . "\\etc\"";

        `$gencfgcmd`;
      }

      # Finally, release control by deleting the locked file.
      #

      $delcmd = "del /Q \"$lockpath\"";
      `$delcmd`;

      if ($Arg_restartflag)
      {
        $rescmd = "\"" . $ENV{'INSITE2_HOME'} . "\\Questra\\QSAManControl.bat\"";
        `$rescmd`;
      }

      exit 0;
}
else
{
      print "Invalid Command-line Arguments\n";
      exit 1;
}
