# This Perl Script reads the specified install option XML or a sitemap xml file and extracts 
# Questra agent sitemap portion of it and make a sitemap xml file that can be used for manufacturing or updating existing sitemap.xml file.
# Usage:
#   perl ExtractSitemap.pl <Install Option XML> <SiteMap XML>
#

# Author : Jung Oh Date: April, 2006

if ( $#ARGV < 1 )
{
   print "Not enough input parameters. \n";
   print "Usage:\n";
   print "  perl ExtractSitemap.pl <Install Option XML> <SiteMap XML>\n";
   exit 1;
}

$optionfile = $ARGV[0];
$sitemapxml = $ARGV[1];
	
unless (open(IN,"$optionfile"))
{
	print "Failed to locate file : $optionfile. Exiting.\n";
	exit 1;
}

unless (open(OUT,">$sitemapxml"))
{
	print "Could not create output file $outputfile. Exiting.\n";
	exit 1;
}

select(OUT);

$polltype = "MANUAL";
$polltype_defined = 0;
$svcrev_defined = 0;
$svcrev_error = 0;
print "<?xml version=\"1\.0\" encoding=\"utf-8\" ?>\n";
print "<AgentConfig>\n";
while(<IN>)
{
	if ($_ =~ /<QuestraAgent Install=\"1\">/)
	{
		# Find out if the agent is configured to poll manually or constantly.
		$startmode = <IN>;
		if ($startmode =~ />AutoService<|>AutoProcess</)
		{
			$polltype = "CONSTANT";
		}
	}
			
	# Copy "QuestraAgentConfig" node
	if ($_ =~ /<QuestraAgentConfig>|<ModificationMap>/)
	{
		while(<IN>)
		{ 
			if ($_ =~ /__SA_POLLTYPE__/)
			{
				$polltype_defined = 1;
			}
			elsif ($_ =~ /__SA_SRV_REVISION__/)
			{
				$svcrev_defined = 1;
			}
			elsif ($_ =~ /<\/QuestraAgentConfig>|<\/ModificationMap>/)
			{
				if ($svcrev_defined == 0 || $polltype_defined == 0)
				{
					print "\t\t<replace>\n";
					# Unless __SA_SRV_REVISION__ tag is explicitly defined,
					if ($svcrev_defined == 0)
					{
						$ver = "";
						# Find out Service Platform version
						if (open(VersionFile, $ENV{"INSITE2_HOME"}."\\SVCPFORMVERSION"))
						{
							$ver=<VersionFile>;
							close(VersionFile);
							$ver=~s/VERSION://; # Strip "VERSION:" string
							$ver=~ s/ |\n//g;	# Strip the next line and space char
						}	
						else
						{
							$svcrev_error = 1;
						}
						# Add the tag for creating CS_GSP_SRVREV (Service Software Revision) Property
						print "\t\t\t<text symbol=\"__SA_SRV_REVISION__\">".$ver."<\/text>\n";
					}
					# Unless __SA_POLLTYPE__ tag is explicitly defined,
					if ($polltype_defined == 0)
					{
						# Add the tag for creating CS_GSP_POLLTYPE (Agent Polling Type) Property
						print "\t\t\t<text symbol=\"__SA_POLLTYPE__\">".$polltype."<\/text>\n";
					}
					print "\t\t<\/replace>\n";
				}
				last;
			}
			print $_;
		}
		last;
	} 
}
print "</AgentConfig>\n";
close(IN);
close(OUT);

if ($svcrev_error == 1)
{
	print STDOUT "Failed to locate file : SVCPFORMVERSION.\n";
	exit 1;
}


