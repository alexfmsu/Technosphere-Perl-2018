package Client::Config::History;

use 5.16.0;
use strict;
use warnings;

my @hist_to_add;

sub HISTORY_FILENAME {
    ".history";
}

sub new {
    my ($self, %params) = @_;

    $params{filename} ||= HISTORY_FILENAME;

    $params{history_path} = $params{config}->{config_dir} . '/' . $params{filename};

    return bless \%params, $self;
}

sub load {
    my ($self, $term) = @_;

    my $fh = $self->{fh};

    if (-e $self->{history_path}) {
        open($fh, '<', $self->{history_path}) or die $!;

        my @history_commands = grep { s/\n$// } <$fh>;

        close($fh);

        $term->SetHistory(@history_commands) if @history_commands;
    }
    else {
        `touch $self->{history_path}`;
    }
}

sub push_history {
    my $self = shift;

    my $fh = $self->{fh};

    open($fh, '>>', $self->{history_path}) or die $!;
    print $fh join "\n", @hist_to_add, "";
    close $fh;
}

sub add_to_history {
    my ($self, $text) = @_;

    push @hist_to_add, $text;
}

1;
