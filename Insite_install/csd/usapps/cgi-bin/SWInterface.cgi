#!D:/Program Files/InSite2/Perl/bin/perl.exe

use CookieMonster;

print "Content-type:text/html \n\n";
$buffer=$ENV{'QUERY_STRING'};
 @pairs = split(/&/, $buffer);
 foreach $pair (@pairs) 
	{
    		($name, $value) = split(/=/, $pair);
	     	$value =~ tr/+/ /;
     		$value =~ s/%(..)/pack("C", hex($1))/eg;
     		$FORM{$name} = $value;
 	}
$cmd=$FORM{"t1"};
$keyid=$FORM{"keyid"};
$addcmd=$FORM{"doadd"};
print "
<html>
	<head>
	<style type=\"text/css\">
		body {color: #000;}
	</style>";
#$cmd="details";$keyid=1;
if ($cmd eq "add")
{
print "
<script language=\"Javascript\">
function flip()
{
	var str=document.addf.keystring.value;
	var pos=str.indexOf(\" \");
	if(str == \"\")
	{
		alert(\"Please Enter a string\");
		document.addf.keystring.select();
		document.addf.keystring.focus();
		return;
	}
	if(pos>=0)
	{
		alert(\"Key string should not have spaces\");
		document.addf.keystring.select();
		document.addf.keystring.focus();
		return;
	}
	m_url=\"/uscgi-bin/SWInterface.cgi?doadd=Add!&keystring=\"+str;
	//alert(m_url);
	parent.results.location.href=m_url;

}
</script></head>
<body bgcolor=#b5b5b5>
<center><table border=3><tr><td><form name=addf onsubmit=\"return false\"><b>Key String:</b><br><input type=text size=45 name=keystring>&nbsp \n &nbsp<input type=button name=doadd value=Add! onclick=flip()></form></td></tr></table></center></body></html>";

exit;

}
elsif($addcmd eq "Add!")
{
	$keystringis=$FORM{"keystring"};
	@result=CookieMonster::runCommand("SwOptionIf.exe -Add $keystringis");
	print "</head><body bgcolor=#b5b5b5> @result[0]</body>";
	exit;
}

elsif($cmd eq "del")
{
	@result=CookieMonster::runCommand("SWOptionIf.exe -Remove $keyid");
	print "</head><body bgcolor=#b5b5b5> @result[0]\n</body>";
#	exit;
}
elsif($cmd eq "details")
{
	@details=CookieMonster::runCommand("SWOptionIf.exe -KeyDetails $keyid");
	print "</head><body bgcolor=#b5b5b5>";
	(@detail_pairs) = split(/,/, @details[0]);
	$count=0;
	$numpairs=$#detail_pairs;
	print "<center><table border=\"1\" cellspacing=\"8\"><tr>";
	foreach $pair (@detail_pairs)
       	{
               ($name, $value) = split(/=/, $pair);
               #$value =~ tr/+/ /;
               #$value =~ s/%(..)/pack("C", hex($1))/eg;
               $DETAIL[$count] = $value;
		if ($name =~ /Options/)
		{
			$name="Options Serial Number";
		}
		if ($name =~ /Hwid/)
		{
			$name="Hardware Id";
		}
		if($count==$numpairs)
		{
			$DETAIL[$count]="$name=$value";
			$name="Key Life";
		}
	       print "<td align=center>$name</td>";
	       $count++;
       	}
	print "</tr><tr>";
	while($ind <$count)
	{
		
		if($ind==$count-1)
		{
			($DETAIL[$ind],@optiondetails)=split(/\n/,$DETAIL[$ind]);
		}
		print "<td align=center>$DETAIL[$ind]</td>";
		$ind++;
	}
	$ind=0;
	$row1="<tr>";$row2="<tr>";
	$row1=$row1."</tr>";$row2=$row2."</tr>";
	#print "$row1$row2</table>";
	print "</td></tr>";

	print "</table></center></body>\n";
#	exit;
}
else
{
@product=CookieMonster::runCommand("SystemStatus -productName");
@hwid=CookieMonster::runCommand("SWOptionIf.exe -HWNumber");
print "
	<script language=\"javascript\">
		function formURL(id)
		{
		        if(id == \"add\")
        		{
		                m_url=\"/uscgi-bin/SWInterface.cgi?t1=add\"
        		parent.results.location.href=m_url;

 		       }
        		if(id == \"del\")
        		{
				if(document.f1.keys.selectedIndex < 0)
				{
					alert(\"Please select a key to delete\");
					return;
				}
				else
				{
					var name=confirm(\"Proceed with removal of key:\\n \"+document.f1.keys.options[document.f1.keys.selectedIndex].text);
					if(name==false) 
					{
						return;
					}
				}
                		m_url=\"/uscgi-bin/SWInterface.cgi?t1=del&keyid=\"+document.f1.keys.selectedIndex;
        		parent.results.location.href=m_url;
				location.reload();
        		}
	        	if(id==\"details\")
        		{
				if(document.f1.keys.selectedIndex < 0)
				{
        				alert(\"Please select a key to browse\")

        				return;
				}

                	m_url=\"/uscgi-bin/SWInterface.cgi?t1=details&keyid=\"+document.f1.keys.selectedIndex
        		parent.results.location.href=m_url;
        		}
			if(id==\"refresh\")
			{
				location.reload();
			}
	        	//alert(\"this is:\"+m_url);
			//parent.interface.location.href=\"/uscgi-bin/SWInterface.cgi\"

		}
	</script>
	</head>
<body bgcolor=\"#b5b5b5\">
<center>
<table border=\"6\" cellspacing=\"5\">
<tr>
<td><pre><strong>Product        :  </strong><font color=brown>@product[0]</font>
<strong>Hardware Number:  </strong><font color=brown>@hwid[0]</font></pre></td>
</tr>
</table>
<table border=\"6\" cellspacing=\"5\">
<th colspan=\"2\"> Software Option Keys</th>
<tr>
<form name=f1>
<td>
Available Keys:<br>
";
@optiondetails=CookieMonster::runCommand("SWOptionIf.exe -OptionDetails");
chop(@optiondetails);
$ind=0;
$row1="<tr>";$row2="<tr>";
while($ind < $#optiondetails)
{
		($optionname,$statusval)=split(/;/,$optiondetails[$ind]);
                $row1=$row1."<td align=center>$optionname</td>";
                if($statusval =~ /Disabled/)
                {
                        $statusval="<font color=brown>$statusval</font>";

                }
                elsif($statusval =~ /Expired/)
                {
                        $statusval="<font color=red>$statusval</font>";
                }
                elsif($statusval =~ /Permanent/)
                {
                        $statusval="<font color=green>$statusval</font>";


                }
                elsif($statusval =~ /Valid/)
                {
                        $statusval="<font color=yellow>$statusval</font>";


                }
                elsif($statusval =~ /Count/)
                {
                        $statusval="<font color=blue>$statusval</font>";

                }
                #$row2=$row2."<td align=center>$optiondetails[$ind]</td>

                $row2=$row2."<td align=center>$statusval</td>";
        $ind++;
}
$row1=$row1."</tr>";$row2=$row2."</tr>";

@keys=CookieMonster::runCommand("SWOptionIf.exe -KeyNames");
chop(@keys);
$numkeys=$#keys;
$i=0;
print "<select name=\"keys\" size=$numkeys>";
	while($i < $numkeys)
	{
		($keystring,$id)=split(/;/,$keys[$i]);
		print "<option value=$i>$keystring\n";
		$i++;
	
	}
print "</select>
</td>
<td align=center>
<input type=\"button\" name=add value=\"  Add...  \" onclick=formURL(\"add\")>
<br><br>
<input type=\"button\" name=delete value=\"  Delete  \" onclick=formURL(\"del\")>
<br><br>
<input type=\"button\" name=details value=\"  Details \" onclick=formURL(\"details\")>
<br><br>
<input type=\"button\" name=refresh value=\" Refresh \" onclick=formURL(\"refresh\")>
</td>
</form>
</tr>
<br></table>
<br><br><table border=\"6\" cellspacing=\"5\"><th colspan=$ind align=center>Details of Installed Options</th>$row1$row2</table>
</center>
</body>

";
}
#print "</html>";
#exit 0;
