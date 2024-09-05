#! /usr/local/bin/perl
$debug=0;
#$debug=1;

print "Content-type: text/html\n\n";

print "<head>\n";
print "<script>\n";
print "var fPath=\"\"\n";
print "function GetNew(dhtml)\n";
print "{\n";
print "   fPath=dhtml.value;\n";
print "   var f=document.forms[\"Submit\"];\n";
print "   f.choose.value=fPath;\n";
print "}\n";
print "</script>\n";
print "</head>\n";

print "<html>\n";
print "<body bgcolor=#b5b5b5>\n";


$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;

if ( $ENV{'REQUEST_METHOD'} eq "POST" ) {
   read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
} else {
   $buffer = $ENV{'QUERY_STRING'};
}
if ($debug==1) {
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
       print "  debug:   variables: <br>\n";
       print "  debug:   $name  =  $value<br>\n";
    }
}
$command=$FORM{"cmd"};

if($command eq "init")
{

	print "<br>";
	print "<b>Note:</b> The file transfer tool of the scanner will transfer files to the GE-Service<br>";
	print "This tool will not be operational unless the scanner is configured by GE-service for <br>";
	print "insite/iLinq connectivity<br><br>";

	print "The File Transfer Configuration Utility will let you configure the scanner to transfer a specific file.<br>";
	print "The actual file transfer will occur later. By default, the scanner is capable of transfering<br>";
	print "all system logs and crash logs (when configured). Use this tool to add more to that list <br><br>";
	print "Add Files - Choose a specific file to send during the next file transfer<br>";
	print "Delete Files - Choose a file to remove from the list of files that need to be transfered<br>";
	print "List Files - List the currently selected files meant to be transfered to GE-Service.<br>";
	print "Note:  The files will be listed with a Unix format path.<br><br><br>";

	print "<a href=/uscgi-bin/FilesToSend.cgi?cmd=ShowAddForm> Add Files </a>&nbsp&nbsp";
	print "<a href=/uscgi-bin/FilesToSend.cgi?cmd=ShowDeleteForm> Delete Files </a>&nbsp&nbsp";
	print "<a href=/uscgi-bin/FilesToSend.cgi?cmd=ListFiles> List Files </a>";
	#print "<a href=/uscgi-bin/FilesToSend.cgi?cmd=ListDefFiles> List Default Files </a>";
}
if($command eq "ListFiles")
{
	$file_list=`cat c:/tmp/filelist.txt`;
	$file_list=~s/\n/<br>/g;
	print $file_list;
}
if($command eq "ListDefFiles")
{
	#$file_list=
}
if($command eq "ShowAddForm")
{
	# we use the form FileChooser to select a file.  The java script GetNew() puts the file name into
	# the Submit form.  If the first form had a submit button, it would send the whole file, not just the name.
	print "\n";
	print "<form NAME=\"FileChooser\" ENCTYPE=\"form-data\" ACTION=\"/uscgi-bin/FilesToSend.cgi\" METHOD=\"POST\">\n";
	print "<input type=hidden name=\"cmd\" value=add>\n";
	print "<input type=file name=\"choose\" value=\"\" onclick='GetNew(this)'>\n";
	print "<input type=hidden name=path value=\"--\">\n";
	print "</form><br>\n";
	
	print "<form NAME=\"Submit\" ENCTYPE=\"form-data\" ACTION=\"/uscgi-bin/FilesToSend.cgi\" METHOD=\"POST\">\n";
	print "<input type=hidden name=\"cmd\" value=add>\n";
	print "<input type=hidden name=\"choose\" value=\"\">\n";
	print "<input type=\"submit\" name=\"Add\" value=\"Send Input\">\n";
}
if($command eq "add")
{
	$file=$FORM{"choose"};
	$file =~ s/\\/\//g;  # convert backslash to slash
	$file =~ s,:,,g;     # convert c: to c/
	$file =~ s,^,/,;	 # add a / at begninning
	`echo $file >> c:/tmp/filelist.txt`;
	print "<b>Done</b>";
}
if($command eq "ShowDeleteForm")
{
	print "<form action=/uscgi-bin/FilesToSend.cgi>";
	print "<input type=hidden name=cmd value=delete>";
	print "Select a file to delete:<br>";
	print "<select name=files>";
	$filelist=`cat c:/tmp/filelist.txt`;
	@files_list=split(/\n/,$filelist);
	$numfiles=$#files_list;
	while($numfiles >=0)
	{
		print "<option value=$numfiles>$files_list[$numfiles]";
		$numfiles--;
	}
	print "</select>";
	print "<br>";
	print "<input type=submit name=Delete value=Delete>";
	print "</form>";		
}
if($command eq "delete")
{
	$file=$FORM{"files"};
	@file_list=`cat c:/tmp/filelist.txt`;
	#$file =~ s/\\/\\\\/g;
	#print "$file";
	#`grep -wv \\"$file\\" c:/tmp/filelist.txt > c:/tmp/del.txt`;
	#`mv c:/tmp/del.txt c:/tmp/filelist.txt`;
	$num=0;
	open(fh,">c:/tmp/filelist.txt");
	while($num<=$#file_list)
	{
		
		if($num ne $file)
		{
			#chop $file_list[$num];
			print fh $file_list[$num];
		}
		$num++;	
	}
	close(fh);
	print "Deleted file: $file_list[$file]";
}
print "</body></html>";