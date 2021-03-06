#!/usr/bin/env perl

=head1 NAME

mnimograph_gui.pl

=head1 DESCRIPTION

mnimograph_gui.pl is the GUI version of mnimograph.pl

=head1 DEPENDENCIES

-Perl ( >= 5.14.2 )

-Encode ( >= 2.47 )

-Gtk2 ( >= 1.245 )

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

use Encode;
use Gtk2 -init;

use utf8;

our $VERSION = 1.0;

############################################
#Exit if mnimograph_gui is already running.#
############################################
exit if ( `ps aux | grep -v grep | grep mnimograph_gui | wc -l` > 1 );
$SIG{'INT'} = 'app_quit';

my $window = Gtk2::Window->new('toplevel');
$window->set_title('mnimograph.pl');
$window->set_default_icon_from_file(
    '/opt/mnimograph/images/mnimo_logo_text.png');
$window->signal_connect( destroy => \&app_quit );
$window->set_position('mouse');
$window->set_resizable(0);

my $menu_bar = Gtk2::MenuBar->new();

#######
#File.#
#######
my $menu_item_file = Gtk2::MenuItem->new('_File');
my $menu_file      = Gtk2::Menu->new();

my $menu_file_quit = Gtk2::ImageMenuItem->new_from_stock( 'gtk-quit', undef );
$menu_file_quit->signal_connect( 'activate' => sub { app_quit() } );

$menu_file->append($menu_file_quit);
$menu_item_file->set_submenu($menu_file);
$menu_bar->append($menu_item_file);

#######
#Help.#
#######
my $menu_item_help = Gtk2::MenuItem->new('_Help');
my $menu_help      = Gtk2::Menu->new();

my $menu_help_Perl = Gtk2::MenuItem->new('About Perl');
$menu_help_Perl->signal_connect(
    'activate' => sub { system 'x-www-browser http://www.perl.org/about.html' }
);
$menu_help->append($menu_help_Perl);

my $menu_help_gtk2 = Gtk2::MenuItem->new('About gtk2-perl');
$menu_help_gtk2->signal_connect( 'activate' =>
      sub { system 'x-www-browser http://gtk2-perl.sourceforge.net/' } );
$menu_help->append($menu_help_gtk2);

$menu_help->append( Gtk2::SeparatorMenuItem->new() );

my $menu_help_about = Gtk2::ImageMenuItem->new_from_stock( 'gtk-about', undef );
$menu_help_about->signal_connect( 'activate' => \&about );
$menu_help->append($menu_help_about);

$menu_item_help->set_submenu($menu_help);
$menu_bar->append($menu_item_help);

my $vbox = Gtk2::VBox->new( '0', '10' );
$vbox->add($menu_bar);

my $hbox1 = Gtk2::HBox->new( '0', '5' );

my $new_button = Gtk2::Button->new_from_stock('gtk-new');

my $vseparator1 = Gtk2::VSeparator->new();

my $file_selection = Gtk2::Label->new('Output File Selection:');

my $name_entry = Gtk2::Entry->new;
$name_entry->set_width_chars(50);
$name_entry->set_editable(0);

my $name_button = Gtk2::Button->new_with_label('...');

my $hbox2        = Gtk2::HBox->new( '0', '5' );
my $exists_label = Gtk2::Label->new('File exists:');
my $exists_icon  = Gtk2::Image->new();
my $iconsize     = Gtk2::IconSize->register( 'small-toolbar', 50, 50 );
my $perm_label   = Gtk2::Label->new('Write Permission:');
my $perm_icon    = Gtk2::Image->new();
$exists_icon->set_from_stock( 'gtk-no', $iconsize );
$perm_icon->set_from_stock( 'gtk-no', $iconsize );
my $perm_counter = 0;
$hbox2->add($exists_label);
$hbox2->add($exists_icon);
$hbox2->add($perm_label);
$hbox2->add($perm_icon);

my $hseparator1 = Gtk2::HSeparator->new();

my $hbox3      = Gtk2::HBox->new( '0', '5' );
my $swap_box   = Gtk2::CheckButton->new('Swap');
my $cached_box = Gtk2::CheckButton->new('Cached memory');

