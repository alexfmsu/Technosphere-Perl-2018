package Server::Commands::mkdir;

use 5.16.0;
use strict;
use warnings;
use utf8;
use DDP;

use Term::ANSIColor qw(:constants);

no warnings 'experimental';

sub verbose {
    my ($verbose, $cmd) = @_;

    if ($verbose) {
        say $cmd;
        say "";
        say BOLD, BLUE, 'mkdir: ', RESET, 'The ls command lists the contents of, and optional information about, directories and files.';
        say "";
        say "\t  With no options, ls lists the files contained in the current directory, sorting them alphabetically.";
        say "";
        say "\t  -l: Use a long listing format";
        say "\t  -A: Do not list implied \".\" and \"..\"";
        say "";
    }

    if ($verbose > 1) {
        say BOLD, BLUE, 'Command: ', RESET, $cmd;
        say "";
    }
}

sub mkdir {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $out;

    open my $fh, ">>", \$out;
    select $fh;

    my $args = join(' ', @{ $params->{args} }) if @{ $params->{args} };

    $args =~ /^([^{]*)(.*)$/;

    $args = $1;

    if ($2) {
        my @obj = parse_object($2);

        my $path = [];

        for (@obj) {
            push @$path, "$args$_", for @$_;
        }

        $args = join ' ', @$path;
    }

    my $cmd = $params->{command} . ' ';
    $cmd .= $args . ' ';
    $cmd .= join(' ', @{ $params->{flags} }) . ' ' if defined $params->{flags};

    chop($cmd);

    verbose($verbose, $cmd);

    say qx($cmd);

    select(STDOUT);

    return $out;
}

1;
