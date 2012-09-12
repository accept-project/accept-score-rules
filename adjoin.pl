#!/usr/bin/perl

# A generic perl script that adjoins corresponding lines in a given
# list of parallel files, prepends each of the lines with a given identifier,
# and outputs the corresponding lines in a record in the output file.
# Records are separated by empty lines.
#
# Example after adjoin.pl output.txt FILE-A A.txt FILE-B B.txt:
#  A.txt:                             output.txt:
#   This is                            FILE-A<tab>This is
#   And this is                        FILE-B<tab>the first line.
#                                      <emptyline>
# B.txt:                               FILE-A<tab>And this is
#   the first line.                    FILE-B<tab>the second.
#   the second.                        <emptyline>



if (scalar(@ARGV) < 3) {
    print "$0 <outfile> <id1> <file1> [<id2> <file2> [<id3> <file3> [...]]]";
    exit -1;
}

my @names;
my @files;

$outfile = shift;
open OUTFILE, ">$outfile";
$info = "";

while ($name = shift) {
    push @names, $name;
    $file = shift;
    $info .= " $file ($name)";
    my $fhandle;
    open $fhandle, $file;
    push @files, $fhandle;
}

print "Combining ". scalar(@files) . " files$info into $outfile\n";

LOOP:
while (1) {
    for ($i = 0; $i < scalar(@names); $i++) {
	my $fhandle = $files[$i];
       	if ($str = <$fhandle>) {
	    chomp($str);
	    print OUTFILE "$names[$i]\t$str\n";
	}
	else {
	    last LOOP;
	}	
    }
    print OUTFILE "\n";
}

close OUTFILE;
foreach $fhandle (@files) {
    close $fhandle;
}

print "Done.\n";
