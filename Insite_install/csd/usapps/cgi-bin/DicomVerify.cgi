#!C:/Perl/bin/perl.exe
#debug set to 1 prints out extra debug info into web browser page
$debug=0;
#$debug=1;

use CookieMonster;

######
# Main
######

####  get list of symbols to convert
my %escape_symbols = (

    qq(>)     => '&gt;',
    qq(<)     => '&lt;',
    qq(&)     => '&amp;'
);
# create regular expression for these characters 
my $char_class = join ("|", map { "($_)" } keys %escape_symbols);



print "Content-type: text/html\n\n";
print "<head>\n";
print "<link href=\"/service/DicomVerify.css\" rel=\"stylesheet\" type=\"text/css\" />\n";
print "<script>\n";
print "function CallOtherFrame()\n";
print "{\n";
print "   var OtherFrame = top.document.getElementsByTagName(\"FRAME\")[\"ControlFrame\"];\n";
print "   var otherDoc;\n";
print "   var form;\n";
print "   if ( OtherFrame == null ){ \n";
print "      // this handles the case where the dicom verfiy is running inside of the CSD\n";
print "      OtherFrame = this.parent.frames.frames[\"ControlFrame\"];\n";
print "      OtherDoc = OtherFrame.document;\n";
print "      form = OtherDoc.getElementById('Verify');\n";
print "      OtherFrame.ProcessButton(\"LOOP\");\n";
print "   }else {\n";
print "      OtherFrame.contentWindow.ProcessButton(\"LOOP\");\n";
print "      form = OtherFrame.contentWindow.window.document.getElementById('Verify');\n";
print "   }\n";
print "   // now get parameters and update table\n";
print "   var ae = form.AETITLE.value;\n";
print "   var ip = form.IPADDR.value;\n";
print "   var port = form.PORT.value;\n";
print "   // now fill in local table\n";
print "   document.getElementById('AE').innerHTML =ae\n";
print "   document.getElementById('IP').innerHTML =ip\n";
print "   document.getElementById('PORT').innerHTML =port\n";
print "}\n";
print "function DebugOut(msg)\n";
print "{\n";
print "   var x=document.getElementById('OUT');\n";
print "   x.innerHTML+=msg + '<br>'  ;\n";
print "}\n";
print "\n";
print "</script>\n";
print "</head>\n";

print "<html>\n";
print "<body bgcolor=#COCOCO onload=\"CallOtherFrame()\"> \n";

$InsiteHome=$ENV{"INSITE_HOME"};

$RequestMethod = $ENV{'REQUEST_METHOD'};
$RequestMethod =~ tr/a-z/A-Z/;

if ( $RequestMethod eq  "POST" ) {
   read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
} else {
   $buffer = $ENV{'QUERY_STRING'};
}
if ($debug==1) {
        print"<br>  debug: REQUEST_METHOD = $RequestMethod <br>\n";
	print"<br>  debug: buffer = $buffer<br>\n";
}


# Split information into name/value pairs
@pairs = split(/&/, $buffer);
foreach $pair (@pairs) {
    ($name, $value) = split(/=/, $pair);
    $value =~ tr/+/ /;
    $value =~ s/%(..)/pack("C", hex($1))/eg;
    $FORM{$name} = $value;
    if ( $debug==1 ){
       print "  debug Variable:   $name  =  :$value:<br>\n";
    }
}
$aetitle = $FORM{"AETITLE"};
$ipaddr  = $FORM{"IPADDR"};
$port    = $FORM{"PORT"};
if ( $port =~ /^$/ ) {
    $port = 104;
}
$command = $FORM{"cmd"};

# cmd = "init" is the initial web page displayed

print "  <center><h3>Dicom Verify</h3></center> \n";
print "  <center><table border=1> \n";
print "           <tr align=\"center\"> \n";
print "               <th>AE Title</th> \n";
print "               <th>IP Address</th> \n";
print "               <th>Port</th> \n";
print "           </tr> \n";
print "           <tr> \n";
print "               <td id=\"AE\"  > </td> \n";
print "               <td id=\"IP\"  > </td> \n";
print "               <td id=\"PORT\"> </td> \n";
print "           </tr> \n";
print "  </table></center> \n";
#print "  <br/><div ID='OUT'></div>\n";

$ok=1;
if( ! ($command =~ /init/))
{
    if ( $aetitle =~ /^$/ ) {
        $ok=0;
        print "<h3>AE title must not be blank</h3>\n";
    }
    if ( $port =~ /^$/ ) {
        $ok=0;
        print "<h3>Port must not be blank</h3>\n";
    }
    if ( $ipaddr =~ /^$/ ) {
        $ok=0;
        print "<h3>IP address  must not be blank</h3>\n";
    }
    if ( $ok ) {

        $command = "dcmshell " . $aetitle . " " . $ipaddr . " " . $port;

        if ($debug==1) {
            print "CMD: $command<br>\n";
        }

        @result = CookieMonster::runCommand($command);
        chop(@result);

        foreach $line(@result) {
            $line =~ s/($char_class)/$escape_symbols{$1}/ge;  # convert special characters
            if ( $line =~ "loading dictionary" ) {
                next;
            }
            $fail = 0;
            if ( $line =~ /fail/ig ) {
                $fail = 1;
                print "<font color=\"RED\">";
            }
            print "$line";
            if ( $fail ) {
                print "</font>";
            }
            print "<br>\n";
        }
    }

}
print " <div class=\"iheader\">Instuctions:</h3>\n";
print " <div class=\"instr\"> Enter AETITLE, IP Address and port values of Dicom device. </div>\n";
print " <div class=\"instr\"> Click on \"Verify\" to see results</div>\n";
print " <div class=\"instr\"> If the \"Loop\" check box is checked the Verify operation will repeat.</div>\n";
print " <div class=\"instr\"> Uncheck the Loop checkbox to stop the looping.</div>\n";
print "</body></html>";
