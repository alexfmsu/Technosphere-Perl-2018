package Client::Command;

use 5.016;
use strict;
use warnings;
use DDP;
use Server::Storage::PathResolver;

use Term::ANSIColor qw(:constants);

our %handler = (
    ls    => \&Client::Command::ls,
    mkdir => \&Client::Command::mkdir,
    cd    => \&Client::Command::cd,
    cp    => \&Client::Command::cp,
    mv    => \&Client::Command::mv,
    rm    => \&Client::Command::rm,
    shell => \&Client::Command::shell
);

sub new {
    my ($self, %params) = @_;

    $params{verbose} ||= 0;

    return bless \%params, $self;
}

sub call {
    my $self = shift;

    if ($handler{ $self->{command} }) {
        $handler{ $self->{command} }->($self);
    }
    else {
        return "Error: unknown command\n";
    }
}

sub shell_call {
    my $self = shift;

    $handler{shell}->($self);
}

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

sub parse_object {
    my $str = shift;

    my @obj;

    my $a = \@obj;

    my @prev;

    my $re;

    $re = qr{
        \{
        (?{push @prev, $a; push @$a, []; $a=$a->[-1]})

        (?:
            (?<word>
                    [^\{,\}]++
            )
                
            (?{ push @$a, $+{word};})
            |
            (??{$re})
        )
        (?:
            (?<w2>
                ,
                (?:
                    (?<word2>
                        [^\{,\}]++
                    )
                    (?{ push @$a, $+{word2};})
                    |
                    (??{$re})
                )
                # (?>[,\}])
                    
            )
        )*
        
        (?{$a = pop @prev;})
        \}
        
    }x;

    return @obj if ($str =~ $re);

    die "Not match";
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

    say qx($cmd);

    select(STDOUT);

    return $out;
}

sub cd {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $out;

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

    my @files = Server::Storage::PathResolver::resolve($params, $args);

    $args =~ s/\*/[^\0]*/g;
    $args =~ s/\?/[^\0]/g;
    $args =~ /([^\/]+)$/;

    my @paths = grep { /^$1$/ } @files;
    p @paths;    
    
    if(scalar @paths > 1){
        say "ERR";
        say "Слишком много аргументов";
        select(STDOUT);
        p $out;
        return $out;
    }

    p @paths;
    chdir($paths[0]);

    # say join "\n", @files;

    select(STDOUT);

    return $out;
}

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

    my @files = Server::Storage::PathResolver::resolve($params, $args);
# p @files;
# p $out;

    if(@files){
    say join "\n", @files;
}
    select(STDOUT);

    return $out;
}

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

sub mv {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $out;

    open my $fh, ">>", \$out;
    select $fh;

    my $cmd = 'mv ';

    $cmd .= join(' ', @{ $params->{args} }) . ' ' if defined $params->{args};
    $cmd .= join(' ', @{ $params->{keys} }) . ' ' if defined $params->{keys};

    if ($verbose) {
        say $cmd;
        say "";
        say BOLD, BLUE, 'mv: ', RESET, "The mv command moves, or renames, files and directories on your filesystem.";
        say "";
        say BOLD, BLUE, "Syntax: ", RESET, "mv source destination";
        say "";
    }

    if ($verbose > 1) {
        say BOLD, BLUE, 'Command: ', RESET, $cmd;
        say "";
    }

    rename($params->{args}->[0], $params->{args}->[1]) or say $cmd . ": No such file";

    select(STDOUT);

    return $out;
}

sub resolve2{
    my ($params, $args) = @_;

    my $fh_dir;

    my $print_dir = sub {
        my $args = shift;

        my @DIRS;

        my @paths = split /\//, $args;

        my $p = $params->{root_dir};

        my $depth;

        push @DIRS, '.' unless @paths;

        for my $depth(0..$#paths) {
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

                        @DIRS = @D;
                    }
                }
            }
        }

        return @DIRS;
    };

    my @f = $print_dir->($args);

    my @files;

    @f = map { Path::Resolve->new()->join($params->{root_dir}, $_) } sort @f;
    p @f;
    my @_files = grep { -f $_ } @f;
    my @_dirs = grep { -d $_ } @f;
    
    for (@_files) {
        # /([^\/]+)$/;

        push @files, "$_";
    }

    for (@_dirs) {
        chdir($_);

        /([^\/]+)$/;

        # if ($1 !~ /^\./) {
            push @files, '', "$1:";
        # }
        opendir(my $fh_dir, $_) or die "can't opendir $_: $!";
        
        my @ff = readdir($fh_dir);

        push @files, sort { fc($a) cmp fc($b) } grep { $_ !~ /^\./ } @ff;
    }

    return @files;
}

sub rm {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $out;

    open my $fh, ">>", \$out;
    select $fh;

    my $cmd = 'rm ';

    $cmd .= join(' ', @{ $params->{flags} }) . ' ' if defined $params->{flags};
    $cmd .= join(' ', @{ $params->{args} }) . ' '  if defined $params->{args};

    my @files = resolve2($params, @{ $params->{args} });
    p @files;

    if ($verbose) {
        say $cmd;
        say "";
        say BOLD, BLUE, 'rm: ', RESET, "The rm (\"remove\") command is used to delete files.";
        say "";
        say BOLD, BLUE, "Syntax: ", RESET, "rm source";
        say "";
    }

    if ($verbose > 1) {
        say BOLD, BLUE, 'Command: ', RESET, $cmd;
        say "";
    }

    for(@files){
        unlink;
    }

    # unless (unlink $params->{args}->[0]) {
    #     return $cmd . ": " . $! . "\n";
    # }


    select(STDOUT);

    return $out;
}

1;
