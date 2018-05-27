package Tester;

use 5.16.0;
use strict;
use warnings;

use lib 'lib';

use Server::Server;
use Client::Client;

use Test::More;

sub new{
    my ($class, %params) = @_;

    return bless \%params, $class;
}

sub run_test {
    my $self = shift;

    $self->{before_test}->() if $self->{before_test};

    my $res;

    for (@{ $self->{test} }) {
        $res = $self->{client}->handle_input($_);
    }
    
    is($res->{result}, $self->{expected}->(), 'true');
    # system("ls *");

    $self->{after_test}->() if $self->{after_test};
}

1;
