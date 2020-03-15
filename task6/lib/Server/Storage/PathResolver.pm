package Server::Storage::PathResolver;

use 5.16.0;
use strict;
use warnings;
use DDP;

sub resolve {
    my ($params, $args) = @_;

    if($args =~ /^\s*$/){
        $args = '.';
    }
    # $args ||= '.';

    my $fh_dir;

    my $print_dir = sub {
        my $args = shift;

        my @DIRS;

        my @paths = split /\//, $args;

        my $p = $params->{root_dir};

        my $depth;

        push @DIRS, '.' unless @paths;
        p $args;
        p @DIRS;
        p $p;
        for my $depth (0 .. $#paths) {
            if (-d $paths[$depth]) {
                $p = Path::Resolve->new()->join($p, $paths[$depth]);

                push @DIRS, $paths[$depth];

                if (-d $p) {
                    chdir($p);

                    opendir($fh_dir, $p) or die "can't opendir $p: $!";

                    my @f = readdir($fh_dir);

                    if ($depth < $#paths) {
                        $paths[ $depth + 1 ] =~ s/\*/[^\0]*/g;
                        $paths[ $depth + 1 ] =~ s/\?/[^\0]/g;

                        @f = grep { /^$paths[$depth+1]$/ && $_ !~ /^\./ } @f;

                        my @D;

                        for my $d (@DIRS) {
                            for my $f (@f) {
                                push @D, $d . '/' . $f;
                            }
                        }
                        p @D;
                        @DIRS = @D;
                    }
                }
            }
        }

        return @DIRS;
    };

    my @f = $print_dir->($args);
    # my @f = $print_dir->($args);

    my @files;

    @f = map { Path::Resolve->new()->join($params->{root_dir}, $_) } sort @f;
    # p @f;
    
    my @_files = grep { -f $_ } @f;
    my @_dirs  = grep { -d $_ } @f;

    for (@_files) {
        /([^\/]+)$/;

        push @files, "$1";
    }

    p @_files;
    p @_dirs;

    my %DI = ();
    
    for (@_dirs) {
        chdir($_);
        $DI{$_} = [];

        /([^\/]+)$/;

        if ($1 !~ /^\./) {
            push @files, '', "$1:";
            # push @{$DI{$_}}, $1;
        }

        opendir(my $fh_dir, $_) or die "can't opendir $_: $!";

        my @ff = readdir($fh_dir);

        push @files, sort { fc($a) cmp fc($b) } grep { $_ !~ /^\./ } @ff;
    
            push @{$DI{$_}}, sort { fc($a) cmp fc($b) } grep { $_ !~ /^\./ } @ff;
    }

    p %DI;
    # p "123";

    # p @files;

    chdir($params->{root_dir});

    # return @files;
    \%DI;
}

1;
