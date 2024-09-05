#!D:/Program Files/InSite2/Perl/bin/perl.exe
#
#   updateServiceAgent.cgi - Accepts values from the referencing Config Tool
#   document, checks for valid values, and updates the the Questra Agent config
#   files.  This script also displays an update status/error page with a link
#   back to the Config Tool page.
#
#   The script updates system specific values in the file
#   %INSITE2_DATA_DIR%\etc\sitemap.xml, saving a copy
#   in *.old.  It then executes the script
#   %INSITE2_ROOT_DIR%\bin\gencfg.cmd, applying the
#   sitemap.xml values across numerous config file templates.  The final
#   resultant config files are found in
#   %INSITE2_DATA_DIR%\etc.
#

use CGI ':standard';
use CookieMonster;

sub FiltChar{
	my $datastr = @_[0];

      $datastr =~ s/&/&amp;/g;
      $datastr =~ s/'/&apos;/g;
      $datastr =~ s/"/&quot;/g;
      $datastr =~ s/</&lt;/g;
      $datastr =~ s/>/&gt;/g;
     
	return $datastr;
}

sub CreLine{

     my $fixline = @_[0];
     my $fldvalue = @_[1];

     my $replvalue = FiltChar($fldvalue);

     $fixline =~ s/>.*</>$replvalue</;
     return $fixline;
}

#  Get config tool form parameters for possible update to agent files.
#
$devname = param('DeviceName');
$sernum = param('SerialNumber');
$descript = param('AgentDescription');

$addrLine1 = param('AddressLine1');
$addrLine2 = param('AddressLine2');
$addrCity = param('City');
$addrState = param('State');
# Ignore "<Select ...>" option selection
if ($addrState=~/^&lt;Select .+&gt;$/)
{
	$addrState="";
}
$addrPostal = param('PostalCode');
$addrCountry = param('Country');
# Ignore "<Select ...>" option selection
if ($addrCountry=~/^&lt;Select .+&gt;$/)
{
	$addrCountry="";
}
$addrContinent = param('Continent');
# Ignore "<Select ...>" option selection
if ($addrContinent=~/^&lt;Select .+&gt;$/)
{
	$addrContinent="";
}
$addrLon = param('Longitude');
$addrLat = param('Latitude');
$addrInstitution = param('Institution');
$addrDepartment = param('Department');
$addrBuilding = param('Building');
$addrFloor = param('Floor');
$addrRoom = param('Room');
$svcCenter = param('SvcCenter');

$friendlyName = param('FriendlyName');
$watchflag = param('WatchEnable');
$watchDir = param('WatchDir');
$watchFilter = param('WatchFilter');

$entsrv = param('EntServer');        # User enterprise selection - Staging, Development, Production, Other, etc.
$proxyflag = param('ProxyEnable');   # Proxy Service enabled?
$proxyip = param('ProxyIP');
$proxyport = param('ProxyPort');
$currname = param('CurrentName');    # Device name in current agent config file version.
$prevflag = param('PrevFlag');       # Proxy enable flag in current agent config file version.
$loglevel = param('LogLevel');       # Questra agent's logging level - WARN, INFO, ERROR, TRACE, etc
$filerepos = param('FileRepository');
$authflag = param('AuthEnable');     # Proxy Authenication enabled?
$authuser = param('AuthUser');
$authpass = param('AuthPassword');
$authscheme = param('AuthScheme');
$userEntURL = param('UserEntURL');   # Enterprise server URL input.
$userTunURL = param('UserTunURL');   # Enterprise tunnel URL input.
$userlevel = param('UserLevel');     # Is the user GE Service or other?

$fatalerror = "0";   # if set, product error message and don't update agent config file.
$warning = "0";
$message = "";

$myAgentRootDir = $ENV{"INSITE2_ROOT_DIR"};
$myDataRootDir = $ENV{"INSITE2_DATA_DIR"};

