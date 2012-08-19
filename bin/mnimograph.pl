#!/usr/bin/env perl

=head1 NAME

mnimograph.pl

=head1 SYNOPSIS

mnimograph.pl [ options ] outfile

=head1 DESCRIPTION

mnimograph.pl is a tool for memory usage graphing.

It will collect memory usage values every 5 seconds
until being stopped by typing 'Q' and pressing <Enter>.

Its output is a graph of the values in .png format.

=head1 OPTIONS

=head2 -alc (ALways Complete)

With this option a graph will be plotted, even if mnimograph.pl is stopped by a SIGINT signal.

=head2 -gui

Launches the GUI version (mnimograph_gui.pl).

=head1 DEPENDENCIES

-Gnuplot ( >= 4.4 )

-Imagemagick ( >= 6.6.9-7 )

-Perl ( >= 5.14.2 )

-Chart::Gnuplot ( >= 0.17 )

-Term::ReadKey ( >= 2.30 )

=head1 AUTHOR

Dimitrios - Georgios Kontopoulos
<dgkontopoulos@member.fsf.org>

=head1 WEBSITE

B<https://github.com/dgkontopoulos/mnimograph.pl/>

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
use File::Spec;
use Term::ReadKey;

our $VERSION = 1.0;

( @ARGV >= 1 && @ARGV <= 3 )
  or die "Usage: mnimograph.pl [ options ] output_filename\n";

my $output_file;
my $always_complete = 0;
my $argv_length     = @ARGV;
my $gui             = 0;

if ( @ARGV == 1 )
{
    if ( $ARGV[0] eq '-gui' )
    {
        system '/opt/mnimograph/bin/mnimograph_gui.pl&';
        exit;
    }
    else
    {
        $output_file = $ARGV[0];
    }
}
else
{
    for ( 0 .. $argv_length - 2 )
    {
        if ( $ARGV[$_] eq '-alc' )
        {
            $always_complete = 1;
        }
        elsif ( $ARGV[$_] eq '-gui' )
        {
            $gui = 1;
        }
        else
        {
            say "No such flag: $ARGV[$_]";
            die "Usage: mnimograph.pl [ options ] output_filename\n";
        }
    }
    $output_file = $ARGV[ $argv_length - 1 ];
    if ( $gui == 1 )
    {
        $output_file = File::Spec->rel2abs($output_file);
        system "/opt/mnimograph/bin/mnimograph_gui.pl $output_file&";
        exit;
    }
}

if ( $output_file !~ /[.]png$/ )
{
    $output_file .= '.png';
}

open my $fh, '>', $output_file
  or die "ERROR! No permission to write to file \"$output_file\"";
close $fh;

say 'This is a tool for memory usage graphing.';
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
    if ( $always_complete == 1 )
    {
        $SIG{'INT'} = 'signal_handling';
    }
    my $key;
    do
    {
        $key = ReadKey(1);
    } while ( time < 5 && !( defined $key ) );
    if ( defined $key && $key =~ /Q/ )
    {
        last;
    }
}
plot();

sub signal_handling
{
    plot();
    exit;
}

sub plot
{
    say "\nPlotting $output_file ...";
    if ( $counter <= 1 )
    {
        say 'ERROR! Not enough values for a graph to be produced!';
        say 'Please let the program run for a little longer next time.';
        exit;
    }
    my $chart = Chart::Gnuplot->new(
        output => "$output_file",
        xlabel => 'Time (sec)',
        ylabel => 'Memory (MB)'
    );

    my $dataSet = Chart::Gnuplot::DataSet->new(
        xdata  => \@index,
        ydata  => \@values,
        style  => 'linespoints',
        color  => '#FF0000',
        plotbg => '#FFFFFF'
    );
    $chart->plot2d($dataSet);
    say 'Done.';
    return 0;
}
