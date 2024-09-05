use Getopt::Long;

#----------------------------------------------------------------------------------------
#
# processArgs
#
# This subroutine processes the command-line arguments passed to the Toolkit
# scripts.  Based on the mode, the processArgs assigns global variables,
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

   if ($mode == 2)
   {
       $retval=GetOptions("h"=>\$Arg_helpflag,
           "checksizeMB=s"=>\$Arg_checksizeMB,
           "checksysMB=s"=>\$Arg_checksysMB,
           "workdir=s"=>\$Arg_workdir,
           "propname=s"=>\$Arg_propname,
           "propvalue=s"=>\$Arg_propvalue,
           "runscript=s"=>\$Arg_runscript,
           "skippkgaccept"=>\$Arg_skipaccept);

       if ($Arg_helpflag) {
    	    if (($Arg_checksizeMB) || ($Arg_checksysMB) || ($Arg_propname) ||
                ($Arg_propvalue) || ($Arg_runscript) || ($Arg_workdir) ||
                ($Arg_skipaccept)) {
              $Arg_helpflag = 0;
          }
       }
   }
   elsif ($mode == 3)
   {
       $retval=GetOptions("h"=>\$Arg_helpflag,
           "pkgname=s"=>\$Arg_pkgname,
            "failsafe"=>\$Arg_failsafeflag,
              "reboot"=>\$Arg_rebootflag,
	     "current"=>\$Arg_currentflag,
           "previous"=>\$Arg_previousflag,
            "pending"=>\$Arg_pendingflag);

       if ($Arg_helpflag) {
    	    if (($Arg_pkgname) || ($Arg_failsafeflag) || ($Arg_rebootflag) ||
              ($Arg_currentflag) || ($Arg_previousflag) || ($Arg_pendingflag)) {
              $Arg_helpflag = 0;
          }
       }
   }
   elsif ($mode == 4)
   {
       $retval=GetOptions("h"=>\$Arg_helpflag,
           "propname=s"=>\$Arg_propname,
	   "propvalue=s"=>\$Arg_propvalue,
           "wait"=>\$Arg_waitflag,
           "restart"=>\$Arg_restartflag,
           "gencfg"=>\$Arg_gencfgflag);

       if ($Arg_helpflag) {
    	    if (($Arg_propname) || ($Arg_propvalue) || ($Arg_gencfgflag) ||
                 ($Arg_restartflag) || ($Arg_waitflag) ) {
              $Arg_helpflag = 0;
          }
       }
   }
   else
   {
       $retval=GetOptions("h"=>\$Arg_helpflag,
           "pkgname=s"=>\$Arg_pkgname,
           "pkgpath=s"=>\$Arg_pkgpath,
	   "revnum=s"=>\$Arg_revnum,
           "pkgtype=s"=>\$Arg_pkgtype,
           "filetype=s"=>\$Arg_filetype,
           "parentpkg=s"=>\$Arg_parentpkg,
           "workdir=s"=>\$Arg_workdir,
           "manifestdir=s"=>\$Arg_manifestdir,
	   "forcepkginstall"=>\$Arg_forceinstallflag,
           "forcepkgrecovery"=>\$Arg_forcerecoveryflag,
           "noclean"=>\$Arg_nocleanflag,
           "addtocheck"=>\$Arg_addtocheckflag);

	 if ($Arg_helpflag) {
    	    if (($Arg_workdir) || ($Arg_manifestdir) || ($Arg_pkgname) || ($Arg_revnum) ||
              ($Arg_pkgtype) || ($Arg_filetype) || ($Arg_parentpkg) || ($Arg_forceinstallflag) ||
              ($Arg_forcerecoveryflag) || ($Arg_nocleanflag) || ($Arg_addtocheckflag) || ($Arg_pkgpath)) { 
              $Arg_helpflag = 0;
          }
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
#  readCfgProp -
#
#  Subroutine readCfgProp returns the value of a configuration property found
#  in the service agent's versions.txt file.
#
#  Usage: readCfgProp($propname, [$altpath])
#
#  altpath is an optional argument providing an alternative versions.txt file.
#  returns - value of configuration property or null.
#

sub readCfgProp
{
   local($pname, $verpath) = @_;
   my $retval = "";

   if ($verpath eq "")
   {
      $verpath = $ENV{'INSITE2_ROOT_DIR'} . "\\etc\\versions.txt";
   }


   if (-e $verpath)
   {
      open(CFGFILE, $verpath);
      @CfgFileLines = <CFGFILE>;
      chop(@CfgFileLines);
      close(CFGFILE);

      for $n ( 0..$#CfgFileLines )
      {
         my ($pnm, $pval)=split(/:/, $CfgFileLines[$n]);

         if ($pnm eq $pname)
         {
            $retval = $pval;
         }
      }
      
   }

   return $retval;
}


#----------------------------------------------------------------------------------------
#
#  remCfgProp -
#
#  Subroutine remCfgProp removes a configuration property found
#  in the service agent's versions.txt file.
#
#  Usage: remCfgProp($propname, [$altpath])
#
#  altpath is an optional argument providing an alternative versions.txt file.
#  returns - 1 if configuration property was removed or not found.
#            0 if versions.txt path was not valid.
#

sub remCfgProp
{
   local($pname, $verpath) = @_;

   if ($verpath eq "")
   {
      $verpath = $ENV{'INSITE2_DATA_DIR'} . "\\etc\\versions.txt";
   }
   $newpath = $verpath . ".new";

   my $foundit = 0;
   if (-e $verpath)
   {
      open(CFGFILE, $verpath);
      @CfgFileLines = <CFGFILE>;
      chop(@CfgFileLines);
      close(CFGFILE);

      open(NEWFILE, ">$newpath");
      select(NEWFILE);

      for $n ( 0..$#CfgFileLines )
      {
         $readline = @CfgFileLines[$n];

         my ($pnm, $pval)=split(/:/, $readline);

         if ($pnm ne $pname)
         {
            print "$readline\n";
         }
      }
 
      close(NEWFILE);

      rename($newpath, $verpath);

      return 1;
   }

   return 0;
}


#----------------------------------------------------------------------------------------
#
#  writeCfgProp -
#
#  Subroutine writeCfgProp adds or updates a configuration property found
#  in the service agent's versions.txt file.
#
#  Usage: writeCfgProp(propname, propval, [altpath])
#
#  altpath is an optional argument providing an alternative versions.txt file.
#  returns - 1 if configuration property was added or updated.
#            0 if versions.txt path was not valid.
#

sub writeCfgProp
{
   local($pname, $pvalue, $verpath) = @_;

   if ($verpath eq "")
   {
      $verpath = $ENV{'INSITE2_DATA_DIR'} . "\\etc\\versions.txt";
   }
   $newpath = $verpath . ".new";

   my $foundit = 0;
   if (-e $verpath)
   {
      open(CFGFILE, $verpath);
      @CfgFileLines = <CFGFILE>;
      chop(@CfgFileLines);
      close(CFGFILE);

      open(NEWFILE, ">$newpath");
      select(NEWFILE);

      for $n ( 0..$#CfgFileLines )
      {
         $readline = @CfgFileLines[$n];

         my ($pnm, $pval)=split(/:/, $readline);

         if ($pnm eq $pname)
         {
            $foundit = 1;
            print "$pnm: $pvalue\n";
         }
         else
         {
            print "$readline\n";
         }
      }
 
      if (! $foundit)
      {
         print "$pname: $pvalue\n";
      }
      close(NEWFILE);
      select(stdout);

      rename($newpath, $verpath);

      return 1;
   }

   return 0;
}




MAIN:
{
  1;
}