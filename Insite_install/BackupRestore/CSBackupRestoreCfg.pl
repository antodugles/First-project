$path = $ENV{'INSITE2_HOME'} . "\\BackupRestore\\csapi-lib.pl";
require $path;

#
# CSBackupRestore.pl -
#
#   Author: Alan Kuhn
#
#   Script will save a set of service platform configuration files to compressed
#   file at a given location.  The script will also restore a set of platform
#   from given location.  The restore function will be a file copy by default.
#   A alternative process command can be defined in the SaveFilesConfig.xml that
#   will perform other restore functions such as an agent sitemap restore/merge.
#
#   perl CSBackupRestore.pl -backup|-restore -pkglocation=<pkgloc> [-h]  
#    -backup               backup configuration fileset directive.\n";
#    -restore              restore configuration fileset directive.\n";
#                  Only one of {-backup, -restore} must be selected.\n";
#    -pkglocation=<pkgloc> Destination or Source path of config fileset package.\n";
#    -h shows usage\n";
#
#

$debug=0;
$validver="1.0";
$updSaveCfgFlag = 0;

$usage = "CSBackupRestore -backup|-restore -pkglocation=<pkgloc> [-h]\n";
$usage .= ":saves or restores a fileset of platform configuration files.\n";
$usage .= "    -backup               backup configuration fileset directive.\n";
$usage .= "    -restore              restore configuration fileset directive.\n";
$usage .= "                             Only one of {-backup, -restore} must be selected.\n";
$usage .= "    -pkglocation=<pkgloc> Destination or Source path of config fileset package.\n";
$usage .= "    -h shows usage\n";

