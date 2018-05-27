package Server::Commands::ls;

use 5.16.0;
use strict;
use warnings;

use utf8;
use DDP;

use Term::ANSIColor qw(:constants);

no warnings 'experimental';

sub print_tree {
    # -------------------------------------------------------------------------
    my ($tree) = @_;

    return '' unless defined $tree;
    # -------------------------------------------------------------------------
    my $print_dir = (@$tree > 1);
    # -------------------------------------------------------------------------
    my @files;

    for (@$tree) {
        unless (ref $_ eq 'HASH') {
            push @files, $_;
        }
    }

    if (@files) {
        @files = sort { $a cmp $b } @files;
    }
    # -------------------------------------------------------------------------
    my @dirs;

    local $, = "\n";

    for (@$tree) {
        my $out = '';
        open my $fh, ">>", \$out;
        select $fh;

        if (ref $_ eq 'HASH') {
            while (my ($dir, $files) = each %$_) {
                if (@$files) {
                    say "$dir:" if $print_dir;

                    @$files = sort { $a cmp $b } @$files;

                    print @$files;
                }
                else {
                    print "$dir:" if $print_dir;
                }
            }
        }

        push @dirs, $out if $out;

        select(STDOUT);
    }

    my $f = join "\n",   @files;
    my $d = join "\n\n", @dirs;

    if ($f && $d) {
        $d = $f . "\n\n" . $d;
    }
    elsif (!$d) {
        $d = $f;
    }

    return $d . "\n";
}

sub ls_item {
    my ($path, $flags) = @_;

    if (-d $path) {
        my @files;

        my @glob = glob("$path/*");

        if ('-a' ~~ @$flags) {
            push @glob, glob("$path/.*");
        }

        for (@glob) {
            /([^\/]*)$/;

            # if ($1 ne '.' && $1 ne '..') {
            push @files, $1;
            # }
        }

        @files = sort { $a cmp $b } @files;

        return { $path => \@files };
    }
    else {
        return $_;
    }
}

sub filter {
    my ($path, $flags) = @_;
    # p $flags;

    my @files;

    my @glob;

    if ($path eq '.') {
        @glob = glob(".");
    }
    else {
        @glob = glob("$path");
    }

    for (@glob) {
        push @files, ls_item($_, $flags);
    }

    \@files;
}

sub verbose{
    my ($verbose, $cmd) = @_;

    if ($verbose) {
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

    if ($verbose > 1) {
        say BOLD, BLUE, 'Command: ', RESET, $cmd;
        say "";
    }
}

sub ls {
    my $params = shift;

    p $params;

    my $ff;

    unless (exists $params->{args}) {
        $params->{args} = ['.'];
    }

    for (@{ $params->{args} }) {
        my $arg = Path::Resolve->new()->join($params->{root_dir}, $_);

        if ($arg !~ /^$params->{root_dir}/) {
            return "Error: out of working tree";
        }

        $ff = filter("$_", $params->{flags});
    }

    print_tree($ff);

    # my $verbose = $params->{verbose};
    # my $cmd = $params->{command};

    # verbose($verbose, $cmd);
}

1;