my $pidseparator = Gtk2::VSeparator->new();
my $pidlabel     = Gtk2::Label->new('Specific PID:');
my $pidbox       = Gtk2::Entry->new();
my $pid_checkbox = Gtk2::CheckButton->new('PID memory only');

my $pidcounter  = 0;
my $swapcounter = 0;
$swap_box->signal_connect(
    toggled => sub {
        if ( $swapcounter == 0 )
        {
            $swapcounter = 1;
            $pid_checkbox->set_sensitive(0);
            $pidcounter++;
        }
        else
        {
            $swapcounter = 0;
            $pidcounter--;
            if ( $pidcounter == 0 )
            {
                $pid_checkbox->set_sensitive(1);
            }
        }
    }
);

my $cached_counter = 0;
$cached_box->signal_connect(
    toggled => sub {
        if ( $cached_counter == 0 )
        {
            $cached_counter = 1;
            $pid_checkbox->set_sensitive(0);
            $pidcounter++;
        }
        else
        {
            $cached_counter = 0;
            $pidcounter--;
            if ( $pidcounter == 0 )
            {
                $pid_checkbox->set_sensitive(1);
            }
        }
    }
);

my $pidbox_counter = 0;
$pid_checkbox->signal_connect(
    toggled => sub {
        if ( $pidbox_counter == 0 )
        {
            $pidbox_counter = 1;
            $swap_box->set_sensitive(0);
            $cached_box->set_sensitive(0);
        }
        else
        {
            $pidbox_counter = 0;
            $swap_box->set_sensitive(1);
            $cached_box->set_sensitive(1);
        }
    }
);

$hbox3->add($swap_box);
$hbox3->add($cached_box);
$hbox3->add($pidseparator);
$hbox3->add($pidlabel);
$hbox3->add($pidbox);
$hbox3->add($pid_checkbox);

my $output_file;
my $button1 = Gtk2::ToggleButton->new_with_label('Start!');
if ( defined $ARGV[0] )
{
    $output_file = $ARGV[0];
    $output_file = decode 'UTF8', $output_file;
    if ( $output_file !~ /[.]png$/ )
    {
        $output_file .= '.png';
    }
    $name_entry->append_text($output_file);
    if ( -e $output_file )
    {
        $exists_icon->set_from_stock( 'gtk-yes', $iconsize );
        if ( -w $output_file )
        {
            $perm_icon->set_from_stock( 'gtk-yes', $iconsize );
            $button1->set_sensitive(1);
        }
        else
        {
            $perm_icon->set_from_stock( 'gtk-no', $iconsize );
            $button1->set_sensitive(0);
        }
    }
    else
    {
        $exists_icon->set_from_stock( 'gtk-no', $iconsize );
        my $test_creatable = 0;
        open my $fh, '>', $output_file or $test_creatable++;
        if ( $test_creatable == 0 )
        {
            close $fh;
            unlink $output_file;
            $perm_icon->set_from_stock( 'gtk-yes', $iconsize );
            $button1->set_sensitive(1);
        }
        elsif ( $test_creatable == 1 )
        {
            $perm_icon->set_from_stock( 'gtk-no', $iconsize );
            $button1->set_sensitive(0);
        }
    }
}

$name_button->signal_connect( clicked => \&select_file );

my $hbox4 = Gtk2::HBox->new( '0', '20' );

my $image = Gtk2::Image->new_from_file('/opt/mnimograph/images/default.png');

$new_button->signal_connect(
    clicked => sub {
        $name_entry->set_text(q{});
        $button1->set_sensitive(0);
        $exists_icon->set_from_stock( 'gtk-no', $iconsize );
        $perm_icon->set_from_stock( 'gtk-no', $iconsize );
        $image->set_from_file('/opt/mnimograph/images/default.png');
    }
);

$hbox1->add($new_button);
$hbox1->add($vseparator1);
$hbox1->add($file_selection);
$hbox1->add($name_entry);
$hbox1->add($name_button);

$vbox->add($hbox1);
$vbox->add($hbox2);
my $hseparator2 = Gtk2::HSeparator->new();
$vbox->add($hseparator2);
$vbox->add($hbox3);

unless ( defined $output_file )
{
    $button1->set_sensitive(0);
}
my $pid;

my $button2 = Gtk2::Button->new_from_stock('gtk-stop');
$button2->set_sensitive(0);

