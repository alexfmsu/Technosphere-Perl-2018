package Client::Commands;

use 5.16.0;
use strict;
use warnings;

use Term::ANSIColor qw(:constants);

my %handler = (
    ls    => \&Client::Commands::ls,
    cp    => \&Client::Commands::cp,
    mv    => \&Client::Commands::mv,
    rm    => \&Client::Commands::rm,
    shell => \&Client::Commands::shell
);

sub new {
    my ($self, %params) = @_;

    return bless \%params, $self;
}

sub call {
    my $self = shift;

    $handler{ $self->{command} }->($self);
}

sub shell {
    my $params = shift;

    my $cmd = $params->{args}->[0];

    my @res = qx($cmd 2>&1);

    my $out = join '', @res;

    return $out;
}

sub ls {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $cmd = 'ls ';

    $cmd .= join(' ', @{ $params->{args} }) . ' ' if defined $params->{args};
    $cmd .= join(' ', @{ $params->{keys} }) . ' ' if defined $params->{keys};

    if ($verbose) {
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

    return qx($cmd);
}

sub cp {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $cmd = 'cp ';

    $cmd .= join(' ', @{ $params->{args} }) . ' ' if defined $params->{args};
    $cmd .= join(' ', @{ $params->{keys} }) . ' ' if defined $params->{keys};

    if ($verbose) {
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

    return qx($cmd);
}

sub mv {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $cmd = 'mv ';

    $cmd .= join(' ', @{ $params->{args} }) . ' ' if defined $params->{args};
    $cmd .= join(' ', @{ $params->{keys} }) . ' ' if defined $params->{keys};

    if ($verbose) {
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
}

sub rm {
    my $params = shift;

    my $verbose = $params->{verbose};

    my $cmd = 'rm ';

    $cmd .= join(' ', @{ $params->{args} }) . ' ' if defined $params->{args};
    $cmd .= join(' ', @{ $params->{keys} }) . ' ' if defined $params->{keys};

    if ($verbose) {
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

    unlink $params->{args}->[0] or say $cmd . ": " . $!;
}

1;
