#!PERL_HOME\bin\perl

print "Content-Type: text/html\n\n";
print header;

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
$access = "1";
print $access;