#  Display helpful error or status messages on a new screen.  Provide a GO BACK button to return to the
#  Agent Config tool screen.
#
if ($myAgentRootDir eq "")
{
   $message = "INSITE2_ROOT_DIR evironment variable doesn't exist. InSite2 is not installed or not properly installed.";
   $fatalerror = "1";
}
elsif (($devname eq "") || ($devname =~ /DEFAULT/) || ($devname =~ /UNKNOWN/) || ($devname =~ /[Dd]efault/) || ($devname =~ /[Uu]nknown/))
{
   $message = "You must specify a valid Device Name.";
   $fatalerror = "1";
}
elsif (($sernum eq "") || ($sernum eq "UNKNOWN") || ($sernum =~ /^[Uu]nknown$/))
{
   $message = "You must specify a valid CRM Number.";
   $fatalerror = "1";
}
elsif (($entsrv eq "OTHER") && (($userEntURL eq "") || ($userTunURL eq "")))
{
   $message = "If <b>OTHER</b> Enterprise Server selected, you must enter\nvalid Enterprise Server and Enterprise Tunnel URLs.";
   $fatalerror = "1";
}
elsif (($proxyflag eq "1") && (($proxyip eq "") || (($proxyport eq "") && ($proxyip !~/:/))))
{
   $message = "If Proxy enabled, you must enter a\nvalid Proxy Server IP Address and Proxy port.";
   $fatalerror = "1";
}

else
{
# no error:  normal messages
	if ($currname eq $devname)
	{
		$message = "<b>New agent configuration for device $devname.</b>  \n\nThe InSite ExC Agent will now be started/restarted.";
	}
	else
	{
		$message = "<b>A new device $devname will be created.</b>  \n\nThe InSite ExC Agent will now be started/restarted.";
	}
}

print "Content-type:text/html\n\n";
print "<html>";
print "<head>";
print "<style type=\"text/css\">";
print "body {color: #000;}";
print "</style>";
print "</head>";
print "<body  bgcolor=#b5b5b5>";
print "<pre>";

if ($fatalerror eq "1")
{
   print "<H3><font color=red>ERROR: No Configuration changes were made.</font></H3>\n";
   print "$message\n\n";
   print "<b>Please \"<font color=green>Go Back</font>\" and enter valid selections.</b>\n\n";
}
elsif ($warning eq "1")
{
   print "<H3><font color=brown>WARN: Configuration changes were made.</font></H3>\n";
   print "$message\n\n";
   print "<b>If you'd like, you may \"<font color=green>Go Back</font>\" and review selections.</b>\n\n";
}
else
{
   print "$message\n\n";
   print "<b>If you'd like, you may \"<font color=green>Go Back</font>\" and review selections.</b>\n\n";
}
print "</pre>";

print "<FORM METHOD=\"POST\" ACTION=\"/uscgi-bin/ShowAgentConfigTool.cgi\">";
print "<P><INPUT TYPE=submit VALUE=\"Go Back\"></P>";
print "</FORM>";

print "</body>";
print "</html>";


