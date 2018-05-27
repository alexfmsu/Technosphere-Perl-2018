package Server::Commands::shell;

use 5.16.0;
use strict;
use warnings;
use utf8;
use DDP;

no warnings 'experimental';

sub shell {
    my $params = shift;

    my $flags = ' ';
    $flags .= join(' ', @{ $params->{flags} }) if defined $params->{flags};

    my $args = '';
    $args .= join(' ', @{ $params->{args} }) if defined $params->{args};

    my $cmd = $params->{command} . ' ' . $flags . '  ' . $args;

    my @res = qx($cmd 2>&1);

    my $out = join '', @res;

    return $out;
}

1;