my $button_counter = 0;
###############
#Start button.#
###############
$button1->signal_connect(
    toggled => sub {
        if ( $button_counter == 0 )
        {
            #######################################################
            #Error if PID is not defined, while pidonly is active.#
            #######################################################
            my $pidonly = $pid_checkbox->get_active;
            if ( $pidbox->get_text eq q{} && $pidonly == 1 )
            {
                my $dialog =
                  Gtk2::MessageDialog->new( $window, 'destroy-with-parent',
                    'error', 'close', "PID was not defined!" );
                $dialog->signal_connect(
                    response => sub {
                        my $self = shift;
                        $self->destroy;
                    }
                );
                $pid_checkbox->set_active(0);
                $button1->set_sensitive(1);
                $dialog->show_all;
            }
            else
            {

                $button_counter = 1;
                $button2->set_sensitive(1);
                $button1->set_sensitive(0);
                $new_button->set_sensitive(0);
                $name_button->set_sensitive(0);
                $swap_box->set_sensitive(0);
                $cached_box->set_sensitive(0);
                $pid_checkbox->set_sensitive(0);
                $image->set_from_file('/opt/mnimograph/images/loading.gif');

                unlink $output_file;
                my $swap_param   = $swap_box->get_active;
                my $cached_param = $cached_box->get_active;
                my $parameters   = q{};
                if ( $swap_param == 1 )
                {
                    $parameters .= ' -swap';
                }
                if ( $cached_param == 1 )
                {
                    $parameters .= ' -cached';
                }
                if ( $pidbox->get_text =~ /(\d+)/ )
                {
                    $parameters .= " -pid=$1";
                }
                if ( $pidonly == 1 )
                {
                    $parameters .= ' -pidonly';
                }
                $pid = fork;

                if ( !$pid )
                {
                    exec
"/usr/local/bin/mnimograph.pl -alc $parameters $output_file&";
                }
                ######################
                #Launch mnimograph.pl#
                ######################
                $pid =
`ps aux | grep -v grep | grep -v gui | grep 'mnimograph.pl -alc' | awk ' {print \$2; exit} '`;
            }
        }
        else
        {
            $button_counter = 0;
        }
    }
);
$hbox4->add($button1);
##############
#Stop button.#
##############
$button2->signal_connect(
    clicked => sub {
        do
        {
            kill 2, $pid;
        } while ( `ps aux | grep -v grep | grep $pid` ne q{} );
        $button1->set_sensitive(1);
        $button1->set_active(0);
        $button2->set_sensitive(0);
        $new_button->set_sensitive(1);
        $name_button->set_sensitive(1);
        $swap_box->set_sensitive(1);
        $cached_box->set_sensitive(1);
        $pid_checkbox->set_sensitive(1);
        $exists_icon->set_from_stock( 'gtk-yes', $iconsize );
        sleep 1;

        if ( -z $output_file )
        {
            $image->set_from_file('/opt/mnimograph/images/error.png');
        }
        else
        {
            my $pixbuf =
              Gtk2::Gdk::Pixbuf->new_from_file_at_scale( $output_file, 650,
                650, 1 );
            $image->set_from_pixbuf($pixbuf);
        }
    }
);

$hbox4->add($button2);
$vbox->add($hbox4);

my $separator = Gtk2::HSeparator->new();
$vbox->add($separator);

$vbox->add($image);

$window->add($vbox);

$window->show_all;
Gtk2->main;

####################
#On program exit...#
####################
sub app_quit
{
    if ( defined $pid )
    {
        kill 1, $pid;
    }
    Gtk2->main_quit();
    exit;
}