#  If some cursory check reveals some incompatible entries in the config tool screen, an error is display above.
#  No updates are performed on any config files.
#
if ($fatalerror ne "1")     # no error
{

   #  Locate the current agent config files.
   #
   $SiteMapFile = $myDataRootDir . "/etc/sitemap.xml";
   $SaveMapFile = $myDataRootDir . "/etc/sitemap.xml.old";
   $NewSiteMapFile = $myDataRootDir . "/etc/newsitemap.xml";
   $Save1MapFile = $myDataRootDir . "/etc/sitemap.xml.old.1";
   $Save2MapFile = $myDataRootDir . "/etc/sitemap.xml.old.2";

   open(OLDMAPFILE, $SiteMapFile);
   @MapFileLines = <OLDMAPFILE>;
   chop(@MapFileLines);
   close(OLDMAPFILE);

   open(OUT, ">$NewSiteMapFile");

   select(OUT);

   #  In general, substitute the new value in the proper "replace" directive
   #  in the sitemap.xml.
   #
   for $a ( 0..$#MapFileLines )
   {
      $newline = @MapFileLines[$a];

	if (@MapFileLines[$a] =~ /__SA_ASSET_NAME__/)
      {
             $newline = CreLine($newline, $devname);
             print "$newline\n";
	}

      elsif (@MapFileLines[$a] =~ /__SA_ASSET_SERIAL_NUMBER__/)
      {
            $newline = CreLine($newline, $sernum);
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__SA_ASSET_DESCRIPTION__/)
      {

             $newline = CreLine($newline, $descript);
             print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__LOG_LEVEL__/)
      {
            $newline =~ s/>.*</>$loglevel</;
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__FILE_REPOS_DIR__/)
      {
            $newline =~ s/>.*</>$filerepos</;
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__FILE_WATCHER_DIR__/)
      {
            if ($watchflag eq "1")
            {
               $newline =~ s/>.*</>$watchDir</;
            }
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__FILE_WATCHER_FILTER__/)
      {
            if ($watchflag eq "1")
            {
               $newline = CreLine($newline, $watchFilter);
            }
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__PROXY_SERVER__/)
      {
			if ($proxyflag eq "1")
			{
				if (($proxyport eq "") && ($proxyip =~/:/)) 
				{
					$newline =~ s/>.*</>$proxyip</;
				}
				elsif (($proxyport ne "") && ($proxyip =~/:/)) 
				{
					$proxyip =~ s/:.*//;
					$newline =~ s/>.*</>$proxyip:$proxyport</;
				}
				else
				{
					$newline =~ s/>.*</>$proxyip:$proxyport</;
				}
			}
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__PROXY_AUTH_USERNAME__/)
      {
            if ($authflag eq "1")
            {
               $newline = CreLine($newline, $authuser);
            }
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__PROXY_AUTH_PASSWORD__/)
      {
            if ($authflag eq "1")
            {
               $newline = CreLine($newline, $authpass);
            }
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__PROXY_AUTH_SCHEME__/)
      {
            if ($authflag eq "1")
            {
               $newline =~ s/>.*</>$authscheme</;
            }
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__SA_ASSET_FRIENDLY_NAME__/)
      {
            $newline = CreLine($newline, $friendlyName);
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__SA_LONGITUDE__/)
      {
            $newline =~ s/>.*</>$addrLon</;
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__SA_LATITUDE__/)
      {
            $newline =~ s/>.*</>$addrLat</;
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__SA_ADDRESS_LINE1__/)
      {
            $newline = CreLine($newline, $addrLine1);
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__SA_ADDRESS_LINE2__/)
      {
            $newline = CreLine($newline, $addrLine2);
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__SA_CITY__/)
      {
            $newline = CreLine($newline, $addrCity);
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__SA_STATE__/)
      {
            $newline =~ s/>.*</>$addrState</;
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__SA_POSTALCODE__/)
      {
            $newline =~ s/>.*</>$addrPostal</;
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__SA_COUNTRY__/)
      {
            $newline = CreLine($newline, $addrCountry);
            print "$newline\n";
      }
	  
	  elsif (@MapFileLines[$a] =~ /__SA_CONTINENT__/)
      {
            $newline = CreLine($newline, $addrContinent);
            print "$newline\n";
      }
	  
	  elsif (@MapFileLines[$a] =~ /__SA_INSTITUTION__/)
      {
            $newline = CreLine($newline, $addrInstitution);
            print "$newline\n";
      }
	  
	  elsif (@MapFileLines[$a] =~ /__SA_DEPARTMENT__/)
      {
            $newline = CreLine($newline, $addrDepartment);
            print "$newline\n";
      }
	  
	  elsif (@MapFileLines[$a] =~ /__SA_BUILDING__/)
      {
            $newline = CreLine($newline, $addrBuilding);
            print "$newline\n";
      }
	  
	  elsif (@MapFileLines[$a] =~ /__SA_FLOOR__/)
      {
            $newline = CreLine($newline, $addrFloor);
            print "$newline\n";
      }
	  
	  elsif (@MapFileLines[$a] =~ /__SA_ROOM__/)
      {
            $newline = CreLine($newline, $addrRoom);
            print "$newline\n";
      }
	  
	  elsif (@MapFileLines[$a] =~ /__SA_SERVICE_CENTER__/)
      {
            $newline = CreLine($newline, $svcCenter);
            print "$newline\n";
      }
	  
	  elsif (@MapFileLines[$a] =~ /__PROXY_SCHEME__/)
      {
			if ($proxyflag eq "1")
			{
				$newline = CreLine($newline, "TRUE");
			}
			else
			{
				$newline = CreLine($newline, "FALSE");
			}
				
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /ProxyServerAddress|CS_GSP_PXY_ADD/)
      {

            # Here, determine if the ProxyServer template nodes and CS_GSP_PXY_ADD property should be
            # marked as delete from templates.... i.e. was it enabled
            # on the config tool screen?
            #
            #  If <node>TEMPLATE NODE</node> node is commented out, that
            #  "TEMPLATE NODE" will be included in the config file.   If
            #  <node> is not commented out, that "TEMPLATE NODE" will
            #  not be included in the config file.
            #
            if ($prevflag ne $proxyflag)
            {
               if ($proxyflag eq "1")
               {
                  $newline =~ s/<node>/<!--node>/;
                  $newline =~ s/<\/node>/<\/node-->/;
               }
               else
               {
                  $newline =~ s/<!--node>/<node>/;
                  $newline =~ s/<\/node-->/<\/node>/;
               }
            }
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /AuthScheme/)
      {
            #  If NONE authenication scheme was selected in the config tool,
            #  mark the node as delete from templates... other selections will
            #  include the node.
            #
            #  If <node>TEMPLATE NODE</node> node is commented out, that
            #  "TEMPLATE NODE" will be included in the config file.   If
            #  <node> is not commented out, that "TEMPLATE NODE" will
            #  not be included in the config file.
            #
            if ($authscheme ne "NONE")
            {
               if (@MapFileLines[$a] =~ /<node>/)
               {
                  $newline =~ s/<node>/<!--node>/;
                  $newline =~ s/<\/node>/<\/node-->/;
               }
            }
            else
            {
               if (@MapFileLines[$a] =~ /<!--node>/)
               {
                  $newline =~ s/<!--node>/<node>/;
                  $newline =~ s/<\/node-->/<\/node>/;
               }
            }
            print "$newline\n";

      }

      elsif (@MapFileLines[$a] =~ /LatLonCoordinates/)

      {
            if (($addrLat ne "") && ($addrLon ne ""))
            {
               if (@MapFileLines[$a] =~ /<node>/)
               {
               # enables if values valid and previously disabled.
               #
                  $newline =~ s/<node>/<!--node>/;
                  $newline =~ s/<\/node>/<\/node-->/;
               }
            }
            else
            {
               if (@MapFileLines[$a] =~ /<!--node>/)
               {
               # disables if values not valid and previously enabled.
               #
                  $newline =~ s/<!--node>/<node>/;
                  $newline =~ s/<\/node-->/<\/node>/;
               }
            }
            print "$newline\n";
      }

	elsif (@MapFileLines[$a] =~ /FileWatcher/)
      {
            if ($watchflag eq "1")
            {
               if (@MapFileLines[$a] =~ /<node>/)
               {
                  $newline =~ s/<node>/<!--node>/;
                  $newline =~ s/<\/node>/<\/node-->/;
               }
            }
            else
            {
               if (@MapFileLines[$a] =~ /<!--node>/)
               {
                  $newline =~ s/<!--node>/<node>/;
                  $newline =~ s/<\/node-->/<\/node>/;
               }
            }
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /ProxyServerAuthorization/)
      {

            #  Here, determine if the Proxy Server Authorization should be marked
            #  as delete from templates... i.e. was authorization enabled in the
            #  agent config tool screen?
            #
            if ($authflag eq "1")
            {
               if (@MapFileLines[$a] =~ /<node>/)
               {
                  $newline =~ s/<node>/<!--node>/;
                  $newline =~ s/<\/node>/<\/node-->/;
               }
            }
            else
            {
               if (@MapFileLines[$a] =~ /<!--node>/)
               {
                  $newline =~ s/<!--node>/<node>/;
                  $newline =~ s/<\/node-->/<\/node>/;
               }
            }
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__ENT_URL__/)
      {
			$newline = CreLine($newline, $userEntURL);
            print "$newline\n";
      }

      elsif (@MapFileLines[$a] =~ /__TUN_URL__/)
      {
		    $newline = CreLine($newline, $userTunURL);
            print "$newline\n";
      }

      else
      {
      #  We aren't changing other lines in sitemap.xml, so just pass through untouched.
      #
            print "$newline\n";

      }
   } 

   close(OUT);

   # Move the old sitemap to *.old.  Copy new sitemap.
   #
   if (-e $Save1MapFile)
   {
      rename($Save1MapFile, $Save2MapFile);
   }
   if (-e $SaveMapFile)
   {
      rename($SaveMapFile, $Save1MapFile);
   }
   rename($SiteMapFile, $SaveMapFile);
   rename($NewSiteMapFile, $SiteMapFile);

   # Generate an updated set of config files.
   #
   $gencmd = "";
   $gencmd = "\"\"%INSITE2_ROOT_DIR%\\bin\\gencfg.cmd\" -template \"";
   $gencmd .= "%INSITE2_DATA_DIR%\\etc\\templates\\qsa\" -cfgdir \"";
   $gencmd .= "%INSITE2_DATA_DIR%\\etc\"\"";

   $gencmd =~ s/\\/\//g;

   CookieMonster::runCommand($gencmd);

   # Check if the name has changed.  The C:\WINDOWS\qsacfg\<$devname> directory
   # will be created for the new device name, if changed.

   if ($currname ne $devname)
   {

      $Checkwin = "";
      $Checkwin = "C:/WINDOWS/qsacfg";

      if (-d $Checkwin)
      {
         $delcmd = "";
         $delcmd = "rmdir /S /Q C:\\WINDOWS\\qsacfg";

         CookieMonster::runCommand($delcmd);
      }
      
      $newcmd = "";
	  $newcmd = "mkdir C:\\WINDOWS\\qsacfg";

	  CookieMonster::runCommand($newcmd);

      # Copy file into windows.

      $newcmd = "";
      $newcmd = "mkdir C:\\WINDOWS\\qsacfg\\" . $devname;
      CookieMonster::runCommand($newcmd);

      $cpycmd = "";

      $cpycmd = "copy /Y \"" . $myDataRootDir;
      $cpycmd .= "\\etc\\sitedefs.txt\" ";
      $cpycmd .= "C:\\WINDOWS\\qsacfg\\" . $devname;

      CookieMonster::runCommand($cpycmd);

      # ... and change permissions to allow all read, execute access.

      $chmodcmd = "ECHO Y| CACLS C:\\WINDOWS\\qsacfg\\" . $devname;
      $chmodcmd .= "\\sitedefs.txt /G EVERYONE:F";

      CookieMonster::runCommand($chmodcmd);
   }
   
   # The following perl script will update %INSITE2_HOME%\Questra\AgentConfig.xml file
   # which will be used with UpdateAgentConfig.bat
   $insite2home = $ENV{"INSITE2_HOME"};
   $extractsitemap = "\"\"" . $ENV{"PERL_HOME"} . "bin\\perl\" \"" . $insite2home . "\\Questra\\ExtractSitemap.pl\" \"";
   $extractsitemap = $extractsitemap . $myDataRootDir . "\\etc\\sitemap.xml\" \"" .  $insite2home . "\\Questra\\AgentConfig.xml\"\"";
   CookieMonster::runCommand($extractsitemap);
   
   # The following batch will
   # not only create the Questra agent service (or make it an Auto Process)
   # but also start/restart the service or process depending on the install option.
   CookieMonster::runCommand("\"".$insite2home."\\Questra\\QSAServiceCreate.bat\"");

}  # if not fatal error

exit 0;
