package Client::Client;

use 5.16.0;
use strict;
use warnings;
use DDP;

use Getopt::Long;
use Term::ReadLine;
use Path::Resolve;

use lib '.';

use Client::Config;
use Client::Config::Alias;
use Client::Config::History;
use Client::Autocomplete 'cmd_autocomplete';
use JSON::XS;
# use Client::Command;

use IO::Socket;

no warnings 'experimental';

sub new {
    my ($self, %params) = @_;

    $params{port}    ||= 9000;
    $params{verbose} ||= 0;

    $params{socket} = IO::Socket::INET->new(
        PeerAddr => $params{host},
        PeerPort => $params{port},
        Proto    => "tcp",
        Type     => SOCK_STREAM,
        # ) or die "Can't connect to $host:$port $/";
        # ) or warn "$/";
    ) or die "$!";

    my $obj = bless \%params, $self;

    $obj->init();

    return $obj;
}

my $help;
my $verbose;

# -----------------------------------------------
our $help_message = <<'HELP_MESSAGE';
client.pl [-h] [-v] /path/to/somewhere
        
        -h | --help        - print usage and exit
        -v | --verbose     - be verbose
HELP_MESSAGE
# -----------------------------------------------

sub init {
    my $self = shift;

    #     if ($self->{help}) {
    #     # if ($self->{help} || !defined($self->{remote_pwd})) {
    #         say $help_message;

    #         exit(0);
    #     }

    $self->{term} = Term::ReadLine->new('shell2');
    $self->{term}->ornaments(0);

    $self->{config} = Client::Config->new(host => $self->{host}, port => $self->{port});

    #     $self->set_local_pwd();
    #     $self->set_remote_pwd();
    #     $self->set_prompt();

    #     $self->{path} = Path::Resolve->new();

    #     $self->{verbose} ||= 0;
    #     $self->{silent}  ||= 0;

    #     $self->{env} = \%ENV;

    $self->init_history();
    $self->init_alias();
    $self->init_autocomplete();
}

# sub set_local_pwd {
#     my $self = shift;

#     $self->{local_pwd} = `pwd`;

#     chomp($self->{local_pwd});
# }

# sub set_remote_pwd {
#     my $self = shift;

#     $self->{remote_pwd} ||= '.';

#     eval { chdir($self->{remote_pwd}) } or die "'$self->{remote_pwd}': no such directory\n";
# }

# sub set_prompt {
#     my $self = shift;

#     $self->{username} = `whoami`;

#     chomp($self->{username});

#     $self->{prompt} = '[' . $self->{username} . ' ~]$ ';
# }

sub init_history {
    my $self = shift;

    $self->{history} = Client::Config::History->new(config => $self->{config});

    $self->{history}->load($self->{term});
}

sub init_alias {
    my $self = shift;

    $self->{alias} = Client::Config::Alias->new(config => $self->{config});

    $self->{alias}->load();
}

sub init_autocomplete {
    my $self = shift;

    my @cmd = qw(ls cp mv rm);

    &cmd_autocomplete($self->{term}, \@cmd);
}

sub tokenize {
    my $cmd = shift;

    $cmd =~ m{
        ^
        (?<shell>!)?
        (?<command>
            \\q
            |
            \w+
        )
        \s?|$
    }x;

    my %h;

    $h{shell}   = 0 + defined $+{shell};
    $h{command} = $+{command};
    $h{flags}   = [];

    my @flags;
    my @args;

    while (
        $cmd =~ m{
            (?:
                \s\-(?<flag>[^-\s]+)
            )
            |
            (?:
                \s(?<arg>[^-\s]+)
            )
    }gx
      )
    {
        if (defined $+{arg}) {
            push @{ $h{args} }, $+{arg};
        }

        if (defined $+{flag}) {
            push @{ $h{flags} }, "-$_" for split //, $+{flag};
        }
    }

    return \%h;
}

sub handle_input {
    my ($self, $line) = @_;

    p $line;

    my $socket = $self->{socket};
    die "socket not exist" unless $socket;
    $_ = $line;
    $_ = $self->{alias}->get_alias($_);

    next if /^\s*$/;

    s/^\s+//;
    s/\s+$//;

    my @exit = qw(\\q exit quit);

    # if ($_ ~~ @exit) {
    # exit(0);
    # }

    my $h = tokenize($_);

    if ($h->{command} ~~ [ 'exit', 'quit', '\q' ]) {
        $self->{alias}->push_alias();

        $self->{history}->push_history();

        say "Bye!";

        exit(0);
    }

    if ($h->{command} eq 'alias') {
        my $args = $h->{args}->[0];

        my @p = split /=/, $args;
        my $arg0 = $p[0];

        my $flags = ' ';
        $flags .= join(' ', @{ $h->{flags} }) if defined $h->{flags};

        my $arg1 = $p[1] . ' ' . $flags;

        $self->{alias}->set_alias($arg0, $arg1);

        next;
    }
    $h->{verbose} = $self->{verbose};
    p $h;
    my $cmd = encode_json($h);

    print $socket $cmd . "\n";

    my $answer = <$socket>;

    chomp($answer);

    $answer = decode_json($answer);

    if ($answer->{err_code}) {
        say $answer->{err_msg};
        exit(0);
    }

    unless ($self->{silent}) {
        say $answer->{result};
    }

    my $out = $answer->{result};

    return $answer;
}

1;
