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

A graph will be plotted even if mnimograph.pl is stopped by a SIGINT signal.

=head2 -cached

Plots also cached memory. Incompatible with -pidonly.

=head2 -gui

Launches the GUI version (mnimograph_gui.pl).

=head2 -pid=[PID]

Plots memory used by PID.

=head2 -pidonly

Plots only memory used by PID. Always in combination with -pid=[PID], incompatible with -cached, -swap.

=head2 -swap

Plots also swap. Incompatible with -pidonly.

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

( @ARGV >= 1 && @ARGV <= 7 )
  or die "\033[1mUsage: mnimograph.pl [ options ] output_filename\033[0m\n";

my $output_file;
my $always_complete = 0;
my $argv_length     = @ARGV;
my $gui             = 0;
my $cached          = 0;
my $swap            = 0;
my $pid             = q{};
my $pidonly         = 0;

if ( @ARGV == 1 )
{
    #########################
    #Launch the GUI version.#
    #########################
    if ( $ARGV[0] eq '-gui' )
    {
        system '/opt/mnimograph/bin/mnimograph_gui.pl&';
        exit;
    }
    else
    {
        if ( $ARGV[0] !~ /^-/ )
        {
            $output_file = $ARGV[0];
        }
        else
        {
            die
"\033[1mUsage: mnimograph.pl [ options ] output_filename\033[0m\n";
        }
    }
}
else
{
    ######################
    #Parameters checking.#
    ######################
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
        elsif ( $ARGV[$_] eq '-swap' )
        {
            $swap = 1;
        }
        elsif ( $ARGV[$_] eq '-cached' )
        {
            $cached = 1;
        }
        elsif ( $ARGV[$_] =~ /[-]pid=(\d+)/ )
        {
            $pid = $1;
        }
        elsif ( $ARGV[$_] eq '-pidonly' )
        {
            $pidonly = 1;
        }
        else
        {
            say "\033[1mNo such flag: $ARGV[$_]\033[0m";
            die
"\033[1mUsage: mnimograph.pl [ options ] output_filename\033[0m\n";
        }
    }
    if ( $pidonly == 1 && $pid eq q{} )
    {
        die "\033[1mUsage: mnimograph.pl [ options ] output_filename\033[0m\n";
    }
    if ( $pidonly == 1 && ( $swap + $cached ) > 0 )
    {
        die "\033[1mUsage: mnimograph.pl [ options ] output_filename\033[0m\n";
    }
    $output_file = $ARGV[ $argv_length - 1 ];
    if ( $output_file =~ /-/ )
    {
        die "\033[1mUsage: mnimograph.pl [ options ] output_filename\033[0m\n";
    }
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
  or die
  "\033[1mERROR! No permission to write to file \"$output_file\"\033[0m\n";
close $fh;

unlink $output_file;

say 'This is a tool for memory usage graphing.';
say "When you're done, type 'Q' and press Enter.\n";

