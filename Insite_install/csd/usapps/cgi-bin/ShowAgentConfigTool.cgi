#!D:\Program Files\InSite2\Perl\bin/perl.exe
#
#   ShowAgentConfigTool.cgi - Produces a forms based html page representation
#   of InSite ExC Agent configuration tool.  The Tool displays the current agent
#   configuration parameters, accepts user input, resets user input, and
#   submits final inputs to the updateServiceAgent.cgi.
#
#   This checks if the user is ClassM.  If not, a subset of the config fields
#   become static, not editable.
#
#
#

# 
#

sub ExtractData{
	my $datastr = @_[0];
      $datastr =~ s/<text.*\">//;
      $datastr =~ s/<\/text>//;
      $datastr =~ s/^\s*|\s*$//g;

      $datastr =~ s/&amp;/&/g;
      $datastr =~ s/&apos;/'/g;
      $datastr =~ s/&quot;/"/g;
      $datastr =~ s/&lt;/</g;
      $datastr =~ s/&gt;/>/g;
     
	return $datastr;
}


print "Content-type:text/html\n\n";
print "<html>";
print "<head>";
print "<style type=\"text/css\">";
print "body {color: #000;}";
print "</style>";
# print "<script src=\"/service/fileio\.js\" type=\"text/javascript\"></script>\n";
print "<script src=\"/service/ShowAgentConfigTool\.js\" type=\"text/javascript\"></script>\n";

#
# Find the current agent settings.

$MapFile = $ENV{"INSITE2_DATA_DIR"} . "/etc/sitemap.xml";

if (-e $MapFile)
{
   open(MAPFILE, $MapFile);
   @MapLines = <MAPFILE>;
   chop(@MapLines);

   close(MAPFILE);

}
else
{
    print "</head>";
    print "<body  bgcolor=#b5b5b5>";
 #   print "<center><H><b>ERROR: Cannot find current InSite ExC Agent configuration file.</b></H></center>";
    print "<pre>";
    print "<H><b>ERROR: Cannot find current InSite ExC agent configuration file.</b></H>";
    print "\n\nPlease check that the InSite ExC agent is installed.\n\n";
    print "The InSite ExC Agent Configuration tool expects the file:\n      $MapFile\n";
    print "</pre>";
    print "</body>";
    print "</html>";
    exit 1;
}

$UserLevel = "";  # GE Service will not be default

#
#  Determine the current user level.

if ($ENV{"WIP_HOME"} eq "")
{
   $AccessFile = $ENV{"TARGET_ROOT"} . "/service/svcpform/accessLog.txt";
}
else
{
   $AccessFile = $ENV{"WIP_HOME"} . "tomcat\\webapps\\modality-csd\\AccessLog.txt";
}

