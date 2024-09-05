#!/usr/local/bin/perl


sub read_input
{
    local ($buffer, @pairs, $pair, $name, $value, %FORM);

    # Read in text
    $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;

    if ( $ENV{'REQUEST_METHOD'} eq "POST" ) {
       read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    } else {
       $buffer = $ENV{'QUERY_STRING'};
    }

    # Split information into name/value pairs
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs) {
        ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%(..)/pack("C", hex($1))/eg;
        $FORM{$name} = $value;
    }

    %FORM;
}



print "Content-type: text/html\n\n";

print "<body bgcolor=#b5b5b5></body>";


$clientIpAddress=$ENV{'REMOTE_ADDR'};
$clientHostName = $ENV{'REMOTE_HOST'};

$target_root=$ENV{"TARGET_ROOT"};
$target_root=~s/\\/\//g;
if(($clientIpAddress eq "127.0.0.1") || ($clientHostName eq "localhost"))
{
		`wscript $target_root/bin/RemoveUnattchedImages.js -r`;
		print "Image Cleanup tool terminated";

}
else
{
	# check for disruptive mode.
	$dis_file="$target_root/service/svcpform/diagLogs/.statusFile";
	$dis_mode=0; # default is disruptive mode is disabled
#	print "dis file:$dis_file<br>";
	if(-f $dis_file)
	{
#		print "found file<br>";
		$status_str1=`grep Status= $dis_file | cut -f2 -d=`;
		chop $status_str1;
		@status_str=split(/\n/,$status_str1);
		$temp_str=$status_str[$#status_str];
#		print "temp_str:$temp_str<br>";
		if($temp_str =~ /1/)
		{
			$dis_mode=1;
		}
		
	}
	
	if($dis_mode==0)
	{
		print "Can not run the Image Cleanup tool. Disruptive mode is not enabled.<br> Enable it using Diagnostics->Common Diagnostics->Utilites->Disruptive Mode";
	}
	else
	{
		`wscript $target_root/bin/RemoveUnattchedImages.js -r`;
		print "Image Cleanup tool terminated";
	}
}
print "</html>";

