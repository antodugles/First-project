use Getopt::Long;
use XML::Simple;
use Data::Dumper;
use CookieMonster;

#----------------------------------------------------------------------------------------
#
# processArgs
#
# This subroutine processes the command-line arguments passed to the virtual
# device API scripts.  Based on the mode, the processArgs assigns global variables,
# performs arg validation, and returns a pass/fail.  If the argument list
# is invalid or -h(elp) is requested, the usage string is displayed.
#
# Usage: processArgs(usagestr, listmode)
#
# returns: 1 - successful argument processing
#          0 - argument list invalid
#
sub processArgs
{
   my $usageStr = @_[0];

       $retval=GetOptions("h"=>\$Arg_helpflag,
           "xmlpath=s"=>\$Arg_xmlpath,
           "start"=>\$Arg_startflag,
           "stop"=>\$Arg_stopflag,
           "applycfg"=>\$Arg_applyflag);

	 if ($Arg_helpflag) {
    	    if ($Arg_xmlpath) { 
              $Arg_helpflag = 0;
            }
         }
       

   if (!($retval) || ($Arg_helpflag))
   {   
      print "USAGE : " . $usageStr . "\n";
   }
   
   if ($retval)
   {
      return 1;
   }
  
   return 0;
}

#----------------------------------------------------------------------------------------
#
# readXML -
#
# This subroutine reads either the default virtual device index path
# or a provided path and places the XML data into an XML::Simple hash table.
# The hash table is searchable, update-able, and can be rewritten to a
# new updated index XML.
#
# readXML( [vindexPath] )
#
# returns      $hashdata: - hash data structure representing the XML content
#              null - could not read the XML content.
#
# optional reposPath provides an alternate index XML.
#
sub readXML
{
   my $vindexPath = @_[0];

   if ($vindexPath eq "")
   {
       $vindexPath = $ENV{'INSITE2_ROOT_DIR'} . "\\virtuals\\VirtualIndex.xml";
   }

   # print "Index path: $vindexPath.\n";
   my $xml = new XML::Simple;
   my $hashdata = eval { $xml->XMLin ($vindexPath, ForceArray=>1)};

   if ($@)
   {
      logException($@, "ERROR", 666);
   }

   # print Dumper($hashdata);
   return $hashdata;
}

#----------------------------------------------------------------------------------------
#
# Logs an event in the APPLICATION event log for a given type and error code.
#
#

sub logException
{
   local($errtext, $type, $errcode) = @_;

   # type is either ERROR, WARNING or INFORMATION
   # errcode is numeric ID

   $logcmd = "eventcreate \/T $type \/ID $errcode \/L APPLICATION \/SO VDeviceCmd \/D \"$errtext\"";
   `$logcmd`;

   return 1;
}

#----------------------------------------------------------------------------------------
#
# getFileData
#
#
sub getFileData
{
   local($myhash, $mymode) = @_;
   my @retarray = ();
   my $devtype = "";
   my $serialnum = "";

   if ($mymode eq 1)
   {
      $devtype = $myhash->{Dock}->[0]->{DeviceId}->[0]->{DeviceType}->[0];
      $serialnum = $myhash->{Dock}->[0]->{DeviceId}->[0]->{SerialNo}->[0];
      push(@retarray, $devtype);
      push(@retarray, $serialnum);

      for my $fd (@{$myhash->{Dock}->[0]->{FileList}->[0]->{File}})
      {
         push(@retarray, $fd->{Path});
      }
   }  

   else
   {
      $devtype = $myhash->{FileSync}->[0]->{DeviceId}->[0]->{DeviceType}->[0];
      $serialnum = $myhash->{FileSync}->[0]->{DeviceId}->[0]->{SerialNo}->[0];
      push(@retarray, $devtype);
      push(@retarray, $serialnum);

      for my $fs (@{$myhash->{FileSync}->[0]->{FileList}->[0]->{File}})
      {
         push(@retarray, $fs->{Path});
      }  
   }
   return @retarray;
}

#----------------------------------------------------------------------------------------
#
# getNewUpdateData
#
#
#
sub getNewUpdateData
{
   local($myhash) = @_;
   my @retarray = ();

   my $devtype = "";

   $devtype = $myhash->{AddUpdate}->[0]->{DeviceType}->[0];
   push(@retarray, $devtype);

   foreach my $rr (@{$myhash->{AddUpdate}->[0]->{NewRevisions}->[0]->{Revision}})
   {
      my @arr1 = ();
      push( @arr1, $rr->{ID});
      push( @arr1, $rr->{Type});
      push( @arr1, $rr->{Version});

      push( @arr1, $rr->{Path}->[0]->{Value});

      push @retarray, [ @arr1 ];
   }

   return @retarray;
   
}


