$path = $ENV{'INSITE2_PKGREPOS_DIR'} . "\\bin\\prapi-lib.pl";

require $path;

#
#  Reduces patch segments by removing patches of same type that were installed
#  prior to a like-accumulative patch.  If segment is AA,AS,AS,AA ... this would
#  reduce to the last AA patch only for re-load.
#
sub reduceSegment
{
    local($min, $max) = @_;
    $maxAA = -1;

    $famtype = convPkgType($ptypes{$ordpat[$min]});

    my $acctype = "";
    my $fulltype = "";
    my $matchstr = "";

    if ($famtype eq "AP")
    {
       $acctype = "AA";
       $fulltype = "AF";
    }
    elsif ($famtype eq "OP")
    {
       $acctype = "OA";
    }
    elsif ($famtype eq "SV")
    {
       $acctype = "SA";
    }

    for $x ($min..$max)
    {
       if ($ptypes{$ordpat[$x]} eq $acctype)
       {
          $maxAA = $x;
       }
    }

    for $t ($min..$max)
    {
       if (($ptypes{$ordpat[$t]} eq $fulltype) || ($t >= $maxAA))
       {
           push(@f4, $ordpat[$t]);
       }
    }

}

$usage = "PAgetPatchList [pkgtype=<ptype][-current | -previous | -pending][-h]\n";
$usage .= " : returns current, previous, or pending patchlists.\n";
$usage .= "   -pkgtype=<ptype>  search releases of <ptype>\n";
$usage .= "   -current    return current patch list\n";
$usage .= "   -previous   return previous patch list\n";
$usage .= "   -pending    return pending patch list\n";
$usage .= "   -h shows usage";

my $retval = "";
my $debug = 0;

if (processArgs($usage, 1)){
   if (checkIndexMD5())
   {
      if ($Arg_helpflag)
      {
          # help was requested.  Exit here.
          exit 0;
      }
      elsif ((!$Arg_pendingflag) && (!$Arg_currentflag) && (!$Arg_previousflag))
      {
          # no valid list indentifier was provided.
          print "Not all required arguments are provided.\n";
          print "$usage\n";
          exit 1;
      }

      $hash1 = readXML();

      if ($hash1)
      {

          my $md = 1;
          my $fndpkg = -1;
          my $fndpkg2 = -1;
          if ($Arg_currentflag)
          {
              if ($Arg_pkgtype)
              {
                 @plist = processInstallList($hash1, 2, $Arg_pkgtype);
              }
              else
              {
                 @plist = processInstallList($hash1, 2);
              }
          }
          elsif ($Arg_previousflag)
          {
              if ($Arg_pkgtype)
              {
                 @plist = processInstallList($hash1, 1, $Arg_pkgtype);
              }
              else
              {
                 @plist = processInstallList($hash1, 1);
              }
          }
          elsif ($Arg_pendingflag)
          {
              $md = 2;
              if ($Arg_pkgtype)
              {
                 $fndpkg = findPendRelPtr($hash1, $Arg_pkgtype);
              }
              else {
                 $fndpkg = findPendRelPtr($hash1);
              }
              if ($fndpkg < 0)
              {
                 if ($Arg_pkgtype)
                 {
                    $fndpkg = findCurrRelPtr($hash1, $Arg_pkgtype);
                 } else {
                    $fndpkg = findCurrRelPtr($hash1);
                 }
              }
              if ($fndpkg > -1)
              {
                 @plist = getReleasePatches($hash1, $fndpkg, $md);
              }
          }


              @unsorted = ();
              %pnames = ();
              %ptypes = ();
              
              for $dd (0..$#plist)
              {
                  $pnames{$plist[$dd][0]} = $plist[$dd][1];
                  $ptypes{$plist[$dd][0]} = $plist[$dd][2];
                  push(@unsorted, $plist[$dd][0]);
              }

              @ordpat = sort ascending @unsorted;

              if ($debug) {
                 for $a (0..$#ordpat)
                 {
                    print "$ordpat[$a]: $ptypes{$ordpat[$a]}: $pnames{$ordpat[$a]}\n"
                 }
              }

              # identify pkgtype segments

              @f4 = ();
             
              $currtype = "";
              $bstart = -1;
              $bend = -1;
 
              for $b (0..$#ordpat)
              {
                 $chktype = "AF";
                 if ($ptypes{$ordpat[$b]} ne "AF")
                 {
                    $chktype = convPkgType($ptypes{$ordpat[$b]});
                 }
                 if ($chktype ne $currtype)
                 {
                    if ($bstart > -1)
                    {
                       $bend = $b - 1;
                       reduceSegment($bstart, $bend);
                    }
                    $currtype = $chktype;
                    $bstart = $b;
                 }
              }

              # handles the final segment
              reduceSegment($bstart, $#ordpat);

              if ($debug){
print "------\n";
                  for $a (0..$#f4)
                  {
                      print "$f4[$a]: $ptypes{$f4[$a]}: $pnames{$f4[$a]}\n";
                  }
print "-----------\n";
              }

              $maxAA = -1;
              for $b (0..$#f4)
              {
                  if ($ptypes{$f4[$b]} eq "AA")
                  {
                      $maxAA = $b;
                  }
              }

              @ordpat = ();
              for $d (0..$#f4)
              {
                  $chktype = "AF";
                  if ($ptypes{$f4[$d]} ne "AF")
                  {
                     $chktype = convPkgType($ptypes{$f4[$d]});
                  }
                  if (($chktype ne "AP") || ($d >= $maxAA))
                  {
                     push(@ordpat, $f4[$d]);
                  }
              }

              if ($debug){
print "------\n";
                  for $a (0..$#ordpat)
                  {
                      print "$ordpat[$a]: $ptypes{$ordpat[$a]}: $pnames{$ordpat[$a]}\n";
                  }
print "-----------\n";
              }

              @f4 = ();

              # identify pkgtype segments
             
              $currtype = "";
              $bstart = -1;
              $bend = -1;
 
              for $b (0..$#ordpat)
              {
                 $chktype = convPkgType($ptypes{$ordpat[$b]});
                 if ($chktype ne $currtype)
                 {
                    if ($bstart > -1)
                    {
                       $bend = $b - 1;
                       reduceSegment($bstart, $bend);
                    }
                    $currtype = $chktype;
                    $bstart = $b;
                 }
              }

              # handles the final segment
              reduceSegment($bstart, $#ordpat);

              if ($debug){
print "------\n";
                  for $a (0..$#f4)
                  {
                      print "$f4[$a]: $ptypes{$f4[$a]}: $pnames{$f4[$a]}\n";
                  }
print "-----------\n";
              }

              $dchr = ";";
              if ($Arg_delimchar)
              {
                 $dchr = $Arg_delimchar;
              }

              for $ff (0..$#f4)
              {
                 if ($ff > 0)
                 {
                    $retval .= $dchr;
                 }
                 $retval .= $pnames{$f4[$ff]};
              }

              if ($retval eq ";")
              {
                 $retval = "";
              }

              print "$retval";
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
