#!/usr/bin/perl

my @names;
my @files;

$outfile = shift;
open OUTFILE, ">$outfile";

while ($name = shift) {
    push @names, $name;
    $file = shift;
    my $fhandle;
    open $fhandle, $file;
    push @files, $fhandle;
}

my $stopped = 0;

LOOP:
while (1) {
    for ($i = 0; $i < $#names; $i++) {
       	if ($str = <$files[$i]>) {
	    chomp($str);
	    print OUTFILE, "$names[$i]\t$str\n";
	}
	else {
	    last LOOP;
	}	
    }
    print OUTFILE, "\n";
}

close OUTFILE;
foreach $fhandle (@files) {
    close $fhandle;
}
