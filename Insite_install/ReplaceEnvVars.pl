# ReplaceEnvVars.pl
#
# This script Reads the input file and appends it to the output file.
# Along the way it replaces any Environment variables with their values
#
# Usage:
#   perl ReplaceEnvVars.pl  InputFile  OutputFile

#########
# MAIN
########
if( $#ARGV < 1 )
{
    print "Not enough input variables, need input and output file\n";
    exit 1;
}
($InputFile,$OutputFile) = @ARGV;

if ( -e $OutputFile ) {
    `attrib -R $OutputFile`;
}
open (IN, $InputFile) || die "Unable to open input file:  $InputFile\n";
if ( ! open (OUT, ">>$OutputFile")) {
    close IN;
    print "Unable to open output file:  $OutputFile\n";
    exit(1);
}
print "Updating $OutputFile\n";

while ( <IN> )
{
    $line = $_;
    # find any strings that look like env vars: %SOMETHING%, and replace with env value
    if (/(%)(.*)(%)/) {
        $replace=$ENV{$2};
        if ( $replace )
        {
            $line =~ s,%.*%,$replace,;
            # print "$line\n";
        }
        else
        {
            print "\tThe following environment variable is undefined: %$2%\n";
        }
    }
    $line =~ s/(\r)//;
    print OUT $line;
}


close IN;
close OUT;