if (-e $AccessFile)
{
   open(ACCESSFILE, $AccessFile);
   @AccessLines = <ACCESSFILE>;
   $useraccessline = @AccessLines[$#AccessLines];

   $UserLevel = substr($useraccessline, 6, 1);
   close(ACCESSFILE);
}

$PrevAssetName = "";
$PrevDesc = "";
$PrevSerNum = "";
$ProxyLine = "";
$PrevFlag = "1";
$watchflag = "1";

$AssetType = "";
$Model = "";
$AssetTypeVersion = "";
$FriendlyName = "";

$AddrLine1 = "";
$AddrLine2 = "";
$AddrCity = "";
$AddrState = "";
$AddrPostal = "";
$AddrCountry = "";
$AddrCountinent = "";
$AddrLon = "";
$AddrLat = "";
$AddrInstitution = "";
$AddrDepartment = "";
$AddrBuilding = "";
$AddrFloor = "";
$AddrRoom = "";
$SvcCenter = "";

$proxyNoSel = "";
$proxyYesSel = "selected";     # directive that proxy enable is current selection in pulldown.
$authNoSel = "";
$authYesSel = " selected";     # directive that authenication enable is current selection.
$watchNoSel = "";
$watchYesSel = " selected";    # directive that file watcher enable is current selection.
$watchDir = "";
$watchFilter = "";
$watchLabel = "Enabled";

$proxyAddr = "";
$proxyPort = "";
$authUser = "";
$authPassword = "";
$authScheme = "";
$prevLevel = "";

$errorSel = "";    # directives for current LOG-LEVEL pulldown selection... ERROR, TRACE, INFO, or WARN.
$infoSel = "";
$warnSel = "";
$traceSel = "";
$filerepos = "";
$noneSel = "";     # directives for current Authentication scheme pulldown selection.. NONE, ntml, DIGEST, or BASIC.
$ntmlSel = "";
$digestSel = "";
$basicSel = "";

#
#  Loop thru the current config settings and extract
#  the editable config values.

for $a ( 0..$#MapLines )
{
	if (@MapLines[$a] =~ /SA_ASSET_NAME/)
      {
		$PrevAssetName = ExtractData(@MapLines[$a]);
	}
      elsif (@MapLines[$a] =~ /SA_ASSET_DESCRIPTION/)
      {
            $PrevDesc = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /SA_ASSET_SERIAL_NUMBER/)
      {
            $PrevSerNum = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /TUN_URL/)
      {
            $userTunURL = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /ENT_URL/)
      {
            $userEntURL = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /LOG_LEVEL/)
      {
            if (@MapLines[$a] =~ /TRACE/)
            {
                $prevLevel = "TRACE";
		    $traceSel = " selected";
            }
            elsif (@MapLines[$a] =~ /INFO/)
            {
                $prevLevel = "INFO";
                $infoSel = " selected";
            }
            elsif (@MapLines[$a] =~ /ERROR/)
            {
	          $prevLevel = "ERROR";
                $errorSel = " selected";
            }
            else
            {
                $prevLevel = "WARN";
 		    $warnSel = " selected";
            }
      }
      elsif (@MapLines[$a] =~ /__PROXY_AUTH_SCHEME__/)
      {
            if (@MapLines[$a] =~ /NONE/)
            {
                $noneSel = " selected";
            }
            elsif (@MapLines[$a] =~ /NTLM/)
            {
                $ntlmSel = " selected";
            }
            elsif (@MapLines[$a] =~ /Digest/)
            {
                $digestSel = " selected";
            }
            else
            {
                $basicSel = " selected";
            }
      }
      elsif (@MapLines[$a] =~ /<node>/)
      {
            if (@MapLines[$a] =~ /ProxyServerAddress/)
            {
                $proxyYesSel = "";
                $proxyNoSel = " selected";
                $PrevFlag = "0";
            }
            if (@MapLines[$a] =~ /ServerAuthorization</)
            {
                $authYesSel = "";
                $authNoSel = " selected";
            }
            if (@MapLines[$a] =~ /FileWatcher/)
            {
                $watchYesSel = "";
                $watchNoSel = " selected";
                $watchLabel = "Disabled";
                $watchflag = "0";
            }
      }
      elsif (@MapLines[$a] =~ /__PROXY_SERVER__/)
      {
            $ProxyLine = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__FILE_REPOS_DIR__/)
      {
            $filerepos = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__FILE_WATCHER_DIR__/)
      {
            $watchDir = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__FILE_WATCHER_FILTER__/)
      {
            $watchFilter = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__PROXY_AUTH_USERNAME__/)
      {
            $authUser = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__PROXY_AUTH_PASSWORD__/)
      {
            $authPassword = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_ASSET_TYPE_NAME__/)
      {
            $AssetType = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_ASSET_TYPE_PRODUCT__/)
      {
            $Product = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_ASSET_TYPE_MODEL__/)
      {
            $Model = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_ASSET_TYPE_VERSION__/)
      {
	      $AssetTypeVersion = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_ASSET_FRIENDLY_NAME__/)
      {
            $FriendlyName = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_LONGITUDE__/)
      {
            $AddrLon = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_LATITUDE__/)
      {
            $AddrLat = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_ADDRESS_LINE1__/)
      {
            $AddrLine1 = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_ADDRESS_LINE2__/)
      {
		$AddrLine2 = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_CITY__/)
      {
		$AddrCity = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_STATE__/)
      {
		$AddrState = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_POSTALCODE__/)
      {
		$AddrPostal = ExtractData(@MapLines[$a]);
      }
      elsif (@MapLines[$a] =~ /__SA_COUNTRY__/)
      {
		$AddrCountry = ExtractData(@MapLines[$a]);
      }
	  elsif (@MapLines[$a] =~ /__SA_CONTINENT__/)
      {
		$AddrContinent = ExtractData(@MapLines[$a]);
      }
	  elsif (@MapLines[$a] =~ /__SA_INSTITUTION__/)
      {
		$AddrInstitution = ExtractData(@MapLines[$a]);
      }
	  elsif (@MapLines[$a] =~ /__SA_DEPARTMENT__/)
      {
		$AddrDepartment = ExtractData(@MapLines[$a]);
      }
	  elsif (@MapLines[$a] =~ /__SA_BUILDING__/)
      {
		$AddrBuilding = ExtractData(@MapLines[$a]);
      }
	  elsif (@MapLines[$a] =~ /__SA_FLOOR__/)
      {
		$AddrFloor = ExtractData(@MapLines[$a]);
      }
	  elsif (@MapLines[$a] =~ /__SA_ROOM__/)
      {
		$AddrRoom = ExtractData(@MapLines[$a]);
      }
	  elsif (@MapLines[$a] =~ /__SA_SERVICE_CENTER__/)
      {
		$SvcCenter = ExtractData(@MapLines[$a]);
      }

}

#
#  Special proxy server steps - split into ip address and port.

($proxyAddr,$proxyPort) = split(/:/,$ProxyLine);


#
#  If STAGING, PILOT, DEVELOPMENT, PRODUCTION server selected (not OTHER), then
#  force the user URL fields to null.
#

$allswitch = "";
$tunswitch = "readonly";
$watchfldswitch = "";
$proxyfldswitch = "";
$authswitch = "";
$authfldswitch = "";

# Switch off FileWatcher fields if FW not enabled.
#

if ($watchYesSel eq "")
{
   $watchfldswitch = "DISABLED";
}

if ($proxyYesSel eq "")
{
   $proxyfldswitch = "DISABLED";
   $authswitch = "DISABLED";
   $authfldswitch = "DISABLED";
} else {
   if ($authYesSel eq "")
   {
      $authfldswitch = "DISABLED";
   }
}

# Turn off most fields but address and proxy if user is not
# GE Service.
#
if ($UserLevel ne "M")
{
   $allswitch = "DISABLED";
   $watchfldswitch = "DISABLED";
}

# Place the javascript within the page.
#
print "\n<script type=\"text/javascript\">\n";

# changedURL will save the Other enterprise user selections.  This will
# persist user selections when flipping between enterprise drop-down
# entries.
#
print "function changedURL(oform){\n";
print "var enturl = oform[\"UserEntURL\"];\n";
print "var tunurl = oform[\"UserTunURL\"];\n";
print "var userenturl = oform[\"LocalUserEntURL\"];\n";
print "var usertunurl = oform[\"LocalUserTunURL\"];\n";

print "userenturl.value = enturl.value;\n";
print "usertunurl.value = tunurl.value;\n";
print "}\n";

# switchWatcher will enable or disable filewatcher fields when
# user selects enable/disable FW.
#
print "function switchWatcher(oform, x) {\n";
print "var watchdir = oform[\"WatchDir\"];\n";
print "var watchfilt = oform[\"WatchFilter\"];\n";
print "var watchen = parseInt(x,10);\n";
print "if (watchen == 1)\n";
print "{\n";
print "watchdir.disabled=false;\n";
print "watchfilt.disabled=false;\n";
print "}\n";
print "else\n";
print "{\n";
print "watchdir.disabled=true;\n";
print "watchfilt.disabled=true;\n";
print "}\n";
print "}\n";

# switchProxy will enable-disable proxy and authorization
# fields as the user selects proxy enable/disable.
#
print "function switchProxy(oform, x) {\n";
print "var proxip = oform[\"ProxyIP\"];\n";
print "var proxport = oform[\"ProxyPort\"];\n";
print "var proxen = parseInt(x,10);\n";
print "var authenable = oform[\"AuthEnable\"];\n";
print "if (proxen == 1)\n";
print "{\n";
print "proxip.disabled=false;\n";
print "proxport.disabled=false;\n";
print "authenable.disabled=false;\n";
print "switchAuth(oform, authenable.value);\n";
print "}\n";
print "else\n";
print "{\n";
print "proxip.disabled=true;\n";
print "proxport.disabled=true;\n";
print "authenable.disabled=true;\n";
print "switchAuth(oform, \"0\");\n";
print "}\n";
print "}\n";


# switchAuth will disable-enable proxy authorization
# fields when user selects enable-disable proxy authorization.
#
print "function switchAuth(oform, x) {\n";
print "var authscheme = oform[\"AuthScheme\"];\n";
print "var authuser = oform[\"AuthUser\"];\n";
print "var authpassword = oform[\"AuthPassword\"];\n";
print "var authflag = parseInt(x,10);\n";
print "if (authflag == 1)\n";
print "{\n";
print "authscheme.disabled=false;\n";
print "authuser.disabled=false;\n";
print "authpassword.disabled=false;\n";
print "}\n";
print "else\n";
print "{\n";
print "authscheme.disabled=true;\n";
print "authuser.disabled=true;\n";
print "authpassword.disabled=true;\n";
print "}\n";
print "}\n";
  
# enableFields will enable centain fields, which are normally disabled, for testing purpose
#
print "function enableFields() {\n";
print "var userLevel = \"$UserLevel\";\n";
print "var deviceName = document.forms[0][\"DeviceName\"][0];\n";  # Pick the first DeviceName input. The second DeviceName input is hidden.
print "if (userLevel==\"M\")\n";  # enable it only if the user is GE Service
print "deviceName.disabled=false;\n";
print "}\n";

print "</script>\n";
print "</head>";

#
#  Now that we have all default / current values, display the page.  Submit action
#  will be executing updateServiceAgent.cgi.

print "<body  bgcolor=#b5b5b5 onload=\"AgentConfig.initForm();\">";
print "<STYLE TYPE=\"text/css\">";
print "th  {font-size:10pt}";
print "td  {font-size:8pt}";
print "td.invalid {color: red}";
print "input {font-size:8pt}";
print "select {font-size:8pt}";
print "</STYLE>";
#print "<center><H><b>Agent Config Tool</b></H></center>";
print "<FORM id=\"oform\" METHOD=\"POST\" ACTION=\"/uscgi-bin/updateServiceAgent.cgi\" onsubmit=\"return AgentConfig.validate();\">";

#
#  These fields are only editable if Class M.
#


   print "<table border=0 cellpadding=2 cellspacing=2>";
   print "<tr><th ALIGN=CENTER COLSPAN=4><b>Agen<span onClick=\"enableFields();\">t</span> Configuration</b></th></tr>";
   print "<tr><td><b>Device Name</b>:</td><td><INPUT TYPE=\"text\" Name=\"DeviceName\" ";
   print    "Size=\"16\" value=\"$PrevAssetName\" DISABLED></td>";
   print "<td><b>CRM No.</b>:</td><td><INPUT TYPE=\"text\" Name=\"SerialNumber\" ";
   print    "Size=\"16\" value=\"$PrevSerNum\" onblur=\"AgentConfig.capitalAllCharsInput(this);\" $allswitch></td></tr>";
   print "<tr><td>Display Name:</td><td><INPUT TYPE=\"text\" NAME=\"FriendlyName\" ";
   print    "Size=\"16\" value=\"$FriendlyName\" $allswitch></td>";
   print "<td>Description:</td><td><INPUT TYPE=\"text\" NAME=\"AgentDescription\" ";
   print    "Size=\"32\" value=\"$PrevDesc\" $allswitch></td></tr>";

print "<INPUT TYPE=hidden Name=\"DeviceName\" ";
    print    "value=\"$PrevAssetName\">";
   if ($UserLevel ne "M")
   {
    
    print "<INPUT TYPE=hidden Name=\"SerialNumber\" ";
    print    "value=\"$PrevSerNum\">";
    print "<INPUT TYPE=hidden NAME=\"FriendlyName\" ";
    print    "value=\"$FriendlyName\">";
    print "<INPUT TYPE=hidden NAME=\"AgentDescription\" ";
    print    "value=\"$PrevDesc\">";
   }
   print "</table>";

print "<br/>";
#  Address fields are editable at all times.
#
print "<table border=0 cellpadding=2 cellspacing=2>";
print "<tr><td><b>Continent</b>:</td><td><SELECT Size=\"1\" Name=\"Continent\" onchange=\"AgentConfig.loadCountry();AgentConfig.loadSvcCenter();\">";
if ($AddrContinent ne "")
{
	print "<option value=\"$AddrContinent\">$AddrContinent</option>";
}
print "</SELECT></td>";
print "<td><b>Country</b>:</td><td COLSPAN=3><SELECT Size=\"1\" Name=\"Country\" onchange=\"AgentConfig.loadState();\">";
if ($AddrCountry ne "")
{
	print "<option value=\"$AddrCountry\">$AddrCountry</option>";
}
print "</SELECT></td></tr>";
print "<tr><td>Addr Line1:</td><td COLSPAN=5><INPUT TYPE=\"text\" NAME=\"AddressLine1\" ";
print    "Size=\"40\" value=\"$AddrLine1\"></td></tr>";
print "<tr><td>Addr Line2:</td><td COLSPAN=5><INPUT TYPE=\"text\" NAME=\"AddressLine2\" ";
print    "Size=\"40\" value=\"$AddrLine2\"></td></tr>";
print "<tr><td><b>City</b>:</td><td><INPUT TYPE=\"text\" NAME=\"City\" ";
print    "Size=\"20\" value=\"$AddrCity\" onblur=\"AgentConfig.capitalAllCharsInput(this);\"></td>";
print "<td><b>State(Prov)</b>:</td><td><SELECT Size=\"1\" Name=\"State\" id=\"State\">";
if ($AddrState ne "")
{
	print "<option value=\"$AddrState\">$AddrState</option>";
}
print "</SELECT></td>";
print "<td>Postal Code:</td><td><INPUT TYPE=\"text\" NAME=\"PostalCode\" ";
print    "Size=\"7\" value=\"$AddrPostal\" onblur=\"AgentConfig.capitalAllCharsInput(this);\"></td></tr>";
print "<tr><td>Latitude:</td><td><INPUT TYPE=\"text\" NAME=\"Latitude\" ";
print    "Size=\"5\" value=\"$AddrLat\"></td>";
print "<td>Longitude:</td><td><INPUT TYPE=\"text\" NAME=\"Longitude\" ";
print    "Size=\"5\" value=\"$AddrLon\"></td></tr>";
print "<tr><td><b>Institution</b>:</td><td><INPUT TYPE=\"text\" NAME=\"Institution\" onblur=\"AgentConfig.capitalAllCharsInput(this);\" ";
print    "Size=\"20\" value=\"$AddrInstitution\"></td>";
print "<td>Department:</td><td><INPUT TYPE=\"text\" NAME=\"Department\" onblur=\"AgentConfig.capitalAllCharsInput(this);\" ";
print    "Size=\"20\" value=\"$AddrDepartment\"></td></tr>";
print "<tr><td>Building:</td><td><INPUT TYPE=\"text\" NAME=\"Building\" onblur=\"AgentConfig.capitalAllCharsInput(this);\" ";
print    "Size=\"7\" value=\"$AddrBuilding\"></td>";
print "<td>Floor:</td><td><INPUT TYPE=\"text\" NAME=\"Floor\" onblur=\"AgentConfig.capitalAllCharsInput(this);\" ";
print    "Size=\"7\" value=\"$AddrFloor\"></td>";
print "<td>Room:</td><td><INPUT TYPE=\"text\" NAME=\"Room\" onblur=\"AgentConfig.capitalAllCharsInput(this);\" ";
print    "Size=\"7\" value=\"$AddrRoom\"></td></tr></table>";

   print "<table border=0 cellpadding=2 cellspacing=2>";
   print "<tr><th COLSPAN=6 ALIGN=CENTER><b>Advanced Configuration</b></th></tr>";
   print "<tr><td><b>Enterprise Server</b>:</td><td><SELECT Size=\"1\" Name=\"EntServer\" onChange=\"AgentConfig.fillURLFields(this);\" $allswitch>";
   print    "</SELECT></td>";
   print "<td><b>Service Center</b>:</td><td><SELECT Size=\"1\" Name=\"SvcCenter\">";
   if ($SvcCenter ne "")
	{
		print "<option value=\"$SvcCenter\">$SvcCenter</option>";
	}
   print    "</SELECT></td>";
   print "<td>Log Level:</td><td><SELECT Size=\"1\" Name=\"LogLevel\" $allswitch>";
   print    "<option VALUE = \"ERROR\"";
   print       "$errorSel>ERROR";
   print    "<option VALUE = \"INFO\"";
   print       "$infoSel>INFO";
   print    "<option VALUE = \"WARN\"";
   print       "$warnSel>WARN";
   print    "<option VALUE = \"TRACE\"";
   print       "$traceSel>TRACE";
   print    "</SELECT></td></tr>";  


   print "<tr><td>Enterprise Server URL:</td><td COLSPAN=5><INPUT TYPE=\"text\" NAME=\"UserEntURL\" ";
   print    "Size=\"45\" value=\"$userEntURL\" onChange=\"changedURL(this.form)\" $tunswitch></td></tr>";
   print "<INPUT TYPE=hidden Name=\"LocalUserEntURL\" Value=\"$localUserEntURL\">";

   print "<tr><td>Enterprise Tunnel URL:</td><td COLSPAN=5><INPUT TYPE=\"text\" NAME=\"UserTunURL\" ";
   print    "Size=\"45\" value=\"$userTunURL\" onChange=\"changedURL(this.form)\" $tunswitch></td></tr>";
   print "<INPUT TYPE=hidden Name=\"LocalUserTunURL\" Value=\"$localUserTunURL\">";

   print "<tr><td>File Repository:</td><td COLSPAN=5><INPUT TYPE=\"text\" NAME=\"FileRepository\" ";
   print    "Size=\"45\" value=\"$filerepos\" $allswitch></td></tr></table>";

   print "<table border=0 cellpadding=2 cellspacing=2>";
   print "<tr><td><b>File Watcher</b>:</td><td><SELECT Size=\"1\" Name=\"WatchEnable\" onChange=\"switchWatcher(this.form, this.value)\" $allswitch>";
   print    "<option VALUE = \"0\"";
   print       "$watchNoSel>Disable";
   print    "<option VALUE = \"1\"";
   print       "$watchYesSel>Enable";
   print    "</td>";
   print "<td>Dir:</td><td COLSPAN=3><INPUT TYPE=\"text\" Name=\"WatchDir\" ";
   print    "Size=\"25\" Value=\"$watchDir\" $watchfldswitch></td>";
   print "<td>Filter:</td><td><INPUT TYPE=\"text\" Name=\"WatchFilter\" ";
   print    "Size=\"4\" Value=\"$watchFilter\" $watchfldswitch></td></tr></table>";

   if ($UserLevel ne "M")
   {
       print "<INPUT TYPE=hidden NAME=\"LogLevel\" value=\"$prevLevel\">";
       print "<INPUT TYPE=hidden NAME=\"FileRepository\" value=\"$filerepos\">";
       print "<INPUT TYPE=hidden NAME=\"WatchEnable\" value=\"$watchflag\">";
       print "<INPUT TYPE=hidden Name=\"WatchDir\" value=\"$watchDir\">";
       print "<INPUT TYPE=hidden Name=\"WatchFilter\" Value=\"$watchFilter\">";
   }

#  These proxy server and proxy authorization fields are editable at all times.
#

print "<table border=0 cellpadding=2 cellspacing=2>";
print "<tr><th COLSPAN=6 ALIGN=CENTER><b>Proxy Configuration</b></th></tr>";
print "<tr><td><b>Proxy</b>:</td><td><SELECT Size=\"1\" Name=\"ProxyEnable\" onChange=\"switchProxy(this.form, this.value)\">";
print    "<option VALUE = \"0\"";
print       "$proxyNoSel>Disable";
print    "<option VALUE = \"1\"";
print       "$proxyYesSel>Enable";
print    "</SELECT></td>";

print "<td>IP Addr:</td><td><INPUT TYPE=\"text\" Name=\"ProxyIP\" ";
print    "Size=\"20\" Value=\"$proxyAddr\" $proxyfldswitch></td>";
print "<td>Port:</td><td><INPUT TYPE=\"text\" Name=\"ProxyPort\" ";
print    "Size=\"4\" Value=\"$proxyPort\" $proxyfldswitch></td></tr></table>";

print "<table border=0 cellpadding=2 cellspacing=2>";
print "<tr><td><b>Proxy Authentication</b>:</td><td><SELECT Size=\"1\" Name=\"AuthEnable\"  onChange=\"switchAuth(this.form, this.value)\" $authswitch>";
print    "<option VALUE = \"0\"";
print       "$authNoSel>Disable";
print    "<option VALUE = \"1\"";
print       "$authYesSel>Enable";
print    "</SELECT></td>";

print "<td>Scheme:</td><td><SELECT Size=\"1\" Name=\"AuthScheme\" $authfldswitch>";
print    "<option VALUE = \"NONE\"";
print       "$noneSel>NONE";
print    "<option VALUE = \"NTLM\"";
print       "$ntlmSel>NTLM";
print    "<option VALUE = \"Digest\"";
print       "$digestSel>Digest";
print    "<option VALUE = \"Basic\"";
print       "$basicSel>Basic";
print    "</SELECT></td></tr>";


print "<tr><td ALIGN=RIGHT>Proxy User:</td><td><INPUT TYPE=\"text\" Name=\"AuthUser\" ";
print    "Size=\"15\" Value=\"$authUser\" $authfldswitch></td>";
print "<td>Password:</td><td><INPUT TYPE=\"PASSWORD\" Name=\"AuthPassword\" ";
print    "Size=\"12\" Value=\"$authPassword\" $authfldswitch></td></tr>";


#  Finally, the submit and reset inputs.  Plus some housekeeping hidden parameters for the
#  update cgi.
#
print "<tr><td><INPUT TYPE=submit VALUE=\"Submit Changes\"></td>";
print "<td><INPUT TYPE=reset VALUE=\"Reset Form\"></td></tr></table>";


print "<INPUT TYPE=hidden Name=\"CurrentName\" Value=\"$PrevAssetName\">";
print "<INPUT TYPE=hidden Name=\"PrevFlag\" Value=\"$PrevFlag\">";
print "<INPUT TYPE=hidden Name=\"UserLevel\" Value=\"$UserLevel\">";

print "</FORM>";

print "</body>";
print "</html>";
