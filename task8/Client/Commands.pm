package Client::Commands;

use 5.16.0;
use strict;
use warnings;
use DDP;

use Term::ANSIColor qw(:constants);

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

    open my $fh, ">", \$out;
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

    say $cmd;
    say "";

    if ($verbose) {
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

    close($fh);

    select(STDOUT);

    return $out;
}

sub ls {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $out;

    open my $fh, ">", \$out;
    select $fh;

    my $args = '';
    $args .= join(' ', @{ $params->{args} }) if $params->{args};

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
p $cmd;

    say $cmd;
    say "";

    if ($verbose) {
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

    say qx($cmd);

    close($fh);

    select(STDOUT);

    return $out;
}

sub cp {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $out;

    open my $fh, ">", \$out;
    select $fh;

    my $cmd = 'cp ';

    $cmd .= join(' ', @{ $params->{args} }) . ' '  if defined $params->{args};
    $cmd .= join(' ', @{ $params->{flags} }) . ' ' if defined $params->{flags};

    say $cmd;
    say "";

    if ($verbose) {
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

    close($fh);

    select(STDOUT);

    return $out;
}

sub mv {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $out;

    open my $fh, ">", \$out;
    select $fh;

    my $cmd = 'mv ';

    $cmd .= join(' ', @{ $params->{args} }) . ' ' if defined $params->{args};
    $cmd .= join(' ', @{ $params->{keys} }) . ' ' if defined $params->{keys};

    say $cmd;
    say "";

    if ($verbose) {
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

    close($fh);

    select(STDOUT);

    return $out;
}

sub rm {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $out;

    open my $fh, ">", \$out;
    select $fh;

    my $cmd = 'rm ';

    $cmd .= join(' ', @{ $params->{flags} }) . ' ' if defined $params->{flags};
    $cmd .= join(' ', @{ $params->{args} }) . ' '  if defined $params->{args};

    say $cmd;
    say "";

    if ($verbose) {
        say BOLD, BLUE, 'rm: ', RESET, "The rm (\"remove\") command is used to delete files.";
        say "";
        say BOLD, BLUE, "Syntax: ", RESET, "rm source";
        say "";
    }

    if ($verbose > 1) {
        say BOLD, BLUE, 'Command: ', RESET, $cmd;
        say "";
    }

    unless (unlink $params->{args}->[0]) {
        return $cmd . ": " . $! . "\n";
    }

    close($fh);

    select(STDOUT);

    return $out;
}

1;