#------------------------------------------------------------------------------------------
#
# getDirOnly
#
#
sub getDirOnly
{
   local($fullpath) = @_;

   $fullpath =~ s/\//\\/g;
   my @parray = split(/\\/, $fullpath);

   my $numparts = ($#parray - 1);
   my $nn = 0;
   my $endpath = "";

   for $nn (0..$numparts)
   {
      if ($endpath ne "")
      {
         $endpath .= "\\";
      }
      $endpath .= $parray[$nn];
   }

   return $endpath;
}


#----------------------------------------------------------------------------------------
#
# getResponsePath
#
# method also deletes the previous 
#
sub getResponsePath
{
   local($fullpath) = @_;

   $fullpath =~ s/\//\\/g;
   my @parray = split(/\\/, $fullpath);

   my $numparts = ($#parray - 1);
   my $nn = 0;
   my $endpath = "";

   for $nn (0..$numparts)
   {
      if ($endpath ne "")
      {
         $endpath .= "\\";
      }
      $endpath .= $parray[$nn];
   }

   $endpath .= "\\Response.xml";

   if (-e $endpath)
   {
      $rmfilecmd = "del /Q \"$endpath\"";
      `$rmfilecmd`;
   }

   return $endpath;
}


#----------------------------------------------------------------------------------------
#
# fileHandler
#
#
sub fileHandler
{
   local($myhash, @fdata) = @_;

   my $devtype = getAssetType($myhash, $fdata[0]);
   my $serialnum = $fdata[1];
   my $filenm = "";

   my $devname = "";

   my @retarray = ();
   @retarray = findHashDevices($myhash, $devtype, $serialnum);

   if ($#retarray > 1)
   {
      $devname = @retarray[1];
      my $ff = 0;
      my $cpcmd = "";
      my $destfile = "";
      for $ff (2..$#fdata)
      {
         if (-e $fdata[$ff])
         {
            $destfile = extractFileDir($fdata[$ff]);
            $cpcmd = "copy \"$fdata[$ff]\" \"%INSITE2_ROOT_DIR%\\virtuals\\logs\\$devname\\$destfile\"";
            print "$cpcmd\n";

            `$cpcmd`;
         }
      }
   }
}


#----------------------------------------------------------------------------------------
#
# getUnDockData
#
#
sub getUnDockData
{
   local($myhash) = @_;

   my @retarray = ();
   my $devtype = "";
   my $serialnum = "";

   $devtype = $myhash->{UnDock}->[0]->{DeviceId}->[0]->{DeviceType}->[0];
   $serialnum = $myhash->{UnDock}->[0]->{DeviceId}->[0]->{SerialNo}->[0];

   push(@retarray,$devtype);
   push(@retarray,$serialnum);

   return @retarray;
}


#----------------------------------------------------------------------------------------
#
# getSvcVersion
#
#
sub getSvcVersion
{
   my $pformstr = "";
   my $pformlab = "";
   my $pformver = "";
   my $filepform = $ENV{'INSITE2_HOME'} . "\\SVCPFORMVERSION";

   if (-e $filepform)
   {
      open(PFFILE, $filepform);

      @pflines=<PFFILE>;
      chop(@pflines);
      close(PFFILE);

      ($pformlab, $pformstr) = split(/:/,@pflines[0]);
      $pformstr =~ s/ //g;

      ($pformlab, $pformver) = split(/V/,$pformstr);

      if ($pformver eq "")
      {
         $pformver = $pformstr;
      }
   }

   return $pformver;
}


#----------------------------------------------------------------------------------------
#
# getDockData
#
#
sub getDockData
{
   local($myhash) = @_;

   my @retarray = ();

   my $devtype = "";
   my $serialnum = "";
   my $aprev = "0.0.0";
   my $oprev = "0.0.0";
   my $svrev = "";

   $devtype = $myhash->{Dock}->[0]->{DeviceId}->[0]->{DeviceType}->[0];
   $serialnum = $myhash->{Dock}->[0]->{DeviceId}->[0]->{SerialNo}->[0];

   foreach my $rr (@{$myhash->{Dock}->[0]->{CurrentRevisions}->[0]->{Revision}})
   {
      if ($rr->{Type} eq "AP")
      {
         $aprev = $rr->{Version};
      }
      elsif ($rr->{Type} eq "OP")
      {
         $oprev = $rr->{Version};
      }
      elsif ($rr->{Type} eq "SV")
      {
         $svrev = $rr->{Version};
      }
   }

   if ($svrev eq "")
   {
      $svrev = getSvcVersion();
   }

   push(@retarray,$devtype);
   push(@retarray,$serialnum);
   push(@retarray,$aprev);
   push(@retarray,$oprev);
   push(@retarray,$svrev);

   return @retarray;
}


#---------------------------------------------------------------------------------------
#
# genStartRespHash
#
sub genStartRespHash
{
  my $rhash = ();

  $rhash->{Ready}->[0] = ();

  return $rhash;
}


#----------------------------------------------------------------------------------------
#
# genAddUpdateRespHash
#
sub genAddUpdateRespHash
{
   local(@nuarr) = @_;

   my $rhash = ();

   $rhash->{AvailableUpdates} = ();
   $rhash->{AvailableUpdates}->[0]->{DeviceType}->[0] = $nuarr[0];

   my $lstctr = 0;

   for $aa (1..$#nuarr)
   {
        $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0]->{Revision}->[$lstctr]->{ID} = $nuarr[$aa][0];
        $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0]->{Revision}->[$lstctr]->{Type} = $nuarr[$aa][1];
        $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0]->{Revision}->[$lstctr]->{Version} = $nuarr[$aa][2];
        $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0]->{Revision}->[$lstctr]->{Path} = ();
        $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0]->{Revision}->[$lstctr]->{Path}->[0]->{Value} = $nuarr[$aa][3];
     
        $lstctr++;
   }

   return $rhash;

}


