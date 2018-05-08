package Client::Cmd;

use 5.16.0;
use strict;
use warnings;

use Client::Commands;

my %handler = (
    ls    => \&Client::Commands::ls,
    mkdir => \&Client::Commands::mkdir,
    cp    => \&Client::Commands::cp,
    mv    => \&Client::Commands::mv,
    rm    => \&Client::Commands::rm,
    shell => \&Client::Commands::shell
);

sub new {
    my ($self, %params) = @_;

    return bless \%params, $self;
}

sub call {
    my $self = shift;

    if ($handler{ $self->{command} }) {
        $handler{ $self->{command} }->($self);
    } else {
        return "Error: unknown command\n";
    }
}

sub shell_call {
    my $self = shift;

    $handler{shell}->($self);
}

1;