my ( $used_memory, @index, @values, @swap, @cache, @pid );
my $counter  = 0;
my $counter2 = 0;
while (1)
{
    #############################
    #Collect used memory values.#
    #############################
    my $mem = `free -m`;
    if ( $mem =~ /buffers\/cache:\s+(\d+)\s+/ )
    {
        if ( $pidonly == 0 )
        {
            $used_memory = $1;
            ######################
            #Collect swap values.#
            ######################
            if ( $mem =~ /Swap:\s+\d+\s+(\d+)\s/ )
            {
                if ( $swap == 1 )
                {
                    $swap[$counter] = $1;
                }
                $used_memory += $1;
                $values[$counter] = $used_memory;
            }
            ###############################
            #Collect cached memory values.#
            ###############################
            if ( $cached == 1 )
            {
                if ( $mem =~ /Mem:.+\s+(\d+)\n/ )
                {
                    $cache[$counter] = $1;
                }
            }
        }
        ############################
        #Collect PID memory values.#
        ############################
        if ( $pid ne q{} )
        {
            ####################################
            #If PID does not exist, value is 0.#
            ####################################
            if ( !( -e "/proc/$pid/smaps" ) )
            {
                $pid[$counter] = 0;
            }
            ############################################################
            #If PID is owned by the user, get Private Dirty RSS values.#
            ############################################################
            if ( -O "/proc/$pid/smaps" )
            {
                my $pidv = `cat /proc/$pid/smaps | grep Private_Dirty`;
                $pid[$counter] = private_dirty_sum($pidv) * 0.000976562;
            }
            ##################################################
            #If PID is not owned by the user, get RSS values.#
            ##################################################
            else
            {
                my $rss = `ps -p $pid -o rss`;
                if ( $rss =~ /(\d+)/ )
                {
                    $pid[$counter] = $1 * 0.000976562;
                }
            }
        }
        $index[$counter] = $counter2;
        $counter2 += 5;
        $counter++;
        sleep 5;
    }
    ####################################
    #Handle SIGINT and SIGTERM signals.#
    ####################################
    if ( $always_complete == 1 )
    {
        $SIG{'INT'}  = 'signal_handling';
        $SIG{'TERM'} = 'signal_handling';
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

###############################
#Add Private Dirty RSS values.#
###############################
sub private_dirty_sum
{
    my $text = shift;
    my $sum  = 0;
    open my $fh, '<', \$text;
    local $/ = "\n";
    while ( my $line = <$fh> )
    {
        if ( $line =~ /\s+(\d+)\skB/ )
        {
            $sum += $1;
        }
    }
    close $fh;
    return $sum;
}

sub signal_handling
{
    plot();
    exit;
}

#################
#Plot the graph.#
#################
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

    my ( $dataSet1, $dataSet2, $dataSet3, $dataSet4 );
    if ( $pidonly == 0 )
    {
        $dataSet1 = Chart::Gnuplot::DataSet->new(
            xdata  => \@index,
            ydata  => \@values,
            style  => 'linespoints',
            color  => '#FF0000',
            plotbg => '#FFFFFF',
            title  => 'Used memory [-(buffers/cache) + Swap]'
        );
    }

    if ( $cached == 1 )
    {
        $dataSet2 = Chart::Gnuplot::DataSet->new(
            xdata => \@index,
            ydata => \@cache,
            style => 'linespoints',
            color => '#336600',
            title => 'Cached memory'
        );
    }
    if ( $swap == 1 )
    {
        $dataSet3 = Chart::Gnuplot::DataSet->new(
            xdata => \@index,
            ydata => \@swap,
            style => 'linespoints',
            color => '#000033',
            title => 'Swap'
        );
    }
    if ( $pid ne q{} )
    {
        my $title;
        if ( -O "/proc/$pid/smaps" )
        {
            $title = "PID $pid [Private Dirty RSS]";
        }
        else
        {
            $title = "PID $pid [RSS]";
        }
        $dataSet4 = Chart::Gnuplot::DataSet->new(
            xdata => \@index,
            ydata => \@pid,
            style => 'linespoints',
            color => '#551033',
            title => $title
        );
    }
    if ( defined $dataSet2 && defined $dataSet3 && defined $dataSet4 )
    {
        $chart->plot2d( $dataSet1, $dataSet2, $dataSet3, $dataSet4 );
    }
    elsif ( defined $dataSet3 && defined $dataSet4 )
    {
        $chart->plot2d( $dataSet1, $dataSet3, $dataSet4 );
    }
    elsif ( defined $dataSet2 && defined $dataSet4 )
    {
        $chart->plot2d( $dataSet1, $dataSet2, $dataSet4 );
    }
    elsif ( defined $dataSet2 && defined $dataSet3 )
    {
        $chart->plot2d( $dataSet1, $dataSet2, $dataSet3 );
    }
    elsif ( defined $dataSet2 )
    {
        $chart->plot2d( $dataSet1, $dataSet2 );
    }
    elsif ( defined $dataSet3 )
    {
        $chart->plot2d( $dataSet1, $dataSet3 );
    }
    elsif ( defined $dataSet4 && $pidonly == 0 )
    {
        $chart->plot2d( $dataSet1, $dataSet4 );
    }
    elsif ( defined $dataSet4 && $pidonly == 1 )
    {
        $chart->plot2d($dataSet4);
    }
    else
    {
        $chart->plot2d($dataSet1);
    }
    say 'Done.';
    return 0;
}
