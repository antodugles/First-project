#!/usr/local/bin/perl
print "Content-type:text/html \n\n";
$buffer=$ENV{'QUERY_STRING'};
@pairs=split(/&/,$buffer);
foreach $pair (@pairs)
{
	($name,$value) = split(/=/,$pair);
	$value=~tr/+/ /;
	$value =~ s/%(..)/pack("C",hex($1))/eg;
	$FORM{$name}=$value;
}
$status=0;
$Test_root=$ENV{"TEST_ROOT"};
$Test_root =~ s/\\/\//g;
if($bkup ne "no")
{
	$dirloc=$FORM{"dirloc"};
	$dirname=$FORM{"dirname"};
	if($dirloc eq "MO")
	{
			$dir="H:\\".$dirname;
		`cmd /c chkdsk H: > nul`;
		$status=$? >> 8;
		if($status eq 0)
		{
			`mkdir $dir`;
			$status=$? >> 8;
		}
	}
	elsif($dirloc eq "CD")
	{
			$dir="G:\\".$dirname;
		`cmd /c chkdsk G: > nul`;
		$status=$? >> 8;
		if($status eq 0)
		{
			`mkdir $dir`;
			$status=$? >> 8;
		}
	}
	if($dirloc eq "D:\\Export")
	{
		$dir="d:/Export/$dirname";
		`mkdir $dir`;
		$status=$? >> 8;
	}
	if($status ne 0)
	{
		print "<b> Could not create $dir</b>\n";
	}
	else
	{
		`cp -f -R $Test_root/resources/idunn/userdefs/* $dir`;
	}
}
if($bkup ne "no" && $status ne 0)
{
	print "<br>Warning: Can not make backup. Userdefs not cleaned<br>";
	exit;
}
`rm -rf $Test_root/resources/idunn/userdefs/*`;
$estatus=$? >> 8;
if ($estatus eq 0)
{
	print "<body bgcolor=#FFFFCC> <b> Successfully cleaned userdefs </b></body>";	
}
else
{
	print "<body bgcolor=#FFFFCC> <b> Clean-up of userdefs FAILED </b></body>";	
}
