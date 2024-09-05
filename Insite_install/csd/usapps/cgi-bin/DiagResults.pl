#!/usr/local/bin/perl
# DiagResults.pl: Content feeder for DiagExecuteIF Results page.
# Last modified: Sep.11.2006
# Usage: http://localhost/uscgi-bin/DiagResults.pl?path=%INSITE_HOME%/html/diags/DiagResults.xml
#	or DiagResults.pl?path=%INSITE_HOME%/html/diags/DiagResults.xml

# Read GET variables into $get
my @values = split(/&/, $ENV{QUERY_STRING});
for $var (@values) {
	my ($key, $value) = split(/=/, $var);
	$value =~ s/\+/ /g;
	$value =~ s/%([A-F0-9]{2})/chr(hex($1))/egi;
	$get{$key} = $value;
}

# Grab path and parse environment variables.
my $path = $get{path};
while ($path =~ m/(%(.+?)%)/g) {
	#~ print "s/$1/" . $ENV{$2} . "/g";
	my $env_var = $ENV{$2};
	$path =~ s/$1/${env_var}/g;
}

# Does the file exist?
if (-e $path) {
	# Yes it does, change the content-type according to the extension.
	if ($path =~ m/\.(xml|xsl|xslt|xsd|rss|rdf|dtd)$/i) {
		print "Content-type: text/xml\n\n";
	} elsif ($path =~ m/\.(html|htm|htmls|shtml|xhtml)$/i) {
		print "Content-type: text/html\n\n";
	} elsif ($path =~ m/\.(css)$/i) {
		print "Content-type: text/css\n\n";
	} elsif ($path =~ m/\.(js)$/i) {
		print "Content-type: application/x-javascript\n\n";
	} else {
		print "Content-type: text/plain\n\n";
	}
	
	# Dump file contents.
	open(FEED, $path);
	while($line = <FEED>) {
		print $line;
	}
	close(FEED);
} else {
	# File does not exist, return 404.
	print "Status: 404 Not Found\n";
}
