# UpdateWebPort.pl  
#
# Usage: perl UpdateWebPort.pl [WebPortNum]
#
# Updates all necessary Apache and modality-csd files to listen on a localhost port
# other than default (80).  If same as default, it will skip processing.
#
#
# This function replaces the ../localhost*/.. with ../localhost:<newWebPort>/.. for
# the type of file determined by <mode>.
#
# <mode>: 1 - updates the menu XML file.
#         2 - updates the <menu>Page.html file.
#         3 - updates the httpd.conf file.
#
   sub ConvertFile{
      my $xmlfile = @_[0];
      my $DaWebPort = @_[1];
      my $mode = @_[2];
      
      my $a = 0;
      my $newline = "";

      open(XMLFILE, $xmlfile);
      my @xmllines = <XMLFILE>;
      chop(@xmllines);

      close(XMLFILE);

      $xmlfile .= ".newform";
      open(OUTFILE, ">$xmlfile");
      select(OUTFILE);

      for $a ( 0..$#xmllines )
      {
         $newline = @xmllines[$a];

         if ($mode eq "1")
         {
            $newline =~ s/localhost.*\/modality-csd\//localhost:$DaWebPort\/modality-csd\//;
         }
         elsif ($mode eq "2")
         {
            $newline =~ s/localhost.*\/uscgi-bin/localhost:$DaWebPort\/uscgi-bin/;
            $newline =~ s/localhost.*\/cgi\/modality-csd/localhost:$DaWebPort\/uscgi-bin/;
         }
         elsif ($mode eq "3")
         {
            if (($newline =~ /Listen/) && (!($newline =~ /#/)))
            {
               $newline = "";
               $newline = "Listen 127.0.0.1:" . $DaWebPort;
            }

            if (($newline =~ /ServerName/) && (!($newline =~ /#/)))
            {
               $newline = "";
               $newline = "ServerName localhost:" . $DaWebPort;
            }
         }

         print "$newline\n";
      }
      close(OUTFILE);

    
      rename($xmlfile, @_[0]);

      return 1;
   }

   ###########################################
   # MAINLine
   ############################################

   $WebPort = "";
   ($WebPort) = @ARGV;

   if (($WebPort eq "") || ($WebPort eq "80"))
   {
      print "Skipped Processing.  Apache port remains default.\n";
      exit 1;
   }

   $basedir = $ENV{"WIP_HOME"};
   chdir($basedir . "tomcat/webapps/modality-csd/xml");

   $MenuDir = `cmd /c \" dir /b *.menu.xml`;
   @MenuDirList = split(/\n/,$MenuDir);

   $i = 0;
   for(@MenuDirList)
   {
      ConvertFile($MenuDirList[$i],$WebPort,"1");
      $i++;
   }

   $MenuTabDirs = "calib;config;diag;errorLog;iq;part;pm;util";
   @MenuTabs = split(/;/,$MenuTabDirs);

   $j = 0;
   for(@MenuTabs)
   {
      chdir($basedir . "tomcat/webapps/modality-csd/" . $MenuTabs[$j]);
      $filetoHandle = $MenuTabs[$j] . "Page.html";
      ConvertFile($filetoHandle,$WebPort, "2");
      $j++;
   }

   chdir($basedir . "Apache/conf");
   ConvertFile("httpd.conf", $WebPort, "3");