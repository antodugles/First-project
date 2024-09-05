#!C:/Perl/bin/perl.exe

print "Content-Type: text/html\n\n";

#Check the access log file to find the current user

$AccessFile = $ENV{"WIP_HOME"} . "tomcat\\webapps\\modality-csd\\AccessLog.txt";

# if file is not there, default to non-GE Service.
$UserLevel = "A";
$access = 0;

if (-e $AccessFile)
{
  open(MYFILE, $AccessFile);
  @ALFile = <MYFILE>;
  $accessline = @ALFile[$#ALFile];

  close(MYFILE);
  $UserLevel = substr($accessline, 6, 1);
}

if ($UserLevel eq "M")
{
   $access = 1;
}

print $access;


