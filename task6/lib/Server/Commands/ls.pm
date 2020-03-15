package Server::Commands::ls;

use 5.16.0;
use strict;
use warnings;

use Term::ANSIColor qw(:constants);

sub ls {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $out = '';

    open my $fh, ">>", \$out;
    select $fh;

    my $args = '';

    if ($params->{args}) {
        $args .= join(' ', @{ $params->{args} });
    }

    if ($args) {
        $args =~ /^([^{]+)(.*)$/;

        $args = $1;

        if ($2) {
            my @obj = parse_object($2);

            my $path = [];

            for (@obj) {
                push @$path, "$args$_", for @$_;
            }

            $args = join ' ', @$path;
        }
    }

    my $cmd = $params->{command} . ' ';

    $cmd .= $args . ' ' if $args;
    $cmd .= join(' ', @{ $params->{flags} }) . ' ' if defined $params->{flags};

    chop($cmd);

    if ($verbose) {
    	my $cmd = shift;

    	verbose($cmd);
    }

    if ($verbose > 1) {
        say BOLD, BLUE, 'Command: ', RESET, $cmd;
        say "";
    }

    my $files = Server::Storage::PathResolver::resolve($params, $args);
    # use DDP;
    # p $files;
    # say 12;

    while (my ($k, $v) = each %$files) {
    	say join "\n", @$v;
        # say join "\n", keys %$files;
    }
    select(STDOUT);

    return $out;
}

sub verbose {
	my $cmd = shift;

    say $cmd;
    say "";
    say BOLD, BLUE, 'ls -l -A: ', RESET, 'The ls command lists the contents of, and optional information about, directories and files.';
    say "";
    say "\t  With no options, ls lists the files contained in the current directory, sorting them alphabetically.";
    say "";
    say "\t  -l: Use a long listing format";
    say "\t  -A: Do not list implied \".\" and \"..\"";
    say "";
}

1;