if (processArgs($usage)){
      if ($Arg_helpflag)
      {
          # help was requested.  Exit here.
          exit 0;
      }
      elsif (!$Arg_pkglocation)
      {
          logException("Execution Error.  Requires Pkg Location.  $usage", "ERROR", 101);
          logFile("Execution Error.  Invalid argument list.");
          exit 1;
      }
      elsif ((!$Arg_backupflag) && (!Arg_restoreflag))
      {
          logException("Execution Error.  No Backup or Restore operation.  $usage", "ERROR", 102);
          logFile("Execution Error.  Invalid argument list.");
          exit 1;
      }
      elsif (($Arg_backupflag) && ($Arg_restoreflag))
      {
          logException("Execution Error.  Backup and Restore both defined.  $usage", "ERROR", 103);
          logFile("Execution Error.  Invalid argument list.");
          exit 1;
      }


      #
      #  Generate the working directory name from the package.
      #
      $pkgname = extractFileDir($Arg_pkglocation);
      $pkgdir = $pkgname;
      $pkgdir =~ s/\./_/g;

      #
      # Build the working directory path.
      #
      $pkgpath = $ENV{"TEMP"};
      $pkgpath = "";
      if ($pkgpath eq "")
      {
         $pkgpath = $ENV{"INSITE2_HOME"} . "\\Temp";
      }
      $pkgpath .= "\\" . $pkgdir;

      #
      # Find valid location to perform deletes of temp directories.
      #
      $safepath = $ENV{"INSITE2_HOME"};
 
      chdir ("$safepath");
      $rmdircmd = "rmdir /s /q \"$pkgpath\"";
      if (-e $pkgpath)
      {
         `$rmdircmd`;
      }

      #
      # Create the working directory.
      $mkdircmd = "mkdir \"$pkgpath\"";
      `$mkdircmd`;

      #
      # Clear the brerr.txt log file.
      #
      logFile(" ");

      # Backup operation was selected.
      #
      if ($Arg_backupflag)
      {

         # Save configuration and agent restore batch files with the package.
         #
         $xmlpath = $ENV{"INSITE2_HOME"} . "\\BackupRestore\\SaveFilesConfig.xml";
         $agentpath = $ENV{"INSITE2_HOME"} . "\\BackupRestore\\RestoreAgent.bat";

         
         if (!(-e $xmlpath))
         {
            logException("No platform SaveFilesConfig.xml file present.", "ERROR", 201);
            logFile("Error.  Missing SaveFilesConfig.xml file.");
            cleanupError($safepath, $rmdircmd);
            exit 1;
         }

         $hashdata = readXML($xmlpath);
         if ($hashdata)
         {

            #  Wrong version of utility configuration.
            #
            if ($hashdata->{version} ne $validver)
            {
               logException("Invalid SaveFilesConfig.xml version.", "ERROR", 202);
               logFile("Error. Invalid SaveFilesConfig.xml version.");
               cleanupError($safepath, $rmdircmd);
               exit 1;
            }

            #
            # Fills array contains configuration files
            #
            @temparray = fillFileArray($hashdata);

            if ($debug)
            {
               for $i (0..$#temparray)
               {
                  print "$temparray[$i][0]\n";
                  print "$temparray[$i][1]\n";
                  print "$temparray[$i][2]\n";
                  print "$temparray[$i][3]\n";
                  print "$temparray[$i][4]\n\n";
               }
            }


            #
            # Overwrites current file at pkg location.
            #
            if (-e $Arg_pkglocation)
            {
               $rmfilecmd = "del /Q \"$Arg_pkglocation\"";
               `$rmfilecmd`;
            }

            $numfiles = 0;
            for $k (0..$#temparray)
            {
               #
               # Include only if exclude flag is disabled.
               #
               if ($temparray[$k][1] eq "0")
               {
                  $srcfile = $temparray[$k][3];
                  if (-e $srcfile)
                  {
                     if (-d $srcfile)
                     {
                         $dirname = "";
                         $dirname = extractFileDir($srcfile);

                         $dirpath = $pkgpath . "\\" . $dirname;
  
                         $mkdcmd = "mkdir $dirpath";
                         `$mkdcmd`;

                         $cpcmd = "xcopy \/y \/q \/e \"$temparray[$k][3]\"";
                         $cpcmd .= " \"$dirpath\"";
                         `$cpcmd`;
                         $numfiles++;

                     }
                     else
                     {
                        $cpcmd = "copy \/y \"$temparray[$k][3]\"";
                        $cpcmd .= " \"$pkgpath\"";
                        `$cpcmd`;
                        $numfiles++;
                     }
                  }

                  #
                  #  Could not find this configuration file.  Log exception and continue.
                  #
                  else
                  {
                     logException("Backup Configuration could not find file $srcfile.", "WARNING", 203);
                  }
               }
            }

            if ($numfiles)
            {
               # At least one config file found.  Save the device name and
               # current SaveFilesConfig.xml file.
               #
               backupDeviceName($pkgpath);
               $cpcmd = "copy \/y \"$xmlpath\"";
               $cpcmd .= " \"$pkgpath\"";
               `$cpcmd`;

               $cpcmd = "copy \/y \"$agentpath\"";
               $cpcmd .= " \"$pkgpath\"";
               `$cpcmd`;

               chdir ("$pkgpath");

               # Compress the configuration data and move to location.
               #
               $zipcmd = "zip -9r $pkgname *";
               `$zipcmd`;

               $cpcmd = "copy \/y $pkgname";
               $cpcmd .= " \"$Arg_pkglocation\"";
               `$cpcmd`;
            }
            else
            {
               logFile("Backup Configuration Error.  No files found.");
               logException("Backup Config Error.  No configuration files found.", "ERROR", 204);
               cleanupError($safepath, $rmdircmd);
               exit 1;
            }
         }
         else
         {
            logFile("Save Configuration Error.  Could not read SaveFilesConfig.xml.");
            logException("Could not read SaveFilesConfig file.", "ERROR", 205);
            cleanupError($safepath, $rmdircmd);
            exit 1;
         }

     }
     else

     #
     #  Restore operation selected.
     #
     {
         if (-e $Arg_pkglocation)
         {

            $cpcmd = "copy \/Y \"$Arg_pkglocation\"";
            $cpcmd .= " \"$pkgpath\"";
            `$cpcmd`;

            chdir("$pkgpath");
            $unzipcmd = "\"" . $ENV{'INSITE2_HOME'} . "\\BackupRestore\\unzip.exe\" $pkgname";
            `$unzipcmd`;

            # Compare the device name of the saved package with the current
            # installed platform's device.
            #
            if (!(validDeviceName($pkgpath)))
            {
               logException("Saved Configuration fileset is from a different device.", "ERROR", 301);
               logFile("Restore Error.  Configuration package does not match device.");
               cleanupError($safepath, $rmdircmd);
               exit 1;
            }

            $xmlpath = "SaveFilesConfig.xml";

            if (!(-e $xmlpath))
            {
               logException("Could not open SaveFilesConfig file in backup pkg.", "ERROR", 302);
               logFile("Restore Error.");
               cleanupError($safepath, $rmdircmd);
               exit 1;
            }
            
            $hashdata = readXML($xmlpath);
            if ($hashdata)
            {

               if ($hashdata->{version} ne $validver)
               {
                  logException("Invalid SaveFilesConfig.xml version.", "ERROR", 303);
                  logFile("Error. Invalid SaveFilesConfig.xml version.");
                  cleanupError($safepath, $rmdircmd);
                  exit 1;
               }

               @temparray = fillFileArray($hashdata);
 
               if ($debug)
               {
                  for $i (0..$#temparray)
                  {
                     print "$temparray[$i][0]\n";
                     print "$temparray[$i][1]\n";
                     print "$temparray[$i][2]\n";
                     print "$temparray[$i][3]\n";
                     print "$temparray[$i][4]\n\n";
                  }
               }

               # Now that we have a valid package, lets compare the savefilescfg
               # content with the verion installed with the platform.
               #
               $oldxmlpath = $ENV{"INSITE2_HOME"} . "\\BackupRestore\\SaveFilesConfig.xml";

               if (!(-e $oldxmlpath))
               {
                   logFile("Restore Configuration Error.  Could not read platform SaveFilesConfig.xml.");
                   logException("Could not read platform SaveFilesConfig.xml.", "ERROR", 304);
                   cleanupError($safepath, $rmdircmd);
                   exit 1;
               }

               $oldhashdata = readXML($xmlpath);
               if ($oldhashdata)
               {
                   @oldtemparray = fillFileArray($oldhashdata);
 
                   if ($debug)
                   {
                      for $i (0..$#oldtemparray)
                      {
                         print "$oldtemparray[$i][0]\n";
                         print "$oldtemparray[$i][1]\n";
                         print "$oldtemparray[$i][2]\n";
                         print "$oldtemparray[$i][3]\n";
                         print "$oldtemparray[$i][4]\n\n";
                      }
                   }
               }
               else
               {
                   logFile("Restore Configuration Error.  Could not read SaveFilesConfig.xml.");
                   logException("Restore Configuration Error.  Could not read SaveFilesConfig file.", "ERROR", 305);
                   cleanupError($safepath, $rmdircmd);
                   exit 1;
               }

               #
               # Loop through files in saved pkg.  Compare the version with the
               # platform version.

               for $k (0..$#temparray)
               {
                  if ($temparray[$k][1] eq "0")
                  {
                     $srcfile = $temparray[$k][0];
                     $srcver = $temparray[$k][2];
                     $destpath = $temparray[$k][3]; 
                     $altcmd = $temparray[$k][4];
                     $dirname = "";

                     if (($srcfile ne "") && (!(validFileVersion($srcfile,$srcver,$oldhashdata))))
                     {
                        logException("File $srcfile contains an invalid version.", "ERROR", 307);
                        logFile("Restore Configuration Error.  Invalid file version.");
                        cleanupError($safepath, $rmdircmd);
                        exit 1;
                     }

                     if ($srcfile eq "")
                     {
                        $dirname = extractFileDir($destpath);
                        $srcfile = $dirname;
                     }

                     if (-e $srcfile)
                     {
 
                           #
                           # By default, the restore perfoms a copy.
                           
                           if ($altcmd eq "")
                           {
                              if (-d $srcfile)
                              {
                                 $cpcmd = "xcopy \/y \/q \/e " . $srcfile;
                                 $cpcmd .= " \"$destpath\"";
                                 `$cpcmd`;
                              }
                              else
                              {
                                 $cpcmd = "copy \/y " . $srcfile;
                                 $cpcmd .= " \"$destpath\"";
                                 `$cpcmd`;
                              }
                           }

                           #
                           # An alternative command was given to apply to this
                           # saved file.  Usually is used for merging in a saved
                           # sitemap.xml file and generating the proper agent files.
                           #
                           else
                           {
                              $newcmd = $altcmd;
                              $newcmd .= " \"$pkgpath";
                              $newcmd .= "\\$temparray[$k][0]\"";
                              `$newcmd`;
                           }

                           if ($updSaveCfgFlag)
                           {
                              # updateSaveConfig($srcfile, $srcver);
                           }
                     }
                     else
                     {
                        logException("Restore Configuration could not find File $srcfile in package.", "WARNING", 306);
                     }
                  }
               }
            }
            else
            {
               logFile("Restore Configuration Error.  Could not read SaveFilesConfig.xml file.");
               logException("Restore Configuration Error.  Could not read SaveFilesConfig file.", "ERROR", 304);
               cleanupError($safepath, $rmdircmd);
               exit 1;
            }
         }
         else
         {
            logFile("Restore Configuration Error.  Invalid configuration pkg path.");
            logException("Restore Configuration Error.  Invalid configuration pkg path.", "ERROR", 305);
            cleanupError($safepath, $rmdircmd);
            exit 1;
         }

     }

     if ($Arg_backupflag)
     {
        logException("Successful Backup Operation.", "INFORMATION", 501);
        logFile("Backup Operation Completed Successfully.");
     } else {
        logException("Successful Restore Operation", "INFORMATION", 502);
        logFile("Restore Operation Completed Successfully.");
     }

     # No error, but still clean up the working directory
     #
     cleanupError($safepath, $rmdircmd); 
     exit 0;
}
else
{
     logException("Execution Error.  Invalid Command Line arguments.", "ERROR", 511);
     exit 1;
}
