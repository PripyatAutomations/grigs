# Here we deal with our memory add/edit window
package rustyrigs_memory;
use strict;
use warnings;
use Carp;
use Glib qw(TRUE FALSE);
use Data::Dumper;

my $mem_file;
my $w_mem_edit;
my $mem_edit_box   = Gtk3::Box->new( 'vertical', 5 );
my $mem_edit_open  = 0;
my $mem_edit_accel = Gtk3::AccelGroup->new();

# new() sets these up
my $cfg;
my $w_main;

sub save {
    ( my $class, my $channel ) = @_;
    $class->close(TRUE);
}

sub show {
    ( my $class ) = @_;

    if ($mem_edit_open) {

        #      $w_mem_edit->present();
        #      $w_mem_edit->grab_focus();
        #      print "reusing existing memory editor window\n";
        #      return TRUE;
        $w_mem_edit->destroy();
    }

    my $button_box = Gtk3::Box->new( 'vertical', 5 );
    $mem_edit_open = 1;
    $w_mem_edit    = Gtk3::Window->new(
        'toplevel',
        decorated           => TRUE,
        destroy_with_parent => TRUE,
        position            => "center"
    );
    $w_mem_edit->set_transient_for($w_main);
    $w_mem_edit->set_keep_above(1);
    $w_mem_edit->set_modal(1);
    $w_mem_edit->set_resizable(0);
    $w_mem_edit->set_title("Memory Editor");

    # set the icon to show it's a settings window
    main::set_settings_icon($w_mem_edit);

    # Place the window and size it
    $w_mem_edit->set_default_size( $cfg->{'win_mem_edit_width'},
        $cfg->{'win_mem_edit_height'} );
    $w_mem_edit->move( $cfg->{'win_mem_edit_x'}, $cfg->{'win_mem_edit_y'} );

    my $save_button = Gtk3::Button->new_with_mnemonic('_Save Memory');
    $save_button->signal_connect( clicked => sub { $class->save(); } );
    $save_button->set_tooltip_text("Save memory");
    my $quit_button = Gtk3::Button->new_with_mnemonic('_Quit');
    $quit_button->signal_connect( clicked => sub { $class->close(FALSE); } );
    $quit_button->set_tooltip_text("Close the memory editor");

    $w_mem_edit->add_accel_group($mem_edit_accel);

    # add widgets into the button box at bottom
    $button_box->pack_start( $save_button, FALSE, FALSE, 0 );
    $button_box->pack_start( $quit_button, FALSE, FALSE, 0 );

    # add it to the END of the window
    $mem_edit_box->pack_end( $button_box, FALSE, FALSE, 0 );
    $w_mem_edit->add($mem_edit_box);

    #########
    # Signal handlers
    #########
    # Handle moves and resizes
    $w_mem_edit->signal_connect(
        'configure-event' => sub {
            my ( $widget, $event ) = @_;
            my ( $width, $height ) = $widget->get_size();
            my ( $x, $y )          = $widget->get_position();
            $cfg->{'win_mem_edit_x'}      = $x;
            $cfg->{'win_mem_edit_y'}      = $y;
            $cfg->{'win_mem_edit_height'} = $height;
            $cfg->{'win_mem_edit_width'}  = $width;
            return FALSE;
        }
    );

    # Handle close button
    $w_mem_edit->signal_connect(
        'delete-event' => sub {
            $class->close(FALSE);
            return TRUE;
        }
    );

    print "*** 1 ***\n";
    $w_mem_edit->show_all();
}

sub close {
    ( my $class, my $quiet ) = @_;

    if ( !defined $quiet ) {
        $quiet = FALSE;
    }

    #   print "hmmm.. quiet: $quiet, meo: $mem_edit_open // wme: $w_mem_edit\n";

    if ( !$mem_edit_open || !defined $w_mem_edit ) {
        print "mem_edit not open, bailing! caller: " . ( caller(1) )[3] . "\n";
        return;
    }

    my $response = 'yes';
    my $dialog;

    # skip this if quiet is passed
    if ( !defined($quiet) || !$quiet ) {
        my $s_modal = $w_mem_edit->get_modal();
        $w_mem_edit->set_keep_above(0);
        $w_mem_edit->set_modal(0);

        $dialog =
          Gtk3::MessageDialog->new( $w_mem_edit, 'destroy-with-parent',
            'warning', 'yes_no',
            "Close settings window? Unsaved changes will be lost." );
        $dialog->set_title('Confirm close memory editor?');
        $dialog->set_default_response('no');
        $dialog->set_transient_for($w_mem_edit);
        $dialog->set_modal(1);
        $dialog->set_keep_above(1);
        $dialog->present();
        $dialog->grab_focus();
        $response = $dialog->run();
    }

    if ( $response eq 'yes' ) {
        $mem_edit_open = 0;
        $w_mem_edit->destroy();
        undef $w_mem_edit;

        if ( defined($dialog) ) {
            $dialog->destroy();
        }
    }
    else {
        $w_mem_edit->set_keep_above(1);
        $w_mem_edit->set_modal(1);
        $w_mem_edit->present();
        $w_mem_edit->grab_focus();

        if ( defined($dialog) ) {
            $dialog->destroy();
        }
    }
}

sub load_defaults {
    ( my $class, my $defaults ) = @_;
}

sub load_from_yaml {
    ( my $class, my $file ) = @_;
}

sub new {
    ( my $class, $cfg, $w_main, $mem_file ) = @_;

    my $self = {
        file           => $mem_file,
        close          => \&close,
        load_defaults  => \&load_defaults,
        load_from_yaml => \&load_from_yaml,
        save           => \&save,
        show           => \&show
    };

    bless $self, $class;
    return $self;
}

sub DESTROY {
    ( my $class ) = @_;
}

1;