#####################
#The about window...#
#####################
sub about
{
    my $window = Gtk2::Window->new('toplevel');
    $window->set_default_icon_from_file(
        '/opt/mnimograph/images/mnimo_logo_text.png');
    $window->set_title('About mnimograph.pl');
    $window->signal_connect( destroy => sub { Gtk2->main_quit() } );
    $window->set_resizable(0);

    my $logo =
      Gtk2::Image->new_from_file('/opt/mnimograph/images/mnimo_logo_text.png');
    my $top_info = <<'ABOUT';
		      <b>mnimograph.pl</b>, v. 1.0
				   <a href="https://github.com/dgkontopoulos/mnimograph.pl">Homepage</a>
(C) 2012 <a href="mailto:dgkontopoulos@member.fsf.org?Subject=mnimograph.pl">Dimitrios - Georgios Kontopoulos</a>
ABOUT
    chomp $top_info;
    my $second_info = <<'ABOUT';
<span size="small">Both <b>mnimograph.pl</b> and its GUI (<b>mnimograph_gui.pl</b>)
are written in <a href="http://www.perl.org/">Perl</a>/<a href="http://gtk2-perl.sourceforge.net/">GTK2</a>.</span>
ABOUT
    chomp $second_info;
    my $license = <<'ABOUT';
<span size="small"><b><u>License:</u></b>
<i>This program is free software; you can redistribute it
and/or modify it under the terms of the <a href="http://www.gnu.org/licenses/gpl.html">GNU General
Public License, as published by the Free Software
Foundation; either version 3 of the License, or (at your
option) any later version</a>.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.</i></span>
ABOUT
    chomp $license;
    my $vbox = Gtk2::VBox->new( '0', '10' );
    my $label1 = Gtk2::Label->new();
    $label1->set_markup($top_info);
    my $separator1 = Gtk2::HSeparator->new;
    my $label2     = Gtk2::Label->new();
    $label2->set_markup($second_info);
    my $separator2 = Gtk2::HSeparator->new;

    my $license_button = Gtk2::ToggleButton->new_with_label('License');

    my $license_counter = 0;
    $license_button->signal_connect(
        toggled => sub {
            if ( $license_counter == 0 )
            {
                $license_counter = 1;
                $label2->set_markup($license);
                $window->show_all;
            }
            else
            {
                $license_counter = 0;
                $license_button->set_active(0);
                $label2->set_markup($second_info);
                $window->show_all;
            }
        }
    );

    $vbox->add($logo);
    $vbox->add($label1);
    $vbox->add($separator1);
    $vbox->add($label2);
    $vbox->add($separator2);
    my $hbox = Gtk2::HBox->new( 0, 20 );
    $hbox->add($license_button);
    $vbox->add($hbox);
    $window->set_border_width(15);
    $window->set_position('mouse');
    $window->add($vbox);

    $window->show_all;
    Gtk2->main;
    return 0;
}

#####################
#Select output file.#
#####################
sub select_file
{
    my $filter = Gtk2::FileFilter->new();
    $filter->set_name('PNG Image (*.png)');
    $filter->add_pattern('.png');
    $filter->add_pattern('.PNG');
    $filter->add_mime_type('image/png');

    my $filechooser =
      Gtk2::FileChooserDialog->new( 'Save File', $window, 'save', 'gtk-cancel',
        'cancel', 'gtk-save', 'accept' );
    $filechooser->set_do_overwrite_confirmation('TRUE');
    $filechooser->add_filter($filter);
    if ( defined $output_file )
    {
        $filechooser->set_filename($output_file);
    }

    my $res = $filechooser->run;
    if ( $res eq 'accept-filename' or $res eq 'accept' )
    {
        $output_file = $filechooser->get_filename;
        if ( utf8::is_utf8($output_file) eq 'TRUE' )
        {
            $output_file = decode 'UTF8', $output_file;
        }
        if ( $output_file !~ /[.]png$/ )
        {
            $output_file .= '.png';
        }
        $name_entry->set_text($output_file);
        if ( -e $output_file )
        {
            $exists_icon->set_from_stock( 'gtk-yes', $iconsize );
            if ( -w $output_file )
            {
                $perm_icon->set_from_stock( 'gtk-yes', $iconsize );
                $button1->set_sensitive(1);
            }
            else
            {
                $perm_icon->set_from_stock( 'gtk-no', $iconsize );
            }

        }
        else
        {
            $exists_icon->set_from_stock( 'gtk-no', $iconsize );
            my $test_creatable = 0;
            open my $fh, '>', $output_file or $test_creatable++;
            if ( $test_creatable == 0 )
            {
                close $fh;
                unlink $output_file;
                $perm_icon->set_from_stock( 'gtk-yes', $iconsize );
                $button1->set_sensitive(1);
            }
            elsif ( $test_creatable == 1 )
            {
                $perm_icon->set_from_stock( 'gtk-no', $iconsize );
            }
        }
    }
    $filechooser->destroy;
    return $output_file, $name_entry;
}
