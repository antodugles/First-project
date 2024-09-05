#!/usr/local/bin/perl
$debug=0;
#$debug=1;
# VpdEditor.cgi
# This script will read in VPD files from the log directory
# Allow the user to edit them, and write them out to the RO directory

######################  defines:
$LOG_DIR = "d:\\log\\";
$RW_DIAG_DIR = "";                  # output directory  , see below for initialization
$BPFILE = "EEP-BP-VPD-Data.txt";    # filename for backplane, special case also includes console and BEP
$MAX_DISP_FIELD = 11;               # maximum size of the field (if data is longer it will scroll
$DISP_FIELD_FUDGE = 0;              # number of extra characters above field length to make the input form
$REMOTE_HOST = $ENV{'HTTP_HOST'};
$RESFILE= "VpdEditorResults.html";

# the following lists the names of the boards that can be read and written by the diags.
@WRITE_BDS= qw(BP EB BM EQ PS RF SC TD0 TD1 TD2 TD3 TD4 TD5 TD6 TD7 XD);
@READ_BDS=(@WRITE_BDS, qw(PC2IP) );

####################

########################## initialization
$TARGETROOT=$ENV{'TARGET_ROOT'};
if($TARGETROOT eq ""){
	$TARGETROOT=`grep TARGET_ROOT $INSITEHOME/.properties | cut -f2 -d=`;
}