#----------------------------------------------------------------------------------------
#
# genFilesRespHash
#
#
sub genFilesRespHash
{
  local(@fdata) = @_;

  my $rhash = ();

  $rhash->{FilesTransferred} = ();

  $rhash->{FilesTransferred}->[0]->{DeviceId} = ();
  $rhash->{FilesTransferred}->[0]->{DeviceId}->[0]->{DeviceType}->[0] = $fdata[0];
  $rhash->{FilesTransferred}->[0]->{DeviceId}->[0]->{SerialNo}->[0] = $fdata[1];
  
  $rhash->{FilesTransferred}->[0]->{FileList}->[0] = ();

  my $datype = "LOG";
  my $lstctr = 0;
  for $ff (2..$#fdata)
  {
     $rhash->{FilesTransferred}->[0]->{FileList}->[0]->{File}->[$lstctr]->{Type} = $datype;
     $rhash->{FilesTransferred}->[0]->{FileList}->[0]->{File}->[$lstctr]->{Value} = $fdata[$ff];
     $lstctr++;
  }
  return $rhash;
}

#--------------------------------------------------------------------------------------
#
# getAvailUpdates
#
#
sub getAvailUpdates
{
   local($myhash, $dtype) = @_;

   my $devtype = getAssetType($myhash, $dtype);
   my @ulist = ();

   foreach my $mm (@{$myhash->{UpdateList}})
   {
      if ($mm->{type} eq $devtype)
      {
          foreach my $aa (@{$mm->{Package}})
          {
              my @inarr = ();
              push(@inarr, $aa->{ID});
              push(@inarr, $aa->{Type});
              push(@inarr, $aa->{Version});
              push(@inarr, $aa->{Path}->[0]->{Value});

              push @ulist, [ @inarr ];
          }
      }
   }

   return @ulist;
}


#---------------------------------------------------------------------------------------
#
# genDockRespHash
#
#
sub genDockRespHash
{

  local($myhash, @ddata) = @_;
  my $rhash = ();
  my @newvers = ();

  $rhash->{AvailableUpdates} = ();
  $rhash->{AvailableUpdates}->[0]->{DeviceId} = ();
  $rhash->{AvailableUpdates}->[0]->{DeviceId}->[0]->{DeviceType}->[0] = $ddata[0];
  $rhash->{AvailableUpdates}->[0]->{DeviceId}->[0]->{SerialNo}->[0] = $ddata[1];

  # see if there are any SW updates available for this device type.
  #
  @newvers = getAvailUpdates($myhash, $ddata[0]);

  $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0] = ();

  my $lstctr = 0;
  for my $aa (0..$#newvers)
  {
     $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0]->{Revision}->[$lstctr]->{ID} = $newvers[$aa][0];
     $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0]->{Revision}->[$lstctr]->{Type} = $newvers[$aa][1];
     $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0]->{Revision}->[$lstctr]->{Version} = $newvers[$aa][2];
     $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0]->{Revision}->[$lstctr]->{Path} = ();
     $rhash->{AvailableUpdates}->[0]->{NewRevisions}->[0]->{Revision}->[$lstctr]->{Path}->[0]->{Value} = $newvers[$aa][3];
     
     $lstctr++;
  }

  # generate the filestransferred element for the dock cmd.
  #

  if ($#ddata > 5)
  {
     $rhash->{FilesTransferred} = ();
     $rhash->{FilesTransferred}->[0]->{DeviceId} = ();
     $rhash->{FilesTransferred}->[0]->{DeviceId}->[0]->{DeviceType}->[0] = $ddata[0];
     $rhash->{FilesTransferred}->[0]->{DeviceId}->[0]->{SerialNo}->[0] = $ddata[1];
     $rhash->{FilesTransferred}->[0]->{FileList}->[0] = ();

     my $datype = "LOG";
     $lstctr = 0;
     for $ff (7..$#ddata)
     {
        $rhash->{FilesTransferred}->[0]->{FileList}->[0]->{File}->[$lstctr]->{Type} = $datype;
        $rhash->{FilesTransferred}->[0]->{FileList}->[0]->{File}->[$lstctr]->{Value} = $ddata[$ff];
        $lstctr++;
     }
  }

  return $rhash;
}


#----------------------------------------------------------------------------------------
#
# undockDevice
#
#
sub undockDevice
{
   local($myhash, $dtype, $serialnum) = @_;

   my $devtype = getAssetType($myhash, $dtype);
   my $nn = 0;
   if ($myhash)
   {
      my @retarray = ();
      @retarray = findHashDevices($myhash, $devtype, $serialnum);

      if ($#retarray > 1)
      {
         $nn = $retarray[0];
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Docked}->[0] = "FALSE";

         writeXML($myhash);

         stopService($retarray[3]);

         return 1;
      }
   }
}


#----------------------------------------------------------------------------------------
#
# dockDevice
#
#
sub dockDevice
{
   local($myhash, $dtype, $serialnum, $aprev, $oprev, $srvrev) = @_; 
   my $nn = 0;
 
   if ($myhash)
   {

      # translation from docking device type to Questra asset type.
      my $devtype = getAssetType($hashdata, $dtype);
      if ($devtype eq "")
      {
         # invalid device type
         return 0;
      }

      my $prefix = findPrefix($hashdata, $devtype);
      if ($prefix eq "")
      {
         # invalid device type
         return 0;
      }

      my @retarray = ();
      @retarray = findHashDevices($myhash, $devtype, $serialnum);

      if ($#retarray > 1)
      {
         # check if the revisions have changed since last device dock.
         if (($aprev eq $retarray[7]) && ($oprev eq $retarray[8]) && ($srvrev eq $retarray[9]))
         {
            # Just start service.  Nothing changes in config.
            $nn = $retarray[0];
            $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Docked}->[0] = "TRUE";

            writeXML($myhash);

            # start service only if main qsa service is running.
            if (isServiceRunning("qsa"))
            {
               startService($retarray[3]);
            }
            return 3;
         }
         else
         {
            # Update record in index and writeXML.
            $nn = $retarray[0];
            $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[0]->{type} = "AP";
            $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[0]->{content} = "$aprev";
            $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[1]->{type} = "OP";
            $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[1]->{content} = "$oprev";
            $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[2]->{type} = "SV";
            $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[2]->{content} = "$srvrev";
            $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Docked}->[0] = "TRUE";

            writeXML($myhash);

            GenDockedSiteMap($retarray[1], $devtype, $aprev, $oprev, $srvrev, $retarray[3],
                  $retarray[5], $retarray[6]);

            # start service if main agent is running.  service already exists.
            if (isServiceRunning("qsa"))
            {
               startService($retarray[3]);
            }

            return 2;
         }
      }
      else
      {
         $nn = getNextIndex($myhash);
         my $devname = $prefix . "_" . $serialnum;

         my $iport = getNextPortNoInd($myhash, "IPC");
         my $iportno = $myhash->{NextPortNo}->[$iport]->{content};

         my $hport = getNextPortNoInd($myhash, "HTTP");
         my $hportno = $myhash->{NextPortNo}->[$hport]->{content};

         my $saveiport = $iportno;
         my $savehport = $hportno;

         my $servicenm = $myhash->{NextSvcName}->[0];

         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{DeviceType}->[0] = $devtype;
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{DeviceId}->[0] = $devname;
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{SerialNumber}->[0] = $serialnum;
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{SvcName}->[0] = $servicenm;
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[0]->{type} = "AP";
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[0]->{content} = "$aprev";
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[1]->{type} = "OP";
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[1]->{content} = "$oprev";
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[2]->{type} = "SV";
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Revision}->[2]->{content} = "$srvrev";
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{PortNo}->[0]->{content} = $iportno;
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{PortNo}->[0]->{type} = "IPC";
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{PortNo}->[1]->{content} = $hportno;
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{PortNo}->[1]->{type} = "HTTP";
         $myhash->{DeviceList}->[0]->{Device}->[$nn]->{Docked}->[0] = "TRUE";

         # bump the counters.
         $iportno++;
         $hportno++;

         $myhash->{NextSvcName}->[0] = buildNextSvcName($servicenm);
         $myhash->{NextPortNo}->[$iport]->{content} = $iportno++;
         $myhash->{NextPortNo}->[$hport]->{content} = $hportno++;

         writeXML($myhash);

         GenDockedSiteMap($devname, $devtype, $aprev, $oprev, $srvrev, $servicenm,
               $saveiport, $savehport);

         GenDeviceLogSpace($devname);

         # create and start service.
         createService($servicenm);

         if (isServiceRunning("qsa"))
         {
            startService($servicenm);
         }
         return 1;
      }
   }
   return 0;
}

