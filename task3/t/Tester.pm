package Tester;

use 5.016;
use strict;
use warnings;

use lib 'lib';

use Test::More;

require_ok('Client::client');

sub new {
    my ($class, %params) = @_;

    return bless \%params, $class;
}

sub run_test {
    my $self = shift;

    $self->{before_test}->() if $self->{before_test};

    my $got;

    for (@{ $self->{test} }) {
        $got = $self->{client}->handle_input($_);
    }

    is($got, $self->{expected}->(), $self->{name});

    $self->{after_test}->() if $self->{after_test};
}

1;
