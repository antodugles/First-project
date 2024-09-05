use Getopt::Long;
use XML::Simple;
use Data::Dumper;

#----------------------------------------------------------------------------------------
#
# processArgs
#
# This subroutine processes the command-line arguments passed to the Repository
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

   if ($mode == 2)
   {
       $retval=GetOptions("h"=>\$Arg_helpflag,
           "pkgname"=>\$Arg_pkgnameflag,
	     "revnum"=>\$Arg_revnumflag,
           "pkgtype=s"=>\$Arg_pkgtype);

       if ($Arg_helpflag) {
    	    if (($Arg_pkgnameflag) || ($Arg_revnumflag) || ($Arg_pkgtype)) {
              $Arg_helpflag = 0;
          }
       }
   }
   elsif ($mode == 3)
   {
       $retval=GetOptions("h"=>\$Arg_helpflag,
           "blobname=s"=>\$Arg_blobname,
           "blobpath=s"=>\$Arg_blobpath,
           "pkgname=s"=>\$Arg_pkgname,
	     "revnum=s"=>\$Arg_revnum,
           "pkgtype=s"=>\$Arg_pkgtype);


       if ($Arg_helpflag) {
    	    if (($Arg_blobname) || ($Arg_blobpath) ||
              ($Arg_pkgname) || ($Arg_revnum) || ($Arg_pkgtype)) {
              $Arg_helpflag = 0;
          }
       }
   }
   elsif ($mode == 4)
   {
       $retval=GetOptions("h"=>\$Arg_helpflag,
           "pkgname=s"=>\$Arg_pkgname,
	     "revnum=s"=>\$Arg_revnum,
           "pkgtype=s"=>\$Arg_pkgtype,
	     "install"=>\$Arg_installflag,
           "uninstall"=>\$Arg_uninstallflag,
           "setpending"=>\$Arg_setpendingflag,
           "unsetpending"=>\$Arg_unsetpendingflag);


       if ($Arg_helpflag) {
    	    if (($Arg_pkgname) || ($Arg_revnum) || ($Arg_pkgtype) || ($Arg_installflag) ||
              ($Arg_uninstallflag) || ($Arg_setpendingflag) || ($Arg_unsetpendingflag)) {
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
           "attrname=s"=>\$Arg_attrname,
           "delimchar=s"=>\$Arg_delimchar,
	     "current"=>\$Arg_currentflag,
           "previous"=>\$Arg_previousflag,
           "pending"=>\$Arg_pendingflag);

	 if ($Arg_helpflag) {
    	    if (($Arg_blobname) || ($Arg_blobpath) || ($Arg_pkgname) || ($Arg_revnum) ||
              ($Arg_pkgtype) || ($Arg_filetype) || ($Arg_parentpkg) || ($Arg_attrname) ||
              ($Arg_delimchar) || ($Arg_currentflag) || ($Arg_previousflag) || ($Arg_pendingflag)) { 
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
# readXML -
#
# This subroutine reads either the default Package Repository index path
# or a provided path and places the XML data into an XML::Simple hash table.
# The hash table is searchable, update-able, and can be rewritten to a
# new updated index XML.
#
# readXML( [reposPath] )
#
# returns      $hashdata: - hash data structure representing the XML content
#              null - could not read the XML content.
#
# optional reposPath provides an alternate index XML.
#
sub readXML
{
   my $reposPath = @_[0];

   if ($reposPath eq "")
   {
       $reposPath = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\reposIndex.xml";
   }

   my $xml = new XML::Simple;
   my $hashdata = eval { $xml->XMLin ($reposPath, ForceArray=>1)};

   if ($@)
   {
      logException($@, "ERROR", 101);
   }

   return $hashdata;
}


#---------------------------------------------------------------------------------------
#
# Logs an event in the APPLICATION event log for a given type and error code
#
# logException errtext type errorcode
#
#    where errtext is the event description
#          type is ERROR, WARNING, or INFORMATION event type
#          errorcode is a numeric ID for an error
#

sub logException
{
   local($errtext, $type, $errcode) = @_;

   $logcmd = "eventcreate \/T $type \/ID $errcode \/L APPLICATION \/SO SWMGMTAPI \/D \"$errtext\"";
   `$logcmd`;

   return 1;
}

#----------------------------------------------------------------------------------------
#
# ascending -
#
# used for sorting an array in increasing install order.
#
sub ascending { $a <=> $b; }


#----------------------------------------------------------------------------------------
#
# writeXML -
#
# This subroutine writes XML content stored in a provided
# hash structure to the Package Repository's index file reposIndex.xml.
# An alternative output path can be provided optionally.
#
# usage     writeXML(hashdata, [reposPath])
#
# returms     1: XML written successfully.
#             0: unsuccessful.
#
# - hashdata inclusion is mandatory.
# - reposPath is option argument giving alternate locaitno for XML file.
#
sub writeXML
{
   my $hashdata = @_[0];
   my $reposPath = @_[1];

   my $xml = new XML::Simple;
   my $xmlstring = $xml->XMLout($hashdata, RootName=>"PkgRepository");

   #remove empty containers.
   $xmlstring =~ s/<Blob><\/Blob>//g;
   $xmlstring =~ s/<ReleasePackage><\/ReleasePackage>//g;
   $xmlstring =~ s/<PatchPackage><\/PatchPackage>//g;

   if ($reposPath eq "")
   {
       $reposPath = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\reposIndex.xml";
   }
   my $tempPath = $reposPath . ".new";

   open NEWINDEX, ">".$tempPath;
   print NEWINDEX "<?xml version =\"1.0\" encoding=\"UTF-8\" ?>\n";
   print NEWINDEX $xmlstring;
   close NEWINDEX;

   rename($tempPath, $reposPath);

   return 1;
}


#----------------------------------------------------------------------------------------
#
# findHashPackages
#
# Subroutine findHashPackages returns record pointers or indexes into a given XML
# hash structure corresponding to a specific package.  The package is either
# identified by name or by revision and package type.
#
# Usage findHashPackages(hashdata, packagename) or
#       findHashPackages(hashdata, revisionnum, packagetype)
#
# returns: @rtnarry - array containing the release and, if applicable, patch package
#       indexes in the hashdata structure.  It's up to the calling program to determine
#       how to use the return data.
#          

sub findHashPackages
{
   my @arr = @_;
   my $hashdata = $arr[0]; 

   if ($#arr == 1)
   {
       my $pkgname = $arr[1];
       @rtnlist = findpkgbyname($hashdata, $pkgname);
   }
   elsif ($#arr == 2)
   {
       my $revnum = $arr[1];
       my $pkgtype = $arr[2];
       @rtnlist = findpkgbyrev($hashdata, $revnum, $pkgtype);
   }

   return @rtnlist;
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
# findCurrRelPtr
#
# Subroutine findCurrRelPtr returns an index pointing to the current
# installed release package.
#
# usage: findCurrRelPtr(hashdata, packagetype)
#
sub findCurrRelPtr
{

    local($hashdata, $ptype) = @_;

    my $pkgind = 0;
    my $maxpkg = -1;
    my $maxord = 0;
    my $retval = "";

    foreach my $pp (@{$hashdata->{ReleasePackage}})
    {
             $thisord = $pp->{InstallOrder}->[0];
             $thisflag = $pp->{InstFlag}->[0];
             if (($thisflag eq "TRUE") && ($thisord > $maxord))
             {
                if (($ptype eq "") || ($pp->{PkgType}->[0] eq $ptype))
                {
                   $maxord = $thisord;
                   $maxpkg = $pkgind;
                }
             }
             $pkgind++;
    }

    return $maxpkg;   
}


#----------------------------------------------------------------------------------------
#
# findPendRelPtr
#
# Subroutine findPendRelPtr returns an index pointing to the latest
# release package with install pending.
#
# usage: findPendRelPtr(hashdata, packagetype)
#
sub findPendRelPtr
{

    local($hashdata, $ptype) = @_;

    my $pkgind = 0;
    my $maxpkg = -1;
    my $maxord = 0;
    my $retval = "";

    foreach my $pp (@{$hashdata->{ReleasePackage}})
    {
             $thisord = $pp->{StoreOrder}->[0];
             $thisflag = $pp->{PendingFlag}->[0];
             if (($thisflag eq "TRUE") && ($thisord > $maxord))
             {
                if (($ptype eq "") || ($pp->{PkgType}->[0] eq $ptype))
                {
                   $maxord = $thisord;
                   $maxpkg = $pkgind;
                }
             }
             $pkgind++;
    }

    return $maxpkg;
}

#----------------------------------------------------------------------------------------
#
# findPrevRelPtr
#
# Subroutine findCurrRelPtr returns an index pointing to the latest previously
# installed release package.  (Deprecated)
#
# usage: findPrevRelPtr(hashdata, packagetype)
#
sub findPrevRelPtr
{

    local($hashdata, $ptype) = @_;

    my $pkgind = 0;
    my $maxpkg = -1;
    my $prevpkg = -1;
    my $retpkg = -1;
    my $maxord = 0;
    my $prevord = 0;
    my $retval = "";

    foreach my $pp (@{$hashdata->{ReleasePackage}})
    {
             $thisord = $pp->{InstallOrder}->[0];
             $thisflag = $pp->{InstFlag}->[0];
             if (($thisflag eq "TRUE") && ($thisord > $maxord))
             {
                if (($ptype eq "") || ($pp->{PkgType}->[0] eq $ptype))
                {
                   $maxord = $thisord;
                   $maxpkg = $pkgind;
                }
             }
             $pkgind++;
    }
     
    foreach my $pp (@{$hashdata->{ReleasePackage}})
    {
             $thisord = $pp->{InstallOrder}->[0];
             $thisflag = $pp->{InstFlag}->[0];
             if (($thisflag eq "TRUE") && ($thisord > $prevord) && ($thisord < $maxord))
             {
                if (($ptype eq "") || ($pp->{PkgType}->[0] eq $ptype))
                {
                   $prevord = $thisord;
                   $prevpkg = $pkgind;
                }
             }
             $pkgind++;
    }

    # determine if current release has same.
    my $ifound = 0;
    if ($maxpkg > -1)
    {
        $reltype = $hashdata->{ReleasePackage}->[$maxpkg]->{PkgType}->[0];
        foreach my $ff (@{$hashdata->{ReleasePackage}->[$maxpkg]->{PatchList}->[0]->{PatchPackage}})
        {
             #previous revision in current release package.
             if ($ff->{InstFlag}->[0] eq "TRUE")
             {
                 $tcmp = convPkgType($ff->{PatchType}->[0]);

                 if ($tcmp eq $reltype)
                 {
                     $ifound = 1;
                     $retpkg = $maxpkg;
                     last;
                 }
             }
        }
    }

    #previous revision in previous release package.
    if (!($ifound))
    {
             $retpkg = $prevpkg;
    }
    return $retpkg;
}


#----------------------------------------------------------------------------------------
#
#  findChildAppl -
# Find index in the given release's Patch list for the PatchPackage element with a
# PkgType of AF (Full Appl Inst).
#
# Usage: findChildAppl($hashdata, $relind);
#
# returns a hashdata index to the child in release's patch list.
#

sub findChildAppl
{
   local($hashdata, $relind) = @_;

   my $chind = 0;
   my $chmatch = -1;

   foreach my $bb (@{$hashdata->{ReleasePackage}->[$relind]->{PatchList}->[0]->{PatchPackage}})
   {
      if ($bb->{PatchType}->[0] eq "AF")
      {
         $chmatch=$chind;
         last;
      }
      $chind++;
   }
   return $chmatch;
}


#----------------------------------------------------------------------------------------
#
#  findBlob -
# Find index in the given release's blob list for the blob element matching
# the provided blob name.
#
# Usage: findBlob(hashdata, blobname, releaseIndex)
#
# returns a hashdata index to the blob in the release's blob list.
#

sub findBlob
{
   local($hashdata, $bname, $relind) = @_;

   my $bind = 0;
   my $bmatch = -1;

   foreach my $bb (@{$hashdata->{ReleasePackage}->[$relind]->{BlobList}->[0]->{Blob}})
   {
      if ($bb->{BlobName}->[0] eq $bname)
      {
         $bmatch=$bind;
         last;
      }
      $bind++;
   }
   return $bmatch;
}


#----------------------------------------------------------------------------------------
#
#  findpkgbyname
#
# Subroutine findpkgbyname returns the pointer (index) to a release or patch package
# in the hashdata matching a package name.
#
# Usage: findpkgbyname(hashdata, packagename)
#
#

sub findpkgbyname
{
   my $pkgind = 0;
   my $patind = 0;
   my $rfound = 0;
   my $pfound = 0;
   my $match = 0;
   my $ctot = 0;
   my $btot = 0;

   local($hashdata, $pkgname) = @_;

   foreach my $pp (@{$hashdata->{ReleasePackage}})
   {
       if ($pp->{PkgName}->[0] eq $pkgname)
       {
           $match = 1;
           $rfound = $pkgind;
           $btot = $#{$pp->{BlobList}->[0]->{Blob}};
           $btot++;
       }

       $patind = 0;
       foreach $ff (@{$pp->{PatchList}->[0]->{PatchPackage}})
       {
           if ($ff->{PkgName}->[0] eq $pkgname)
           {
               $rfound = $pkgind;
               $pfound = $patind;
               $match = 2;
           }
           $patind++;
       }

       if ($match)
       {
           $ctot = $patind;
           last;
       }

       $pkgind++;
   }

   my @reslist = ();
   if ($match == 2){
      push(@reslist,"P");
      push(@reslist,$rfound);
      push(@reslist,$pfound);
      push(@reslist,$ctot);
      push(@reslist,-1);
   }
   elsif ($match == 1)
   {
      push(@reslist,"R");
      push(@reslist,$rfound);

      push(@reslist,-1);
      push(@reslist,$ctot);
      push(@reslist,$btot);
   }

   return @reslist;
}


#----------------------------------------------------------------------------------------
sub fillInstarray
{
   my @retval = ();
   local($hashdata) = @_;

   foreach my $pp (@{$hashdata->{ReleasePackage}})
   {
       if ($pp->{InstFlag}->[0] eq "TRUE")
       {
          my @trr = ();
          push(@trr, $pp->{InstallOrder}->[0]);
          push(@trr, $pp->{PkgName}->[0]);
          push(@trr, $pp->{PkgType}->[0]);

          push @retval, [ @trr ];
       }

       foreach my $ff (@{$pp->{PatchList}->[0]->{PatchPackage}})
       {
            if ($ff->{InstFlag}->[0] eq "TRUE")
            {
               my @trr = ();
               push(@trr, $ff->{InstallOrder}->[0]);
               push(@trr, $ff->{PkgName}->[0]);
               push(@trr, $ff->{PatchType}->[0]);

               push @retval, [ @trr ];
            }
       }
   }
   return @retval;
}

#----------------------------------------------------------------------------------------
#
#  findpkgbyrev
#
# Subroutine findpkgbyrev returns the pointer (index) to a release or patch package
# in the hashdata matching a revision number and package type
#
# Usage: findpkgbyname(hashdata, revisionnumber, packagetype)
#
#

sub findpkgbyrev
{

   local($hashdata, $revnum, $pkgtype) = @_;

   my $pkgind = 0;
   my $patind = 0;
   my $rfound = 0;
   my $pfound = 0;
   my $match = 0;
   my $ctot = 0;
   my $btot = 0;

   foreach my $pp (@{$hashdata->{ReleasePackage}})
   {
       if (($pp->{RevNum}->[0] eq $revnum) && ($pp->{PkgType}->[0] eq $pkgtype))
       {
           $rfound = $pkgind;
           $match = 1;
           $btot = $#{$pp->{BlobList}->[0]->{Blob}};
           $btot++;
       }

       $patind = 0;
       foreach $ff (@{$pp->{PatchList}->[0]->{PatchPackage}})
       {
           if (($ff->{RevNum}->[0] eq $revnum) && ($ff->{PatchType}->[0] eq $pkgtype))
           {
               $match = 2;
               $rfound = $pkgind;
               $pfound = $patind;
           }
           $patind++;
       }

       if ($match)
       {
           $ctot = $patind;
           last;
       }

       $pkgind++;
   }

   my @reslist = ();
   if ($match == 2){
      push(@reslist,"P");
      push(@reslist,$rfound);
      push(@reslist,$pfound);
      push(@reslist,$ctot);
      push(@reslist,-1);
   }
   elsif ($match == 1)
   {
      push(@reslist,"R");
      push(@reslist,$rfound);
      push(@reslist,-1);
      push(@reslist,$ctot);
      push(@reslist,$btot);
   }

   return @reslist;
}


#----------------------------------------------------------------------------------------
#
#  findparentbyrev
#
# Subroutine findparentbyrev returns the pointer (index) to a release
# in the hashdata that is parent to a patch pkg identified by revision number
# and package type
#
# Usage: findparentbyrev(hashdata, revisionnumber, packagetype)
#
#
sub findparentbyrev
{
   local($hashdata, $revnum, $pkgtype) = @_;

   my $pkgind = 0;
   my $rfound = 0;
   my $match = 0;
   my $ctot = 0;
   my $btot = 0;

   # get the parent package type.
   my $partype = convPkgType($pkgtype);

   my $revmatch = getMajorMinor($revnum);

   foreach my $pp (@{$hashdata->{ReleasePackage}})
   {
       if (($pp->{RevNum}->[0] eq $revmatch) && ($pp->{PkgType}->[0] eq $partype))
       {
           $rfound = $pkgind;
           $match = 1;
       }

       if ($match)
       {
           $ctot = $#{$pp->{PatchList}->[0]->{PatchPackage}};
           $btot = $#{$pp->{BlobList}->[0]->{Blob}};
           $ctot++;
           $btot++;
           last;
       }

       $pkgind++;
   }

   my @reslist = ();
   if ($match)
   {
      push(@reslist,"R");
      push(@reslist,$rfound);
      push(@reslist,-1);
      push(@reslist,$ctot);
      push(@reslist,$btot);
   }

   return @reslist;
}


#----------------------------------------------------------------------------------------
#
# nextReleaseIndex -
#
# Subroutine nextReleaseIndex is an internal housekeeping subroutine that determines the next
# index in the hashdata for a new release record element.
#
# Usage: nextReleaseIndex(hashdata)
#
# returns the next available index for a new release record in the hashdata structure.
#
sub nextReleaseIndex
{
   local($hashdata) = @_;

   my $indval = 0;

   $indval = $#{$hashdata->{ReleasePackage}};
   $indval++;

   return $indval;
}


#----------------------------------------------------------------------------------------
#
#  getReleasePatches-
#
#  Subroutine getReleasePatches returns a list of patches for a given release based on
#  a mode.
#
#  Usage: getReleasePatches(hashdata, releaseindex, mode)
#
#  returns:    if mode is 1, returns the currently installed patch packages
#              if mode is 2, returns only the pending patch packages
#
sub getReleasePatches
{
   local($hashdata, $rind, $mode) = @_;

   my @retval = ();

   if ($rind > -1)
   {
      foreach my $rr (@{$hashdata->{ReleasePackage}->[$rind]->{PatchList}->[0]->{PatchPackage}})
      {
         $patname=$rr->{PkgName}->[0];
         $pattype=$rr->{PatchType}->[0];
         $inord=$rr->{InstallOrder}->[0];
         $inflag=$rr->{InstFlag}->[0];
         $peflag=$rr->{PendingFlag}->[0];
         $stord=$rr->{StoreOrder}->[0];

         if (($inflag eq "TRUE") && ($mode == 1))
         {
            my @trr = ();
            push(@trr, $inord);
            push(@trr, $patname);
            push(@trr, $pattype);

            push @retval, [ @trr ];
         }

         if (($peflag eq "TRUE") && ($mode == 2))
         {
            my @trr = ();
            push(@trr, $stord);
            push(@trr, $patname);
            push(@trr, $pattype);

            push @retval, [ @trr ];
         }
      }
   }
   return @retval;
}


#----------------------------------------------------------------------------------------
#
#  Subroutine validRevNum returns a 1 if the revision number has 3 numeric parts, separated
#  by a period.
#
#  Usage: validRevNum(revisionNumber)
#
sub validRevNum
{
   local($rnum) = @_;
   @revs = split(/\./,$rnum);

   if ($#revs == 2)
   {
      foreach $k (0..$#revs)
      {
         if ($revs[$k] =~ /[a-zA-Z]/)
         {
            print "Each revnum part must contain only digits.\n";
            return 0;
         }
      }
   }
   else
   {
      print "The revnum argument requires exactly 3 integers separated by decimal.  (eg. 3.121.55)\n";
      return 0;
   }
   return 1;
}


#----------------------------------------------------------------------------------------
#
#   Subroutine validFileType return 1 if package type parameter is valid.
#
#   Usage: validFileType(filetype)
#
sub validFileType
{
   local($ftype) = @_;
   if (($ftype eq "ISO") || ($ftype eq "GHO") || ($ftype eq "ZIP") || ($ftype eq "DIR"))
   {
      return 1;
   }
   if (($ftype eq "EXE") || ($ftype eq "OTHER"))
   {
      return 1;
   }
   print "The filetype argument does not contain a valid value (ISO,GHO,ZIP,DIR,EXE,BAT,OTHER).\n";
   return 0;
}


#----------------------------------------------------------------------------------------
#
#   Subroutine validPkgType return 1 if package type parameter is valid.
#
#   Usage: validPkgType(pkgtype)
#
sub validPkgType
{
   local($ptype) = @_;
   if (($ptype eq "AA") || ($ptype eq "AF") || ($ptype eq "AS") || ($ptype eq "AD") || ($ptype eq "AP"))
   {
      return 1;
   }
   if (($ptype eq "OA") || ($ptype eq "OS") || ($ptype eq "OD") || ($ptype eq "OP"))
   {
      return 1;
   }
   if (($ptype eq "SA") || ($ptype eq "SS") || ($ptype eq "SD") || ($ptype eq "SV"))
   {
      return 1;
   }
   print "The pkgtype argument does not contain a valid value (AA,AF,AS,AD,AP,OA,OS,OD,OP,SA,SS,SD,SV).\n";
   return 0;
}


#----------------------------------------------------------------------------------------
sub convPkgType
{
   local($ptype) = @_;
   if (($ptype eq "AA") || ($ptype eq "AF") || ($ptype eq "AS") || ($ptype eq "AD"))
   {
      return "AP";
   }
   if (($ptype eq "OA") || ($ptype eq "OS") || ($ptype eq "OD"))
   {
      return "OP";
   }
   if (($ptype eq "SA") || ($ptype eq "SS") || ($ptype eq "SD"))
   {
      return "SV";
   }
   return $ptype;
}


#----------------------------------------------------------------------------------------
#
# getMajorMinor -
#
# Subroutine returns the major and minor revision portion of the revision number for
# child to parent matching.
#
# Usage:  getMajorMinor( fullRevisionNumber )
#
#  Returns "A.B.0" of a revision number "A.B.C"
#
sub getMajorMinor
{
   local($rnum) = @_;
   @revs = split(/\./,$rnum);

   my $retval = $revs[0] . "\." . $revs[1] . "\." . "0";
   return $retval;
}


#----------------------------------------------------------------------------------------
#
#  checkIndexMD5 -
#
#  subroutine checkIndexMD5 verifies the current Package Repository index file with the
#  current MD5 checksum file md5index.xml.
#
#  Usage: checkIndexMD5()
#
#  returns:    1 - MD5 checksum passed.   0 - MD5 checksum failed.
#
sub checkIndexMD5
{
   my $md5path = @_[0];

   if ($md5path eq ""){
      $md5path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\md5index.xml";
   }

   my $systemcmd = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\fciv.exe ";
   $systemcmd .= "-v -bp " . $ENV{'INSITE2_PKGREPOS_DIR'} . " -XML " . $md5path;

   my $retval = 1;
   $retstr=`$systemcmd`;

   if ( $retstr =~ /modified/)
   {
      $retval = 0;
   }

   return $retval;
}


#----------------------------------------------------------------------------------------
#
#  updateIndexMD5 -
#
#  subroutine updateIndexMD5 generates a new MD5 checksum file md5index.xml for
#  the Package Repository index file.  Called after an update to the package repository:
#  package add, delete, update, etc.
#
#  Usage: updateIndexMD5()
#
sub updateIndexMD5
{
   my $md5path = @_[0];

   if ($md5path eq ""){
      $md5path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\md5index.xml";
   }

   $tmppath = $md5path . ".new";

   my $systemcmd = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\fciv.exe ";
   $systemcmd .= "-add " . $ENV{'INSITE2_PKGREPOS_DIR'} . "\\reposIndex.xml" . " -wp " . $ENV{'INSITE2_PKGREPOS_DIR'} . " -XML " . $tmppath;


  `$systemcmd`;

   rename($tmppath, $md5path);
   return 1;
}


#----------------------------------------------------------------------------------------
#
#  processInstallList -
#
#  Subroutine processInstallList creates an ordered list of all installed packages, regardless
#  of type, patch or release.  A mode is passed to process this list differently.
#
#  Usage: processInstallList(hashdata, mode, packagetype)
#
#  packagetype can be OP or AP for Operating System (GHO), or AP (application).
#
#  returns:     if mode is 1, previous patch list
#               if mode is 2, current patch list
#               if mode is 11, previous release package
#               if mode is 12, current release package

sub processInstallList
{
  ($hashdata, $mode, $ptype)=@_;

  my @ilist=fillInstarray($hashdata);

  my @junk = ();
  my %pns = ();
  my %pts = ();

  my $debug = 0;
  my $afflag = 0;

  for $dd (0..$#ilist)
  {
     $pns{$ilist[$dd][0]} = $ilist[$dd][1];
     $pts{$ilist[$dd][0]} = $ilist[$dd][2];

     if ( $ilist[$dd][2] eq "AF")
     {
        $afflag = 1;
     }
     push(@junk, $ilist[$dd][0]);
  }

  @olist = sort ascending @junk;

  if ($debug)
  {
   for $a (0..$#olist)
   {
      print "$olist[$a]: $pts{$olist[$a]}: $pns{$olist[$a]} :: $afflag\n";
   }  
  }

  my $currAppl = -1;
  my $prevAppl = -1;
  my $cAP = -1;
  my $pAP = -1;
  my $cOP = -1;
  my $pOP = -1;

  my $ptcmp = "AP";

  my $maxnum=$#olist;
  for my $g (0..$#olist)
  {
     my $f = $maxnum - $g;

     my $pt = convPkgType($pts{$olist[$f]});

     if ($debug)
     {
        print "--->>>  $maxnum,   $g, $f, $pt, $ptcmp, $pts{$olist[$f]}.\n";
     }

     if (($pt eq $ptcmp) || ($pt eq "AF") || ($pts{$olist[$f]} eq $ptcmp) || ($pts{$olist[$f]} eq "OP"))
     {
        if ($pt eq "AP"){
           if ($currAppl < 0){
              $currAppl = $f;
           }
           elsif ($prevAppl < 0){
              $prevAppl = $f;
           }
        }

        if (($pts{$olist[$f]} eq "AP") || 
            ($pts{$olist[$f]} eq "AF")) {
           if (($currAppl > -1) && ($cAP < 0)){
              $cAP = $f;
           }
           if (($prevAppl > -1) && ($pAP < 0)){
              $pAP = $f;
           }
        }

        if ($pts{$olist[$f]} eq "OP") {
           if (($currAppl > -1)) {
              if ((!$afflag) || ($cOP < 0))
              {
                 $cOP = $f;
              }
           }
           if (($prevAppl > -1)) {
              if ((!$afflag) || ($pOP < 0))
              {
                 $pOP = $f;
              }
           }
        }
     }
  }

  if ($debug)
  {
     print "currAppl: $currAppl     prevAppl: $prevAppl\n";
     print "cAp: $cAP  $olist[$cAP]  $pns{$olist[$cAP]}       pAP: $pAP  $olist[$pAP]  $pns{$olist[$pAP]}\n";
     print "cOP: $cOP  $olist[$cOP]  $pns{$olist[$cOP]}       pOP: $pOP  $olist[$pOP]  $pns{$olist[$pOP]}\n";
     print "mode: $mode\n";
  }

  my @retval = ();

  # returns the previous patch list
  if ($mode == 1)
  {
     if ($pts{$olist[$prevAppl]} eq "AF")
     {
     }
     if ($ptype eq "OP")
     {
        my $start = $pOP + 1;
        my $stop = $pAP - 1;
        for my $b ($start..$stop)
        {
           if (convPkgType($pts{$olist[$b]}) eq "OP")
           {
              my @trr = ();
              push(@trr, $olist[$b]);
              push(@trr, $pns{$olist[$b]});
              push(@trr, $pts{$olist[$b]});

              push @retval, [ @trr ];
           }
        }
     }
     elsif ($ptype eq "AP")
     {
        my $start = $pAP + 1;
        my $stop = $prevAppl;
        for my $b ($start..$stop)
        {
           if (convPkgType($pts{$olist[$b]}) eq "AP")
           {
              my @trr = ();
              push(@trr, $olist[$b]);
              push(@trr, $pns{$olist[$b]});
              push(@trr, $pts{$olist[$b]});
              push @retval, [ @trr ];
           }
        }
     }
     else
     {
        my $strt = 0;
        if ($afflag)
        {
           $strt = $pOP + 1;
        }
        else
        {
           $strt = $pAP + 1;
        }
        my $stop = $prevAppl;
        for my $b ($strt..$stop)
        {
           my @trr = ();
           push(@trr, $olist[$b]);
           push(@trr, $pns{$olist[$b]});
           push(@trr, $pts{$olist[$b]});
           push @retval, [ @trr ];
        }
     }
  }

  # returns the current patch list
  if ($mode == 2)
  {
     if ($ptype eq "OP")
     {
        my $start = $cOP + 1;
        my $stop = $cAP - 1;
        for my $b ($start..$stop)
        {
           if (convPkgType($pts{$olist[$b]}) eq "OP")
           {
              my @trr = ();
              push(@trr, $olist[$b]);
              push(@trr, $pns{$olist[$b]});
              push(@trr, $pts{$olist[$b]});

              push @retval, [ @trr ];
           }
        }
     }
     elsif ($ptype eq "AP")
     {
        my $start = $cAP + 1;
        my $stop = $currAppl;
        for my $b ($start..$stop)
        {
           if (convPkgType($pts{$olist[$b]}) eq "AP")
           {
              my @trr = ();
              push(@trr, $olist[$b]);
              push(@trr, $pns{$olist[$b]});
              push(@trr, $pts{$olist[$b]});
              push @retval, [ @trr ];
           }
        }
     }
     else
     {
        my $strt = 0;
        if ($afflag)
        {
           $strt = $cOP + 1;
        }
        else
        {
           my $strt = $cAP + 1;
        }
        my $stop = $currAppl;
        for my $b ($strt..$stop)
        {
           my @trr = ();
           push(@trr, $olist[$b]);
           push(@trr, $pns{$olist[$b]});
           push(@trr, $pts{$olist[$b]});
           push @retval, [ @trr ];
        }
     }
  }

  # returns the name of the previous release package
  if ($mode == 11)
  {
     my $retpkg = "";

     if ($ptype eq "OP")
     {
        if ($pOP > -1)
        {
           $retpkg = $pns{$olist[$pOP]};
        }
     }
     else
     {
        if (!$afflag)
        {
           if ($pAP > -1)
           {
              $retpkg = $pns{$olist[$pAP]};
           }
        }
        else
        {
           if ($prevAppl > -1)
           {
              $retpkg = $pns{$olist[$prevAppl]};
           }
        }
     }
     return $retpkg;
  }

  # returns the name of the current release package
  if ($mode == 22)
  {
     my $retpkg = "";
     if ($ptype eq "OP")
     {
        if ($cOP > -1)
        {
           $retpkg = $pns{$olist[$cOP]};
        }
     }
     else
     {
        if (!$afflag)
        { 
           if ($cAP > -1)
           {
              $retpkg = $pns{$olist[$cAP]};
           }
        }
        else
        {
           if ($currAppl > -1)
           {
              $retpkg = $pns{$olist[$currAppl]};
           }
        }
     }
     return $retpkg;
  }

  return @retval;

}

MAIN:
{
  1;
}