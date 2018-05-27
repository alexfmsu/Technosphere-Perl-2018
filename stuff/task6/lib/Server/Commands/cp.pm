package Server::Commands::cp;

use 5.16.0;
use strict;
use warnings;

use Term::ANSIColor qw(:constants);

sub cp {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $out;

    open my $fh, ">>", \$out;
    select $fh;

    my $cmd = 'cp ';

    $cmd .= join(' ', @{ $params->{args} }) . ' '  if defined $params->{args};
    $cmd .= join(' ', @{ $params->{flags} }) . ' ' if defined $params->{flags};

    if ($verbose) {
        say $cmd;
        say "";
        say BOLD, BLUE, 'cp: ', RESET, "The cp command is makes copies of files and directories.";
        say "";
        say BOLD, BLUE, "Syntax: ", RESET, "cp source destination";
        say "";
    }

    if ($verbose > 1) {
        say BOLD, BLUE, 'Command: ', RESET, $cmd;
        say "";
    }

    say qx($cmd);

    select(STDOUT);

    return $out;
}

1;