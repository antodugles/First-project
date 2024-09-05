# UpdateTomcatPort.pl  
#
# Usage: perl UpdateTomcatPort.pl [TomcatPortNum]
#
# Updates all necessary Apache and Tomcat configuration files to bind the
# Tomcat java container to a localhost port other that default (8009).  If 
# same as default, it will skip processing.
#
#
# <mode>: 1 - updates the worker properties files - Apache and Tomcat.
#         2 - updates the worker2 file.
#         3 - updates the server.xml file.
#
   sub ConvertFile{
      my $infile = @_[0];
      my $DaPort = @_[1];
      my $mode = @_[2];
      
      my $a = 0;
      my $newline = "";

      open(INFILE, $infile);
      my @xmllines = <INFILE>;

      close(INFILE);

      $infile .= ".newform";
      open(OUTFILE, ">$infile");
      select(OUTFILE);

      for $a ( 0..$#xmllines )
      {
         $newline = @xmllines[$a];

         
         if ($mode eq "1")
         {
            if ($newline =~ /worker1.port/)
            {
		   $newline = "";
		   $newline = "worker.worker1.port=$DaPort\n";
            }
 
            elsif ($newline =~ /worker.ajp13.port/)
            {
		   $newline = "";
		   $newline = "worker.ajp13.port=$DaPort\n";
            }
	 }
         elsif ($mode eq "2")
         {
             if ($newline =~ /localhost:8009/)
             {
                $newline =~ s/localhost:8009/localhost:$DaPort/;
             }
	 }
	 elsif ($mode eq "3")
         {
             if ($newline =~ /address=\"127.0.0.1\"/)
             {
                 $newline =~ s/8009/$DaPort/;
             }
         }

         print "$newline";
      }
      close(OUTFILE);

    
      rename($infile, @_[0]);

      return 1;
   }

   ###########################################
   # MAINLine
   ############################################

   $TomcatPort = "";
   ($TomcatPort) = @ARGV;

   if (($TomcatPort eq "") || ($TomcatPort eq "8009"))
   {
      print "Skipped Processing.  Tomcat port remains default.\n";
      exit 1;
   }

   $basedir = $ENV{"WIP_HOME"};
   $newpath = "";
   $newpath = $basedir . "tomcat/conf/workers.properties";

   ConvertFile($newpath, $TomcatPort, "1");

   $newpath = "";
   $newpath = $basedir . "Apache/conf/workers.properties";

   ConvertFile($newpath, $TomcatPort, "1");

   $newpath = "";
   $newpath = $basedir . "tomcat/conf/workers2.properties";

   ConvertFile($newpath, $TomcatPort, "2");

   $newpath = "";
   $newpath = $basedir . "tomcat/conf/server.xml";

   ConvertFile($newpath, $TomcatPort, "3");

    
