#!/usr/bin/env perl

=head1 NAME

mnimograph.pl

=head1 AUTHOR

Dimitrios - Georgios Kontopoulos

=head1 DESCRIPTION

mnimograph.pl is a tool for memory usage graphing.

It will collect memory usage values every 5 seconds
until being stopped by typing 'Q' and pressing <Enter>.

Its output is a graph of the values in .eps format.

=head1 DEPENDENCIES

-Gnuplot ( >= 4.4 )

-Perl ( >= 5.14.2 )

-Chart::Gnuplot ( >= 0.17 )

-Term::ReadKey ( >= 2.30 )

=head1 USAGE

mnimograph.pl output_filename

=head1 LICENSE

This program is free software: you can redistribute it and/or modify 
it under the terms of the GNU General Public License as 
published by the Free Software Foundation, either version 3 of the 
License, or (at your option) any later version.

For more information, see http://www.gnu.org/licenses/.

=cut

use strict;
use warnings;

use feature qw(say);

use Chart::Gnuplot;
use Term::ReadKey;

@ARGV == 1 or die "Usage: $0 output_filename\n";
my $output_file = $ARGV[0];

if ( $output_file !~ /[.]eps$/ )
{
    $output_file .= '.eps';
}

open my $fh, '>', $output_file
  or die "ERROR! No permission to write to file \"$output_file\"";
close $fh;

say "This is a tool for memory usage graphing.";
say "When you're done, type 'Q' and press Enter.\n";

my ( $used_memory, @index, @values );
my $counter  = 0;
my $counter2 = 0;
while (1)
{
    my $mem = `free -m`;
    if ( $mem =~ /buffers\/cache:\s+(\d+)\s+/ )
    {
        $used_memory = $1;
        if ( $mem =~ /Swap:\s+\d+\s+(\d+)\s/ )
        {
            $used_memory += $1;
            $values[$counter] = $used_memory;
            $index[$counter]  = $counter2;
            $counter++;
            $counter2 += 5;
        }
        sleep 5;
    }
    my $key;
    do
    {
        $key = ReadKey(1);
    } while ( time < 5 && !( defined $key ) );
    if ( defined $key && $key =~ /Q/ )
    {
        say "Plotting $output_file ...\n";
        last;
    }
}
if ( $counter <= 1 )
{
    say "ERROR! Not enough values for a graph to be produced!";
    say "Please let the program run for a little longer next time.";
    exit;
}
my $chart = Chart::Gnuplot->new( output => "/tmp/$output_file" );

my $dataSet = Chart::Gnuplot::DataSet->new(
    xdata  => \@index,
    ydata  => \@values,
    style  => "linespoints",
    color  => "#FF0000",
    plotbg => "#FFFFFF"
);
$chart->plot2d($dataSet);

say "Done.";
