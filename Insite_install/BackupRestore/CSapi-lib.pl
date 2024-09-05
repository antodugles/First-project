use Getopt::Long;
use XML::Simple;
use Data::Dumper;


#----------------------------------------------------------------------------------------
#
# processArgs
#
# This subroutine processes the command-line arguments passed to the CS BackupRestore
# API scripts.  Based on the mode, the processArgs assigns global variables,
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
   my $mode = @_[1];

   $retval=GetOptions("h"=>\$Arg_helpflag,
           "backup"=>\$Arg_backupflag,
	   "restore"=>\$Arg_restoreflag,
           "pkglocation=s"=>\$Arg_pkglocation);

   if ($Arg_helpflag) {
    	    if (($Arg_backupflag) || ($Arg_restoreflag)) {
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
# This subroutine reads either the default SaveFilesCfg index path
# or a provided path and places the XML data into an XML::Simple hash table.
# The hash table is searchable, update-able, and can be rewritten to a
# new updated index XML.
#
# readXML( [saveIndexPath] )
#
# returns      $hashdata: - hash data structure representing the XML content
#              null - could not read the XML content.
#
# optional saveIndexPath provides an alternate saveFiles XML.
#
sub readXML
{
   my $reposPath = @_[0];

   if ($reposPath eq "")
   {
       $reposPath = $ENV{'INSITE2_HOME'} . "\\BackupRestore\\SaveFilesCfg.xml";
   }

   my $xml = new XML::Simple;
   my $hashdata = eval { $xml->XMLin ($reposPath, ForceArray=>1) };
   if ($@)
   {
       logException($@, "ERROR", 666);
   }

   #  print Dumper($hashdata);

   return $hashdata;
}

#---------------------------------------------------------------------------------------
#
#   Returns the current device name configured in the service platform's
#   qsaconfig.xml file.
#
#       returns   $devname - device name found in qsaconfig.xml
#                 null - no qsaconfig.xml was found or devicename is not set.
#

sub getDeviceName
{

   my $AgentCfgFile = $ENV{"INSITE2_DATA_DIR"} . "\\etc\\qsaconfig.xml";
   my $devname = "";

   if (-e $AgentCfgFile)
   {
      open(AGENTFILE, $AgentCfgFile);
      my @AgentFileLines = <AGENTFILE>;
      chop(@AgentFileLines);
      close(AGENTFILE);

      for my $i ( 0..$#AgentFileLines )
      {
         if (@AgentFileLines[$i] =~ /MemberName/)
         {
            $devname = @AgentFileLines[$i];
         }
      }

      if ($devname ne "")
      {
         $devname =~ s/<MemberName>//;
         $devname =~ s/<\/MemberName>//;
         $devname =~ s/ //g;
      }
   }

   return $devname;

}


#------------------------------------------------------------------------------
#
#   Writes the current platform's device name to the configuration backup pkg.
#
#   backupDeviceName pkgdir
#                        where pkgdir is the working location for the backup
#                        config package.
#
#   returns 1 
#
sub backupDeviceName
{
   local($pkgdir) = @_;

   my $currdevname = getDeviceName();

   my $pkgdevicefile = $pkgdir . "\\device.txt";
   
   open(OUTFILE, ">$pkgdevicefile");
   select(OUTFILE);

   print "$currdevname\n";
   close(OUTFILE);

   select(stdout);

   return 1;
}


#---------------------------------------------------------------------------------------
#
#   Compares the current platform's device name with the configuration pkg's
#   device name.
#
#      validDeviceName pkgdir
#              where pkgdir is the location of the restore configuration package.
#
#              Returns      1 - Device names match.
#                           0 - Device name mismatch or missing devicename in pkg.

sub validDeviceName
{
   local($pkgdir) = @_;

   my $retval = 0;
   my $devicename = "";

   my $devnamefile = $pkgdir . "\\device.txt";
   if (-e $devnamefile)
   {
      open(AGENTFILE, $devnamefile);
      my @AgentFileLines = <AGENTFILE>;
      chop(@AgentFileLines);
      close(AGENTFILE);

      $devicename = @AgentFileLines[0];
      my $currdevname = getDeviceName();

      if ($devicename eq $currdevname)
      {
         $retval = 1;
      }
   }

   return $retval;
}


#---------------------------------------------------------------------------------------
#
#  Writes an text string to the brerr.txt file read by the ActDeact tool.
#  This text is displayed to the user as a status of the selected operation.
#
#  logFile errtext
#        where errtext is the string to display to the user.
#
#  returns 1
#

sub logFile
{
   local($errtext) = @_;

   my $errtxtfile = $ENV{"INSITE2_HOME"} . "\\bin\\brerr.txt";

   open(OUTFILE, ">$errtxtfile");
   select(OUTFILE);

   print "$errtext";
   close(OUTFILE);

   select(stdout);
   

   return 1;
}

#---------------------------------------------------------------------------------------
#
# Logs an event in the APPLICATION event log for a given type and error code.
#
# logException errtext type errorcode
#
#    where errtext is the event description
#          type is the either an ERROR, WARNING, or INFORMATION event type
#          errorcode is a numeric ID for the particulare error.
#

sub logException 
{
   local($errtext, $type, $errcode) = @_;

   if ($debug)
   {
      print "$errtext\n";
   }

   $logcmd = "eventcreate \/T $type \/ID $errcode \/L APPLICATION \/SO BackupRestore \/D \"$errtext\"";
   `$logcmd`;

   return 1;
}

#---------------------------------------------------------------------------------------
#

sub parseVersion
{
   local($vertext) = @_;
   my @verparts = ();

   @verparts = split(/\./,$vertext);

   if ($#verparts == 0)
   {
      push(@verparts, "0");
   }

   return @verparts; 
}

#----------------------------------------------------------------------------------------
#
#                       returns:  1 - pkg file is valid for this platform.
#                                 0 - pkg file is not compatible for this platform.

sub validFileVersion
{
   local($pkgfname, $pkgfver, $hash) = @_;
   my $match = 0;
   my $retval = 0;

   my $hfname = "";
   my $hexclflg = "";
   my $hfver = "";

   $updSaveCfgFlag = 0;

   if (!(-e $pkgfname))
   {
      return 1;
   }

   foreach my $ff (@{$hash->{CfgFile}})
   {
      $hfname = $ff->{FileName}->[0]->{content};
      $hexclflg = $ff->{Exclude};
      $hfver = $ff->{FileName}->[0]->{Version};

      if ($hfname eq $pkgfname)
      {
         $match = 1;
         last;
      }
   }

   # now compare the platform with pkg content
   if ($match)
   {
      if ($hfver ne $pkgfver)
      {
         my @hparts = ();
         @hparts = parseVersion($hfver);

         my @pkgparts = ();
         @pkgparts = parseVersion($pkgfver);

         if ($hparts[0] == $pkgparts[0])
         {
            $retval = 1;
            if ($hparts[1] < $pkgparts[1])
            {
               $updSaveCfgFlag = 1;
            } 
         }
      }
      else
      {
         $retval = 1;
      }
   }

   return $retval; 
} 


#----------------------------------------------------------------------------------------
#

sub updateSaveConfig{

   local($fname,$fver) = @_;

   my $a = 0;
   my $newline = "";

   my $xmlfile = $ENV{"INSITE2_HOME"} . "\\BackupRestore\\SaveFilesConfig.xml";
   open(XMLFILE, $xmlfile);
   my @xmllines = <XMLFILE>;
   chop(@xmllines);

   close(XMLFILE);

   my $newfile = $xmlfile . ".newfile";
   open(OUTFILE, ">$newfile");
   select(OUTFILE);

   for $a (0..$#xmllines)
   {
      $newline = @xmllines[$a];

      if ($newline =~ /$fname/)
      {
         $newline = "        <FileName Version=\"$fver\">$fname<\/FileName>";
      }

      print "$newline\n";
   }

   close(OUTFILE);

   #rename($xmlfile, $newfile);
   select(stdout);

   return 1;
}


#----------------------------------------------------------------------------------------
#
#  cleanupError simply changes to a preferred directory and executes the provided
#  command.  This is useful when deleting a working directory after use.
#

sub cleanupError
{
   local($cmdloc, $cmdstr) = @_;

   chdir("$cmdloc");
   `$cmdstr`;

   return;
}


#----------------------------------------------------------------------------------------
#
#  fileFileArray parses the the SaveFilesConfig.xml structure and places the contents
#  in a ordered array.  Useful for quick and easy processing within the application.
#
#  fillFileArray hashdata
#         where hashdata is the XML data structure returned from parseXML
#         routine.
#
#  returns @reslst - a 2 dimensional array with the necessary processing data
#         for each configuration file.
#

sub fillFileArray
{
   local($hashdata) = @_;
   my @reslst = ();

   my $fname="";
   my $fver="";
   my $exclflg = "";
   my $fpath = "";
   my $altflg = "";

   foreach my $ff (@{$hashdata->{CfgFile}})
   {
      $fpath = "";
      $ptype = uc($ff->{PlatformPath}->[0]->{type});

      if ($ptype =~ /REL/) 
      {
         $fpath .= $ENV{"INSITE2_HOME"} . "\\";
      }

      $fname = $ff->{FileName}->[0]->{content};
      $exclflg = $ff->{Exclude};
      $fver = $ff->{FileName}->[0]->{Version};
      $fpath .= $ff->{PlatformPath}->[0]->{content};
      if ($fname ne "")
      {
         $fpath .= "\\" . $fname;
      }
      
      $altcmd = "";
      if ($ff->{AltProcessCmd}->[0] ne "")
      {
         $altcmd = $ff->{AltProcessCmd}->[0];
      }

      my @incrlst = ();
      push(@incrlst, $fname);
      push(@incrlst, $exclflg);
      push(@incrlst, $fver);
      push(@incrlst, $fpath);
      push(@incrlst, $altcmd);
      push @reslst, [ @incrlst ];
   }

   return @reslst;
}


#----------------------------------------------------------------------------------------
#
# extractFileDir
#
# Subroutine extractFileDir returns only the filename from a full
# system or relative path.
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


MAIN:
{
  1;
}