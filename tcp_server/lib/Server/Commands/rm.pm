package Server::Commands::rm;

use 5.16.0;
use strict;
use warnings;

use utf8;
use DDP;

no warnings 'experimental';

sub rm_tree {
    # -------------------------------------------------------------------------
    my ($tree, $h) = @_;

    return '' unless defined $tree;

    my %hh = %{$h};

    for (@$tree) {
        if (ref $_ ne 'HASH') {
            push @{ $hh{files} }, $_;

        }
        else {
            while (my ($dir, $files) = each %$_) {
                push @{ $hh{dirs} }, $dir;

                %hh = (%hh, rm_tree($files, \%hh));
            }
        }
    }

    %hh;
    # -------------------------------------------------------------------------
}

sub ls_item {
    my $path = shift;

    if (-d $path) {
        my @files;
        p $_;

        for (<"$path/.*">) {
            /([^\/]*)$/;

            if($1 ne '.' && $1 ne '..'){
                push @files, ls_item($path . '/' . $1);
            }
        }

        return { $path => \@files };
    }
    else {
        # /([^\/]*)$/;
        # /#([^\/]*)$/;

        return $_;
    }
}

sub filter {
    my $path = shift;

    my @files;

    for (glob("$path")) {
    # for (<"$path">) {
        push @files, ls_item($_);
    }

    \@files;
}

sub remove {
    my ($h, $root) = @_;

    # -------------------------------------------------------------------------
    my $out = '';
    open my $fh, ">>", \$out;
    select $fh;
    # -------------------------------------------------------------------------

    for (@{ $h->{files} }) {
        # say "rm $_";
        unlink $_ or print "Unable to unlink $_: $!";
    }

    for (@{ $h->{dirs} }) {
        # say "rm $_";
        rmdir $_ or print "Unable to rmdir $_: $!";
    }
    # -------------------------------------------------------------------------
    select(STDOUT);

    return $out;
    # -------------------------------------------------------------------------
}

sub rm {
    my $params = shift;

    my $ff;

    unless (exists $params->{args}) {
        $params->{args} = ['.'];
    }

    for (@{ $params->{args} }) {
        my $arg = Path::Resolve->new()->join($params->{root_dir}, $_);
        p $arg;

        if ($arg !~ /^$params->{root_dir}/) {
            return "Error: out of working tree";
        }

        $ff = filter("$_");
    }

    my %h = rm_tree($ff, {});

    remove(\%h, $params->{root_dir});
}

1;