#----------------------------------------------------------------------------------------
#
#  GenDeviceLogSpace
#
sub GenDeviceLogSpace
{
   local($devicenm) = @_;

   $logspace = $ENV{'INSITE2_ROOT_DIR'} . "\\virtuals\\logs\\$devicenm";
   if (-e $logspace)
   {
      $rmdircmd = "rmdir /s /q \"$logspace\"";
      `$rmdircmd`;
   }

   $mkdircmd = "mkdir \"$logspace\"";
   `$mkdircmd`;
}

#----------------------------------------------------------------------------------------
#
#  GenDockedSiteMap
#
sub GenDockedSiteMap
{
   local($devname, $devtype, $aprev, $oprev, $srvrev, $svcname, $ipport, $httpport) = @_;

   $newpathdir = $ENV{'INSITE2_ROOT_DIR'} . "\\virtuals\\$svcname";
   if (-e $newpathdir)
   {
      $rmdircmd = "rmdir /s /q \"$newpathdir\"";
      `$rmdircmd`;
   }


   $mkdircmd = "mkdir \"$newpathdir\"";
   `$mkdircmd`;

   $etcpath = $ENV{'INSITE2_ROOT_DIR'} . "\\virtuals\\basetemplates";
   $cpcmd = "xcopy \/y \/q \/t \"$etcpath\"";
   $cpcmd .= " \"$newpathdir\"";
   `$cpcmd`;


   $sitepath = $ENV{'INSITE2_ROOT_DIR'} . "\\virtuals\\sitemaps\\$devtype\\sitemap.xml";
   open(SITEFILE, $sitepath);
   @SiteLines = <SITEFILE>;
   chop(@SiteLines);
   close(SITEFILE);

   $newpath = $newpathdir . "\\sitemap.xml";
   open(OUT, ">$newpath");

   select(OUT);

   for $b (0..$#SiteLines)
   {
      $siteln = @SiteLines[$b];
      $siteln =~ s/__DEVNAME__/$devname/;
      $siteln =~ s/__APREV__/$aprev/;
      $siteln =~ s/__OPREV__/$oprev/;
      $siteln =~ s/__SVREV__/$srvrev/;
      $siteln =~ s/__SVCNAME__/$svcname/;
      $siteln =~ s/__IPCPORT__/$ipport/;
      $siteln =~ s/__HTTPPORT__/$httpport/;
      print "$siteln\n";
   }

   close(OUT);
   select(STDOUT);


   # Generate this device's specific template set.
   $gencfgcmd = "\"%INSITE2_ROOT_DIR%\\bin\\gensitecfg\" -template ";
   $gencfgcmd .= "\"%INSITE2_ROOT_DIR%\\virtuals\\basetemplates\\etc\\templates\" ";
   $gencfgcmd .= "-cfgdir \"$newpathdir\\etc\\templates\" ";
   $gencfgcmd .= "-sitedir \"$newpathdir\"";

   print "$gencfgcmd\n";
   `$gencfgcmd`;

   # Apply the master sitemap.
   $gencfgcmd = "\"%INSITE2_ROOT_DIR%\\bin\\gensitecfg\" -template ";
   $gencfgcmd .= "\"$newpathdir\\etc\\templates\" ";
   $gencfgcmd .= "-cfgdir \"$newpathdir\\etc\" ";
   $gencfgcmd .= "-sitedir \"%INSITE2_DATA_DIR%\\etc\"";
  
   print "$gencfgcmd\n"; 
   `$gencfgcmd`;
}


#------------------------------------------------------------------------------
#
#  isServiceRunning
#
#
sub isServiceRunning
{
   local($svcname) = @_;

   my @tbuff = ();
   my $retval = 0;

   my $qcmd = "sc query " . $svcname;
   @tbuff = `$qcmd`;

   if ($tbuff[3] =~ /RUNNING/ )
   {
      $retval = 1;
   }

   return $retval;

}


#------------------------------------------------------------------------------
#
# createService
#
sub createService
{
   local($svcname) = @_;

   # create the new Windows service...
   my $svccre = "\"%INSITE2_ROOT_DIR%\\bin\\qsaMain.exe\" -service \"$svcname\" ";
   $svccre .= "-i \"Virtual Agent $svcname\" -config ";
   $svccre .= "\"%INSITE2_ROOT_DIR%\\virtuals\\$svcname\\etc\\qsaconfig.xml\"";

   print "$svccre\n";
   `$svccre`;

   # and change configuation to make it a manual service.
   my $demcmd = "sc config $svcname start= demand";
   print "$demcmd\n";
   `$demcmd`;
}


#---------------------------------------------------------------------------------------
#
# startService
#
sub startService
{
   local($svcname) = @_;

   $stcmd = "sc start $svcname";

   print "$stcmd\n";
   `$stcmd`;
}


#---------------------------------------------------------------------------------------
#
# stopService
#
sub stopService
{
   local($svcname) = @_;

   $stcmd = "sc stop $svcname";

   print "$stcmd\n";
   `$stcmd`;
} 


#----------------------------------------------------------------------------------------
#
# getAssetType
#
#
sub getAssetType
{
   local($myhash, $mydevtype) = @_;
   my $retval = "";

   foreach my $pp (@{$myhash->{AssetTypeLookup}})
   {
      if ($pp->{type} eq $mydevtype)
      {
         $retval = $pp->{content};
      }
   }

   return $retval;
}


#----------------------------------------------------------------------------------------
#
# findPrefix
#
#
sub findPrefix
{
   local($myhash, $mydevtype) = @_;
   my $retval = "";

   foreach my $pp (@{$myhash->{Prefix}})
   {
      if ($pp->{type} eq $mydevtype)
      {
         $retval = $pp->{content};
      }
   }

   return $retval;
}


#----------------------------------------------------------------------------------------
#
# writeResponse
#
#
sub writeResponse
{
   my $myhash = @_[0];
   my $vIndexPath = @_[1];

   my $xml = new XML::Simple;
   my $xmlstring = $xml->XMLout($myhash, RootName=>"InSite2Comms");

   if ($vIndexPath eq "")
   {
       $vIndexPath = $ENV{'INSITE2_ROOT_DIR'} . "\\virtuals\\response.xml";
   }
   my $tempPath = $vIndexPath . ".new";

   open NEWINDEX, ">".$tempPath;
   print NEWINDEX "<?xml version =\"1.0\" encoding=\"UTF-8\" ?>\n";
   print NEWINDEX $xmlstring;
   close NEWINDEX;

   rename($tempPath, $vIndexPath);

   return 1;
}


#----------------------------------------------------------------------------------------
#
# writeXML -
#
# This subroutine writes XML content stored in a provided
# hash structure to the virtual device's index file virtualIndex.xml.
# An alternative output path can be provided optionally.
#
# usage     writeXML(hashdata, [vIndexPath])
#
# returms     1: XML written successfully.
#             0: unsuccessful.
#
# - hashdata inclusion is mandatory.
# - reposPath is option argument giving alternate location for XML file.
#
sub writeXML
{
   my $myhash = @_[0];
   my $vIndexPath = @_[1];

   my $xml = new XML::Simple;
   my $xmlstring = $xml->XMLout($myhash, RootName=>"VirtualAgents");

   #remove empty containers.
   $xmlstring =~ s/<Package><\/Package>//g;

   if ($vIndexPath eq "")
   {
       $vIndexPath = $ENV{'INSITE2_ROOT_DIR'} . "\\virtuals\\VirtualIndex.xml";
   }
   my $tempPath = $vIndexPath . ".new";

   open NEWINDEX, ">".$tempPath;
   print NEWINDEX "<?xml version =\"1.0\" encoding=\"UTF-8\" ?>\n";
   print NEWINDEX $xmlstring;
   close NEWINDEX;

   rename($tempPath, $vIndexPath);

   return 1;
}


#----------------------------------------------------------------------------------------
#
# findHashDevices
#
# Usage findHashDevices(hashdata, devicename) or
#       findHashDevices(hashdata, devicetype, serialnum)
#
# returns: @rtnarry - array containing the release and, if applicable, patch package
#       indexes in the hashdata structure.  It's up to the calling program to determine
#       how to use the return data.
#          

sub findHashDevices
{
   my @arr = @_;
   my $hashdata = $arr[0]; 

   if ($#arr == 1)
   {
       my $devname = $arr[1];
       @rtnlist = finddevbyname($hashdata, $devname);
   }
   elsif ($#arr == 2)
   {
       my $serialnum = $arr[1];
       my $devtype = $arr[2];
       @rtnlist = finddevbynum($hashdata, $serialnum, $devtype);
   }

   return @rtnlist;
}


#------------------------------------------------------------------------------
#
#
sub getNextIndex
{
   local($myhash) = @_;

   my $retval = 0;

   $retval = $#{$myhash->{DeviceList}->[0]->{Device}};
   $retval++;

   return $retval;
}

#------------------------------------------------------------------------------
#
#
sub getNextPkgIndex
{
   local($myhash, $devtype) = @_;

   my $retval = -1;
 
   foreach my $mm (@{$myhash->{UpdateList}})
   {
      if ($mm->{type} eq $devtype)
      {
          $retval = $#{$mm->{Package}};
          $retval++;
      }
   }

   return $retval;
}


#------------------------------------------------------------------------------
#
#
sub buildNextSvcName
{
   local($mysvc) = @_;

   my $retval = "qsa";
   my ($jnk, $numpart) = split(/a/, $mysvc);

   $numpart++;
   $retval .= $numpart;

   return $retval;
}

#-------------------------------------------------------------------------------
#
#
sub getNextPortNoInd
{
   local($myhash, $porttype)=@_;
   my $retval = -1;
   my $found = 0;
   my $pind = 0;

   foreach my $pp (@{$myhash->{NextPortNo}})
   {
      if ($pp->{type} eq $porttype)
      {
         $found = 1;
         last;
      }
      $pind++;
   }

   if ($found)
   {
      $retval = $pind;
   }

   return $retval;
}

#----------------------------------------------------------------------------------------
#
# extractFileDir
#
# Subroutine extractFileDir returns only the filename from a full
# system or relative path.  Used to create meaningful file structures within
# the package repository
#
# Usage: extractFileData( fullpath )
#
# returns only the filename portion of a path.
#
sub extractFileDir
{
   local($fullpath) = @_;

   $fullpath =~ s/\//\\/g;
   my @parray = split(/\\/, $fullpath);

   return $parray[$#parray];
}


#----------------------------------------------------------------------------------------
#

sub fillDockedArray
{
   my @retval = ();
   local($hashdata) = @_;

   return @retval;
}

#----------------------------------------------------------------------------------------
#
#  startAgents
#
# Usage: startAgents(hashdata)
#
sub startAgents
{
   local($myhash) = @_;

   foreach my $pp (@{$myhash->{DeviceList}->[0]->{Device}})
   {
      if ($pp->{Docked}->[0] eq "TRUE")
      {
         startService($pp->{SvcName}->[0]);
      }
   }
   return 1;
}


#---------------------------------------------------------------------------------------
#
#  cfgAgents
#
# Usage: cfgAgents(hashdata)
#
sub cfgAgents
{
   local($myhash) = @_;
   my $gencfgcmd = "";
   my $newpathdir = "";

   foreach my $pp (@{$myhash->{DeviceList}->[0]->{Device}})
   {

      $newpathdir = $ENV{'INSITE2_ROOT_DIR'} . "\\virtuals\\$pp->{SvcName}->[0]";

      # Apply the master sitemap.
      $gencfgcmd = "\"%INSITE2_ROOT_DIR%\\bin\\gensitecfg\" -template ";
      $gencfgcmd .= "\"$newpathdir\\etc\\templates\" ";
      $gencfgcmd .= "-cfgdir \"$newpathdir\\etc\" ";
      $gencfgcmd .= "-sitedir \"%INSITE2_DATA_DIR%\\etc\"";
  
      print "$gencfgcmd\n";
      `$gencfgcmd`;

      if ((isServiceRunning($pp->{SvcName}->[0])) && ($pp->{Docked}->[0] eq "TRUE"))
      {
         stopService($pp->{SvcName}->[0]);
         startService($pp->{SvcName}->[0]);
      }
   }

   return 1;
}


#----------------------------------------------------------------------------------------
#
#  stopAgents
#
# Usage: stopAgents(hashdata)
#
sub stopAgents
{
   local($myhash) = @_;

   foreach my $pp (@{$myhash->{DeviceList}->[0]->{Device}})
   {
      if ($pp->{Docked}->[0] eq "TRUE")
      {
         stopService($pp->{SvcName}->[0]);
      }
   }
   return 1;
}


#----------------------------------------------------------------------------------------
#
#  findpkgbyname
#
# Usage: findpkgbyname(hashdata, dtype, pkgname)
#
sub findpkgbyname
{

   local($myhash, $dtype, $pkgname) = @_;

   my @reslist = ();
   my $pkgind = 0;

   foreach my $mm (@{$myhash->{UpdateList}})
   {
      if ($mm->{type} eq $dtype)
      {
          foreach my $aa (@{$mm->{Package}})
          {
              if ($aa->{ID} eq $pkgname)
              {
                 push(@reslist, $pkgind);
                 push(@reslist, $aa->{ID});
                 push(@reslist, $aa->{Type});
                 push(@reslist, $aa->{Version});
                 push(@reslist, $aa->{Path}->[0]->{Value});
                 last;
              }
              $pkgind++;
          }
      }
   }

   return @reslist;
}

#-------------------------------------------------------------------------------------
#
# findpkgbynum
#
# Usage: findpkgbynum(hashdata, dtype, ptype, revnum)
#
sub findpkgbynum
{
   local($myhash, $dtype, $ptype, $revnum) = @_;

   my @reslist = ();
   my $pkgind = 0;

   foreach my $mm (@{$myhash->{UpdateList}})
   {
      if ($mm->{type} eq $dtype)
      {
          foreach my $aa (@{$mm->{Package}})
          {
              if (($aa->{Type} eq $ptype) && ($aa->{Version} eq $revnum))
              {
                 push(@reslist, $pkgind);
                 push(@reslist, $aa->{ID});
                 push(@reslist, $aa->{Type});
                 push(@reslist, $aa->{Version});
                 push(@reslist, $aa->{Path}->[0]->{Value});
                 last;
              }
              $pkgind++;
          }
      }
   }

   return @reslist;
}


#----------------------------------------------------------------------------------------
#
#  handleUpdateCmd
#
# Usage: handleUpdateCmd(hashdata, reslist)
#
sub handleUpdateCmd
{
   local($myhash, @reslist) = @_;

   my $devtype = getAssetType($myhash, $reslist[0]);
   my $theind = getNextPkgIndex($myhash, $devtype);
   my $skip = 0;

   foreach my $mm (@{$myhash->{UpdateList}})
   {
      if ($mm->{type} eq $devtype)
      {
          for my $aa (1..$#reslist)
          {

             #
             #  first check if the current revision is already stored.  If so, delete curr copy
             #  and store new pkg.  If not, do same if current ID is already stored.
             #
            
             my @plist = ();
             @plist = findpkgbynum($myhash, $devtype, $reslist[$aa][1], $reslist[$aa][2]);

             if ($#plist == -1)
             {
                @plist = findpkgbyname($myhash, $devtype, $reslist[$aa][0]);
             }

             #  remove record from index and remove directory.
             #
             if ($#plist > -1)
             {
                $mm->{Package}->[$plist[0]] = "";
                $delcmd = "rmdir /s /q " . getDirOnly($plist[4]);
                `$delcmd`;
             }

             my $pkgpath = createPkgContainer($devtype, $reslist[$aa][0]);
             my $inpath = $reslist[$aa][3];
             my $filenm = extractFileDir($inpath);

             if (-e $inpath)
             {

                if (-d $inpath)
                {
                   $copycmd = "xcopy \/y \/q \/e \"$inpath\" \"$pkgpath\"";
                }
                else
                {
                   $copycmd = "copy \/y \"$inpath\" \"$pkgpath\"";
                }

                `$copycmd`;

                $pkgpath .= "\\" . $filenm;

                $mm->{Package}->[$theind]->{ID} = $reslist[$aa][0];
                $mm->{Package}->[$theind]->{Type} = $reslist[$aa][1];
                $mm->{Package}->[$theind]->{Version} = $reslist[$aa][2];
                $mm->{Package}->[$theind]->{Path} = ();
                $mm->{Package}->[$theind]->{Path}->[0]->{Value} = $pkgpath;
                $theind++;
             }
          }

          writeXML($myhash);
          last;
      }
   }
   
   return 1;   
}


#----------------------------------------------------------------------------------------
#
#  finddevbyname
#
# Usage: finddevbyname(hashdata, devicename)
#
sub finddevbyname
{

   local($hashdata, $devname) = @_;

   my @reslist = ();
   my $devind = 0;
   foreach my $pp (@{$hashdata->{DeviceList}->[0]->{Device}})
   {
       if ($pp->{DeviceId}->[0] eq $devname)
       {
           push(@reslist,$devind);
           push(@reslist,$pp->{DeviceId}->[0]);
           push(@reslist,$pp->{SerialNumber}->[0]);
           push(@reslist,$pp->{SvcName}->[0]);
           push(@reslist,$pp->{Docked}->[0]);
           push(@reslist,$pp->{PortNo}->[0]->{content});
           push(@reslist,$pp->{PortNo}->[1]->{content});
           push(@reslist,$pp->{Revision}->[0]->{content});
           push(@reslist,$pp->{Revision}->[1]->{content});
           push(@reslist,$pp->{Revision}->[2]->{content});
           last;
       }
       $devind++;
   }

   return @reslist;
}


#---------------------------------------------------------------------------------------
#
#  createPkgContainer
#
sub createPkgContainer
{
   my $contpath = "";
   local($assettype, $pkgname) = @_;

   $contpath = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\" . $assettype . "\\" . $pkgname;

   if (! (-e $contname))
   {
      $credir = "mkdir \"$contpath\"";
      `$credir`;
   }
 
   return $contpath;
}



#----------------------------------------------------------------------------------------
#
#  finddevbynum
#
# Usage: finddevbynum(hashdata, devicetype, serialnum)
#
#

sub finddevbynum
{

   local($hashdata, $devtype, $serialnum) = @_;

   my @reslist = ();
   my $devind = 0;

   foreach my $pp (@{$hashdata->{DeviceList}->[0]->{Device}})
   {
       if (($pp->{SerialNumber}->[0] eq $serialnum) && ($pp->{DeviceType}->[0] eq $devtype))
       {
           push(@reslist,$devind);
           push(@reslist,$pp->{DeviceId}->[0]);
           push(@reslist,$pp->{SerialNumber}->[0]);
           push(@reslist,$pp->{SvcName}->[0]);
           push(@reslist,$pp->{Docked}->[0]);
           push(@reslist,$pp->{PortNo}->[0]->{content});
           push(@reslist,$pp->{PortNo}->[1]->{content});
           push(@reslist,$pp->{Revision}->[0]->{content});
           push(@reslist,$pp->{Revision}->[1]->{content});
           push(@reslist,$pp->{Revision}->[2]->{content});
           last;
       }
       $devind++;
   }

   return @reslist;
}


MAIN:
{
  1;
}