if ( -e "$TARGETROOT/resources/idunn/setup/log.res" ){
	open (LOGRES, "$TARGETROOT/resources/idunn/setup/log.res");
	while (<LOGRES>){
		if ( $_ =~ /LogPath *=/) {
			$var =$_;
			$var =~ s/[ \n\r]//g;
			($junk, $LOG_DIR) = split(/[=\#]/, $var);
			last;
		}
	}
}
$RW_DIAG_DIR="$TARGETROOT\\RW\\Diagnostics";
$OUT_FILE=$LOG_DIR . "\\$RESFILE";
$OUT_FILE =~ s/\\/\\\\/;  # need to escape the backslash so that perl won't absorb them when put in quotes

#########################################
# DisruptiveMode
# this function tests for Disruptive Mode
# Returns:  1 for disruptive mode
#           0 for not disruptive mode
sub DisruptiveMode()
{
    # check for disruptive mode.
    my $dis_file="$TARGETROOT/service/svcpform/diagLogs/.statusFile";
    $dis_file =~ s,\\,/,g;
    my $dis_mode=0;                # default is disruptive mode is disabled
    # print "dis file:$dis_file<br>";
    if(-f $dis_file)
    {
        # print "found file<br>";
        my $status_str1=`grep Status= $dis_file | cut -f2 -d=`;
        chop $status_str1;
        my @status_str=split(/\n/,$status_str1);
        my $temp_str=$status_str[$#status_str];
        # print "temp_str:$temp_str<br>";
        if($temp_str =~ /1/)
        {
            $dis_mode=1;
        }

    }
    return $dis_mode;
}

# DiagName converts an array of board names to the read or write name
# input = ( Prefix, array of board name )
sub DiagNames{
    my @Args = @_;
    my $Prefix = $Args[0];
    my $i;
    my $Result;
    for $i ( 1 .. $#Args )
    {
        $Result .= $Prefix . $Args[$i] . ",";
   }
    $Result =~ s/,$//; # remove trailing comma
    return $Result;
}

sub PrintDebug {
    if ($debug) {
        print "Debug:  @_<br>\n";
        #`echo @_ >> c:/temp/xxx.txt`;
    }
}
sub PrintDebugArr {
    if ($debug) {
        my $i;
        my @arr = @_;
        my $last = $#arr;
        print "Debug   -:";
        for $i ( 0 .. $last )
        {
            print "[$i]$arr[$i]:";
            if ( $i ==  $last ) {
                print "-";
            }
        }
        print "<br>\n";
    }
}
sub PrintError {
    print "<br>@_\n";
}

# ProcessFile reads in one data file
sub ProcessFile {
    my @fields = @_;
    my $FileName= $RW_DIAG_DIR . "//$fields[0]";
    my $SearchBegin = $fields[1];
    my $SearchEnd = $fields[2];
    my $ReadOnly = $fields[3];
    my $Prefix = $fields[4];
    if ( !-e $FileName ) {
        PrintError("File does not exist: $FileName (Check upper frame for errors).");
        return;
    }
    if ( (! $SearchBegin ) || (! $SearchEnd ) ) {
        PrintError("Error parsing config:  @fields");
        return;
    }
    my $Input;
    unless ( open $Input, $FileName ) {
        PrintError("Error opening file: $FileName (Check upper frame for errors).");
        return;
    }
    my $Line;
    my $InSection=0;
    my @Array;
    my $x;
    # be sure that all elements in Array are initialized
    my $i;
    for( $i=0; $i<=$MaxIndexBpFile; $i++) {
        $Array[$i]="";
    }
    $Array[$Rows{"FileName"}] = $fields[0]; # just the base name
    # Typical filename:  EEP-TD6-VPD-Data.txt
    # $SlotName is the text between the first and second dash:
    ($a, $SlotName,$c) = ( $fields[0] =~ /([^-]*-)([^-]*)(-.*)/);
    if ( $Prefix ) { $SlotName = $Prefix; }
    $Array[$Rows{"SlotName"}] = $SlotName;
    $Array[$Rows{"ReadOnly"}] = $ReadOnly;
    while ( $Line = <$Input>)
    {
        $Line =~ s/\r\n//;  # remove new line characters
        my ($cmd, $val) = split /:/, $Line;
        # remove leading and trailing whitespace
        $val =~ s/^\s//;
        $val =~ s/\s$//;
        if ( $Line =~ /$SearchBegin/) {
            #PrintDebug "************** Begin:  $Line\n";
            $InSection = 1;
            next;
        } elsif ( $Line =~ /$SearchEnd/) {
            #PrintDebug "************** End:  $Line\n";
            last;
        } elsif ( ($Prefix) && ( ! $Line =~ /$Prefix/) ) {
            next;  # if I have a prefix, and don't match, skip the data
        }
        if ( ! $InSection ) {
            next;
        }
        my $Index=0;
        #print "[$cmd]   ";
        if ( $FileName =~/$BPFILE/ ) 
        {
            $Index = $RowsBPFile{$cmd};
            #print "[$Index]\n";
        }  else 
        {
            $Index = $Rows{$cmd};
            #print "[$Index]\n";
        }
        #print "***$Index***$val***$Line\n";
        $Array[$Index]=$val;
    }
    $Array[$Rows{"Column"}]=$Column++;
    push @Data, [@Array ];
    close $Input;
}

# ReadDataFiles
# Reads a list of data files for VPD.Dat
# Calls ProcessFile to read each file and place into a nxn array, Data
# Each row in array represents one board
# Special case for Backplane because it also contains console and BEP (back end processor)
sub ReadDataFiles 
{
    # read in configuration file
    $Column=0;
    my $ConfigFile = $TargetRoot . "/service/svcpform/cgi-bin/VPD.dat";
    if ( ! -e $ConfigFile ){
        PrintError( "File does not exist:  $ConfigFile");
        return 1;
    }
    my $CONFIG;
    unless ( open $CONFIG, $ConfigFile ) {
        PrintError("Error openning file: $ConfigFile (Check upper frame for errors).");
        return 1;
    }
    my $Line;
    while ( $Line = <$CONFIG> )
    {
        if ( $Line =~ /^\#/ ){  #skip comments
            next;
        }
        if ( $Line =~ /^\s$/ ){ #skip blank lines
            next;
        }
        $Line =~ s/\r\n//;
        my @fields = split /:/, $Line;
        my $res = ProcessFile(@fields);

    }
    close $CONFIG;
    return 0;
}

# CreateButtons outputs the HTML for the Read and Write Buttons
sub CreateButtons
{
    print "   <table cellpadding=1 cellspacing=1 border=0>\n";
    print "     <tr>\n";
    print "         <td>\n";
    print "            <input type=submit value=Write class=button >\n";
    print "            <input type=hidden value=write name=cmd class=button>\n";
    print "         </td>\n";
    print "     </tr>\n";
    print "   </table>\n";
}

sub CreateForm
{
    my @FormArr = @_;
    print "<form name=\"Data\" enctype=form-data method=post action=/uscgi-bin/VpdEditor.cgi>\n"; 
    CreateButtons;
    print "<table border=1 cellpadding=0>\n";
    print "  <tr>\n";
    print "        <th>Field</th>\n";
    my $i;
    my $j;
    # create an array that tells you where in Data each slot is so that they display in the correct order
    my @ColumnIndex;
    for $i (0 .. $#FormArr)
    {
        $ColumnIndex [$FormArr[$i][$Rows{"Column"}]] = $i;
    }
    for $i (0 .. $#FormArr)
    {
        my $Slot = $FormArr[$ColumnIndex[$i]][$Rows{"SlotName"}];
        print "        <th>$Slot</th>\n";
    }
    print "        <th>Field</th>\n";
    print "</tr>\n";
    my $Type="text";  # field type, for last couple of rows will be hidden
    my $Special=0;
    for $j ( 0 .. $MaxIndex) 
    {
        my $Field = $RowName{$j};
        my $Size = $RowsMaxLen{$Field};
        my $FieldSize = $Size + $DISP_FIELD_FUDGE;
        if ( $FieldSize > $MaxFieldSize )
        { $FieldSize = $MaxFieldSize;}
        if ( $Field =~/PWA Information/ )
        { next; }  # this field is not printed
        my $Field_ = $Field;
        $Field_ =~ tr/ /_/;
        if ( $Field =~ /^__/ ) 
        { 
            $Special = $Field; 
            next;
        }
        if ( $Field =~ /HIDDEN/ )
        {   # rest of rows will be hidden in the form
            $Type = "hidden";
        }
        if ( !($Type eq "hidden") )
        {
            print "  <tr>";
            print "\n        <td class=field>$RowName{$j}</td> ";
        } else 
        {
        }
        my $TempSize = $Size;
        my $TempFieldSize = $ FieldSize;
        for $i ( 0 .. $#FormArr) 
        {
            my $iCol = $ColumnIndex[$i];
            print "\n        ";
            my $Slot = $FormArr[$iCol][$Rows{"SlotName"}];
            if ($Field =~ /Date of Manufacture/) {  
                if ($Slot =~ /PC/)
                { # special case for pc2ip board
                    $Size = 11;
                    $FieldSize = $Size + 2;
                }else
                {   # restore correct value
                    $Size = $TempSize;
                    $FieldSize = $TempFieldSize;
                }
            } 
            if ($Field =~ /Functional Revision/) {  
                if ($Slot =~ /PC/)
                { # special case for pc2ip board
                    $Size = 2;
                    $FieldSize = $Size + 2;
                }else
                {   # restore correct value
                    $Size = $TempSize;
                    $FieldSize = $TempFieldSize;
                }
            } 
            my $name = $Slot. "___" . $Field_;
            my $ShowField=0;
            if ($Slot =~ /Console/)
            {
                $ShowField = $RowsConDisp{$Field};
            }
            elsif ($Slot =~ /BEP/)
            {
                $ShowField = $RowsBEPDisp{$Field};
                #PrintDebugArr("**** BEP", $Field, $RowsBEPDisp{$Field}, $FormArr[$iCol][$j]);
            }
            elsif ($Slot =~ /BP/)
            {
                $ShowField = $RowsBPDisp{$Field};
            }
            else
            {
                if ( ! $Special )
                { $ShowField = 1; }
            }
            if ( $ShowField || ($Type eq "hidden") ) 
            {
                if ( ! ($Type eq "hidden") ) {print "<td>"; }
                print "<input type=$Type name=$name maxlength=$Size size=$FieldSize  value=\"$FormArr[$iCol][$j]\"></input>";
                if ( ! ($Type eq "hidden") ) 
                {
                    print(" $Slot");
                    print "</td>"; 
                }
            } else 
            {
                print "<td>-</td>";
            }
        }
        if ( !($Type eq "hidden") )
        {
            print "\n        <td class=field>$RowName{$j}</td>\n";
            print "  </tr>\n";
        }
    }
    # print out column heading at bottom
    print "\n  <tr>\n        <th>Field</th>\n";
    for $i (0 .. $#FormArr)
    {
        my $Slot = $FormArr[$ColumnIndex[$i]][$Rows{"SlotName"}];
        print "        <th>$Slot</th>\n";
    }
    print "        <th>Field</th>\n  </tr>\n";
    print "</table>\n";
    CreateButtons;
    print "</form>\n";
}

sub ProcessForm 
{
    PrintDebug("In ProcessForm");
    my @Keys = sort keys %FORM;
    my $IndexForm;
    my @Array;
    my $LastSlot="";
    #split out slot name from field name, create array of data
    for $IndexForm ( 0 .. $#Keys)
    {
        my $Item = $Keys[$IndexForm];
        if ( ! ($Item =~ /__/) )
        { next; }  # not a field name
        my $Slot;
        my $Field;
        ($Slot, $Field) = split /__/, $Item;
        if ( $LastSlot eq "" )
        {
            PrintDebug("*************** First slot:  :$Slot:");
            $LastSlot = $Slot;
        }
        elsif ( ! ($LastSlot eq $Slot) )
        {
            $Array[$Rows{"SlotName"}] = $LastSlot;
            # new board, push the array, and empty it.
            push @FormData, [@Array ];
            PrintDebug("Slot  $LastSlot");
            PrintDebugArr(@Array);
            @Array = ();
            $LastSlot = $Slot;
            PrintDebug("*************** New slot:  :$Slot:");
        }
        $Field =~ tr /_/ /;  # translate _ back to spaces
        $Field =~ s/(^\s)|(\s$)//g;  #remove leading and trailing whitespace
        my $Index;
        if ($Slot =~ /(BEP)|(BP)|(Console)/) {
            $Index = $RowsBPFile{$Field};
            PrintDebug("******** $Slot,^$Field,^$Index,^$FORM{$Item}");
        }
        else {
            $Index = $Rows{$Field};
        }
        my $Val = $FORM{$Item};
        $Val =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg; # convert any hexcodes back to ASCII
        $Array[$Index] = $Val;
    }
    # push last slot
    push @FormData, [@Array ];
    CreateForm(@FormData);
    WriteFiles(@FormData);
}

sub WriteFiles 
{
    @Data = @_;
    my $i;
    my $j;
    my $LastRow = $Rows{"__SPECIAL"} -1;
    # following iXXX variables will hold index of slots that go into BEP file
    my $iConsole=-1;
    my $iBEP=-1;
    my $iBP=-1;
    my $Dir = "";
    for $i ( 0 .. $#Data) 
    {
        my $FileName = $Data[$i][$Rows{"FileName"}];
        if ( $FileName =~ /$BPFILE/ )
        {    # special case handle 
            for ($Data[$i][$Rows{"SlotName"}])
            {
                /Console/ and do {
                    $iConsole = $i;
                    next;
                };
                /BEP/ and do {
                    $iBEP = $i;
                    next;
                };
                /BP/ and do {
                    $iBP = $i;
                    next;
                };
                next; 
            }
        } 
        if ( $FileName =~ /$BPFILE/ )
        {    
            next;
        }
        $FileName = $RW_DIAG_DIR . "\\$FileName";
        unless ( open OUTF, ">$FileName" ) {
            PrintError("Error opening file: $FileName (Check upper frame for errors).");
            return;
        }
        for $j ( 0 .. $LastRow ) 
        {
            print OUTF "$RowName{$j}";
            if ( $RowsMaxLen{$RowName{$j}} > 0 )
            {
                print OUTF ": $Data[$i][$j]";
            }
            print OUTF "\n";
        }
        close OUTF;
    }
    # now handle special case of BP
    $FileName = $RW_DIAG_DIR . "\\" . $BPFILE;
    unless ( open OUTF, ">$FileName" ) {
        PrintError("Error opening file: $FileName (Check upper frame for errors).");
        return;
    }

    my $k;
    for $k ( 0.. $#RowsBPOrder)
    {   # first get row index into @Data
        my $FieldName = $RowsBPOrder[$k];
        $i = $iBP;
        if ( $FieldName =~ /^Console/ ) {
            $i = $iConsole;
        } elsif ( $FieldName =~ /^BEP/) {
            $i = $iBEP;
        }
        print OUTF "$FieldName";
        # lookup column, and print
        $j = $RowsBPFile{$FieldName};
        if ( $RowsMaxLen{$RowName{$j}} > 0 )
        {
            print OUTF ": $Data[$i][$j]";
        }
        print OUTF "\n";
    }
    close OUTF;
}

#####
# CheckForErrors
#
# This function scans the output file for errors.  If any are detected
# it will output a message to the main frame to tell the user to look
# for errors
sub CheckForErrors
{
    if ( ! -e $OUT_FILE ){
        return 1;
    }
    my $INFILE;
    unless ( open $INFILE, $OUT_FILE ) {
        PrintError("Error openning file: $OUT_FILE");
        return;
    }
    my @Results;
    @Results = <$INFILE>;
    close $INFILE;

    my $Line;
    my $errorFlag;
    $errorFlag=0;
    foreach $Line (@Results)
    {
        if ( $Line =~ /(Error)|(Failed)/i ) {
            $errorFlag=1;
            last;
        }
    }
    my $OUTFILE;
    unless ( open $OUTFILE, ">>$OUT_FILE" ) {
        PrintError("Error openning file for writing: $OUT_FILE");
        return;
    }
    if ( $errorFlag == 0 ) {
        print $OUTFILE "<br><font size=+1 color=green><strong>VPD data operation completed successfully.</strong></font>";
    } else {
        print $OUTFILE "<br><font size=+1 color=red><strong>Errors have occurred.  Scroll up to see the errors.</strong></font>";
    }
    close $OUTFILE;
}


##########
# Main
#########
print "Content-type: text/html\n\n";
print "<head>\n";
print "  <link href=/service/VpdEditor.css rel=stylesheet type=text/css />\n";

print "</head>\n";
print "<html>\n<body bgcolor=#B5B5B5 onload=\"parent.results.location.replace('/log/$RESFILE');\">\n";

$TargetRoot=$ENV{"TARGET_ROOT"};
$TargetRoot =~ s/\\/\//g;

$cnt=0;
%Rows = ( # this contains all of the row, those before __SPECIAL are the order in most of the files
         "PWA Information"                   => $cnt++,
         "Product Name"                      => $cnt++,
         "Design Owner Group"                => $cnt++,
         "Part Number"                       => $cnt++,
         "Functional Revision"               => $cnt++,
         "Bar Code Serial Number"            => $cnt++,
         "Date of Manufacture"               => $cnt++,
         "Power On Hours"                    => $cnt++,
         "Fab Revision"                      => $cnt++,
         "Date of Installation"              => $cnt++,
         "User Data 00"                      => $cnt++,
         "User Data 01"                      => $cnt++,
         "User Data 02"                      => $cnt++,
         "User Data 03"                      => $cnt++,
         "User Data 04"                      => $cnt++,
         "User Data 05"                      => $cnt++,
         "User Data 06"                      => $cnt++,
         "User Data 07"                      => $cnt++,
         "User Data 08"                      => $cnt++,
         "User Data 09"                      => $cnt++,
         "User Data 10"                      => $cnt++,
         "User Data 11"                      => $cnt++,
         "User Data 12"                      => $cnt++,
         "User Data 13"                      => $cnt++,
         "User Data 14"                      => $cnt++,
         "User Data 15"                      => $cnt++,
         "Minimum Application Software Version"  => $cnt++,
         "Service Defect Reference Number 1"  => $cnt++,
         "Service Defect Reference Number 2"  => $cnt++,
         "Service Defect Reference Number 3"  => $cnt++,
         "Service Defect Reference Number 4"  => $cnt++,
         "Service Defect Reference Number 5"  => $cnt++,
         "Service Dispatch Number 1"          => $cnt++,
         "Service Dispatch Number 2"          => $cnt++,
         "Service Dispatch Number 3"          => $cnt++,
         "Service Dispatch Number 4"          => $cnt++,
# The following rows are unique to the BP
         "__SPECIAL"                          => $cnt++,
         "Service Dispatch Number"            => $cnt++,
         "__START_BEP"                        => $cnt++,
         "BEP Serial Number"                  => $cnt++,
         "BEP Base Image Software Version"    => $cnt++,
         "__START_CON"                        => $cnt++,
         "Console Serial Number"              => $cnt++,
# The following are last, placeholders for flags
         "HIDDEN"                             => $cnt++,
         "SlotName"                           => $cnt++,
         "FileName"                           => $cnt++,
         "ReadOnly"                           => $cnt++,
         "Column"                             => $cnt++
         );

@RowsBPOrder = ( # order of rows in BP file
           "PWA Information",
           "Product Name",
           "Design Owner Group",
           "Part Number",
           "Functional Revision",
           "Bar Code Serial Number",
           "Date of Manufacture",
           "Power On Hours",
           "Fab Revision",
           "Date of Installation",
           "Service Defect Reference Number 1",
           "Service Defect Reference Number 2",
           "Service Defect Reference Number 3",
           "Service Defect Reference Number 4",
           "Service Defect Reference Number 5",
           "Service Dispatch Number",
           "Console Information",
           "Console Part Number",
           "Console Serial Number",
           "Console Date of Manufacture",
           "Console Power On Hours",
           "Back End Processor (BEP) Information",
           "BEP Part Number",
           "BEP Functional Revision",
           "BEP Serial Number",
           "BEP Date of Manufacture",
           "BEP Power On Hours",
           "BEP Date of Installation",
           "BEP Base Image Software Version",
           "BEP Service Defect Reference Number 1",
           "BEP Service Defect Reference Number 2",
           "BEP Service Defect Reference Number 3",
           "BEP Service Defect Reference Number 4",
           "BEP Service Defect Reference Number 5",
           "BEP Service Dispatch Number 1",
           "BEP Service Dispatch Number 2",
           "BEP Service Dispatch Number 3",
           "BEP Service Dispatch Number 4"
           );

%RowsBPFile = (
           "PWA Information"                       => $Rows{"PWA Information"},        
           "Product Name"                          => $Rows{"Product Name"},           
           "Design Owner Group"                    => $Rows{"Design Owner Group"},     
           "Part Number"                           => $Rows{"Part Number"},            
           "Functional Revision"                   => $Rows{"Functional Revision"},    
           "Bar Code Serial Number"                => $Rows{"Bar Code Serial Number"}, 
           "Date of Manufacture"                   => $Rows{"Date of Manufacture"},    
           "Power On Hours"                        => $Rows{"Power On Hours"},         
           "Fab Revision"                          => $Rows{"Fab Revision"},           
           "Date of Installation"                  => $Rows{"Date of Installation"},   
           "Service Defect Reference Number 1"     => $Rows{"Service Defect Reference Number 1"},
           "Service Defect Reference Number 2"     => $Rows{"Service Defect Reference Number 2"},
           "Service Defect Reference Number 3"     => $Rows{"Service Defect Reference Number 3"},
           "Service Defect Reference Number 4"     => $Rows{"Service Defect Reference Number 4"},
           "Service Defect Reference Number 5"     => $Rows{"Service Defect Reference Number 5"},
           "Service Dispatch Number"               => $Rows{"Service Dispatch Number"},
           "Console Information"                   => $Rows{"PWA Information"},
           "Console Part Number"                   => $Rows{"Part Number"},
           "Console Serial Number"                 => $Rows{"Console Serial Number"},
           "Console Date of Manufacture"           => $Rows{"Date of Manufacture"},
           "Console Power On Hours"                => $Rows{"Power On Hours"},
           "Back End Processor (BEP) Information"  => $Rows{"PWA Information"}, 
           "BEP Part Number"                       => $Rows{"Part Number"},
           "BEP Functional Revision"               => $Rows{"Functional Revision"},   
           "BEP Serial Number"                     => $Rows{"BEP Serial Number"},
           "BEP Date of Manufacture"               => $Rows{"Date of Manufacture"},
           "BEP Power On Hours"                    => $Rows{"Power On Hours"},
           "BEP Date of Installation"              => $Rows{"Date of Installation"},
           "BEP Base Image Software Version"       => $Rows{"BEP Base Image Software Version"},
           "BEP Service Defect Reference Number 1" => $Rows{"Service Defect Reference Number 1"},
           "BEP Service Defect Reference Number 2" => $Rows{"Service Defect Reference Number 2"},
           "BEP Service Defect Reference Number 3" => $Rows{"Service Defect Reference Number 3"},
           "BEP Service Defect Reference Number 4" => $Rows{"Service Defect Reference Number 4"},
           "BEP Service Defect Reference Number 5" => $Rows{"Service Defect Reference Number 5"},
           "BEP Service Dispatch Number 1"         => $Rows{"Service Dispatch Number 1"},
           "BEP Service Dispatch Number 2"         => $Rows{"Service Dispatch Number 2"},
           "BEP Service Dispatch Number 3"         => $Rows{"Service Dispatch Number 3"},
           "BEP Service Dispatch Number 4"         => $Rows{"Service Dispatch Number 4"},
           "FileName"                              => $Rows{"FileName"},
           "ReadOnly"                              => $Rows{"ReadOnly"},
           "Column"                                => $Rows{"Column"},
#Special cases
           "Service Dispatch Number 1"         => $Rows{"Service Dispatch Number 1"},
           "Service Dispatch Number 2"         => $Rows{"Service Dispatch Number 2"},
           "Service Dispatch Number 3"         => $Rows{"Service Dispatch Number 3"},
           "Service Dispatch Number 4"         => $Rows{"Service Dispatch Number 4"}
           );

%RowsMaxLen = (
               "PWA Information"                   => 0,
               "Product Name"                      => 15,
               "Design Owner Group"                => 5,
               "Part Number"                       => 10,
               "Functional Revision"               => 1,
               "Bar Code Serial Number"            => 20,
               "Date of Manufacture"               => 8,
               "Power On Hours"                    => 13,
               "Fab Revision"                      => 2,
               "Date of Installation"              => 8,
               "User Data 00"                      => 1,
               "User Data 01"                      => 1,
               "User Data 02"                      => 1,
               "User Data 03"                      => 1,
               "User Data 04"                      => 1,
               "User Data 05"                      => 1,
               "User Data 06"                      => 1,
               "User Data 07"                      => 1,
               "User Data 08"                      => 1,
               "User Data 09"                      => 1,
               "User Data 10"                      => 1,
               "User Data 11"                      => 1,
               "User Data 12"                      => 1,
               "User Data 13"                      => 1,
               "User Data 14"                      => 1,
               "User Data 15"                      => 1,
               "Minimum Application Software Version"  => 15,
               "Service Defect Reference Number 1"  => 8,
               "Service Defect Reference Number 2"  => 8,
               "Service Defect Reference Number 3"  => 8,
               "Service Defect Reference Number 4"  => 8,
               "Service Defect Reference Number 5"  => 8,
               "Service Dispatch Number 1"          => 8,
               "Service Dispatch Number 2"          => 8,
               "Service Dispatch Number 3"          => 8,
               "Service Dispatch Number 4"          => 8,
# The following rows are unique to the BP
               "__SPECIAL"                          => 1,
               "Service Dispatch Number"            => 8,
               "__START_BEP"                        => 1,
               "BEP Serial Number"                  => 20,
               "BEP Base Image Software Version"    => 15,
               "__START_CON"                        => 1,
               "Console Serial Number"              => 18,
# The following are last, placeholders for flags
               "HIDDEN"                             => 0,
               "SlotName"                           => 5,
               "FileName"                           => 25,
               "ReadOnly"                           => 1
               );
    $MaxFieldSize=0;
    for $i (keys %RowsMaxLen) {
        if ($RowsMaxLen{$i} > $MaxFieldSize) {
            $MaxFieldSize = $RowsMaxLen{$i};
        }
    }

#Set the maximum display field (not the maximum number of chars in field.
if ( $MaxFieldSize > $MAX_DISP_FIELD ) {
    $MaxFieldSize = $MAX_DISP_FIELD;
}

%RowsBPDisp = (  # fields to display/edit
               "Product Name"                          => 1,
               "Design Owner Group"                    => 1,
               "Part Number"                           => 1,
               "Functional Revision"                   => 1,
               "Bar Code Serial Number"                => 1,
               "Date of Manufacture"                   => 1,
               "Power On Hours"                        => 1,
               "Fab Revision"                          => 1,
               "Date of Installation"                  => 1,
               "Service Defect Reference Number 1"     => 1,
               "Service Defect Reference Number 2"     => 1,
               "Service Defect Reference Number 3"     => 1,
               "Service Defect Reference Number 4"     => 1,
               "Service Defect Reference Number 5"     => 1,
               "Service Dispatch Number"               => 1,
               );
%RowsConDisp = (  # fields to display/edit
                "Part Number"                       => 1,
                "Console Serial Number"             => 1,
                "Date of Manufacture"               => 1,
                "Power On Hours"                    => 1,
                );


%RowsBEPDisp = (  # fields to display/edit
                "Part Number"                       => 1,
                "Functional Revision"               => 1,
                "BEP Serial Number"                 => 1,
                "Date of Manufacture"               => 1,
                "Power On Hours"                    => 1,
                "Date of Installation"              => 1,
                "BEP Base Image Software Version"   => 1,
                "Service Defect Reference Number 1" => 1,
                "Service Defect Reference Number 2" => 1,
                "Service Defect Reference Number 3" => 1,
                "Service Defect Reference Number 4" => 1,
                "Service Defect Reference Number 5" => 1,
                "Service Dispatch Number 1"         => 1,
                "Service Dispatch Number 2"         => 1,
                "Service Dispatch Number 3"         => 1,
                "Service Dispatch Number 4"         => 1,
                );


$MaxIndex=0;
foreach $x (values %Rows) {
    if ( $x >$MaxIndex) {$MaxIndex = $x} ;
}
$MaxIndexBpFile=$MaxIndex;
foreach $x (values %RowsBPFile) {
    if ( $x >$MaxIndexBpFile) {$MaxIndexBpFile = $x} ;
}
#print "MaxIndex = $MaxIndex\n\n";

# generate a reverse lookup for rows
foreach $x (keys %Rows ) {
    $RowName{$Rows{$x}}=$x;
}
if ( $debug )
{
    PrintDebug("\n<br>\n<br>\n<br>\n<br> Rows");
    PrintDebug(%Rows);
    my @RowsBPF = sort keys %RowsBPFile;
    PrintDebug "\n<br><br>: keys RowsBPFile";
    PrintDebugArr(@RowsBPF);
    print "\n<br>\n<br> Debug:  ";
    for $x (sort keys %RowName) {
        print "[$x]:$RowName{$x}  ";
    }
    print "<br>\n";
}

$RequestMethod = $ENV{'REQUEST_METHOD'};
$RequestMethod =~ tr/a-z/A-Z/;

if ( $RequestMethod eq  "POST" ) {
   read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
} else {
   $buffer = $ENV{'QUERY_STRING'};
}
if ($debug==1) {
        print"<br>  debug: REQUEST_METHOD = $RequestMethod <br>\n";
        $tempstr = $buffer;
        $tempstr =~ s/\&/\&<br>\n/g;
	print"<br>  debug: buffer = $tempstr<br>\n";
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
$command=$FORM{"Action"};
$command=$FORM{"cmd"};
if ( $debug==1 ) {
    print "  debug Variable:   command  =  :$command:<br>\n";
}
@Bds=();
if ($debug==1) {
    $DiagExe="DiagExecImmediated.exe";
}
else
{
    $DiagExe="DiagExecImmediate.exe";
}

$clientIpAddress=$ENV{'REMOTE_ADDR'};
$clientHostName = $ENV{'REMOTE_HOST'};
if( !(($clientIpAddress eq "127.0.0.1") || ($clientHostName eq "localhost")) ){
    if ( ! DisruptiveMode() )
    {
        print "<br><br><center><font color=red><h2>You must enter disurptive mode before running this diagnostic.</h3></font></center>";
        print "</body></html>";
        exit;
    }
}
for ($command ) {
    # case ^$ is default case on start-up, that is an empty command
    /(read)|(^$)/ and do {  
        print "<font size=+1>Modify data in the table below, and click write to update the boards.</font>\n";
        if ( $debug==1 ){ print " debug:  in Read<br>\n";}
        # first delete any old files in input dir
        # call the read diag to create new ones
        # and display the form
        $DelFiles = $RW_DIAG_DIR . "/EEP-* $OUT_FILE";
	$DelFiles =~ s?/?\\?g;
        $DelCmd="cmd /c \"del /f $DelFiles 2>&1 \"";
        $res = `$DelCmd`;
        $Bds=DiagNames("UTIL_VPD_READ_", @READ_BDS);
        # in the following command %26 (hex value) is used for the &
        $ReadCmd="cmd /c \"$DiagExe name=AcqDiags%26StatusFile=VpdReadAllStat%26args=$Bds%26cnt=1%26remoteip="."//$REMOTE_HOST 2>&1 >$OUT_FILE \"";
        `$ReadCmd`;
        $res = ReadDataFiles;
        CreateForm(@Data);
        last;
    };
    /write/ and do {
        if ( $debug==1 ){ print " debug:  in Form<br>\n";}
        print "<font size=+1 color=yellow><strong>VPD data have been saved. Reboot the system to resume to correct operation.</strong></font>\n";
        ProcessForm;
        $Bds=DiagNames("UTIL_VPD_WRITE_", @WRITE_BDS);
        # in the following command %26 (hex value) is used for the &
        $WriteCmd="cmd /c \"$DiagExe name=AcqDiags%26StatusFile=VpdReadAllStat%26args=$Bds%26cnt=1%26remoteip="."//$REMOTE_HOST 2>&1 >$OUT_FILE \"";
        `$WriteCmd`;
        last;
    };
}
CheckForErrors;
print "</body></html>";
