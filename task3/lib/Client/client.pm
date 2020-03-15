package Client::client;

use 5.016;
use strict;
use warnings;

use Getopt::Long;
use Term::ReadLine;
use Path::Resolve;
use Pod::Usage;

use lib '.';

use Client::config;
use Client::Config::Alias;
use Client::Config::History;
use Client::Autocomplete 'cmd_autocomplete';
use Client::Commands;

no warnings 'experimental';

sub new {
    my ($self, %params) = @_;

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

    if ($self->{help} || !defined($self->{remote_pwd})) {
        say $help_message;

        exit(0);
    }

    $self->{term} = Term::ReadLine->new('shell');
    $self->{term}->ornaments(0);

    $self->{config} = Client::config->new(host => $self->{host}, port => $self->{port});

    $self->set_local_pwd();
    $self->set_remote_pwd();
    $self->set_prompt();

    $self->{path} = Path::Resolve->new();

    $self->{verbose} ||= 0;
    $self->{silent}  ||= 0;

    $self->{env} = \%ENV;
    
    $self->init_history();
    $self->init_alias();
    $self->init_autocomplete();
}

sub set_local_pwd {
    my $self = shift;

    $self->{local_pwd} = `pwd`;

    chomp($self->{local_pwd});
}

sub set_remote_pwd {
    my $self = shift;

    $self->{remote_pwd} ||= '.';

    eval { chdir($self->{remote_pwd}) } or die "'$self->{remote_pwd}': no such directory\n";
}

sub set_prompt {
    my $self = shift;

    $self->{username} = `whoami`;

    chomp($self->{username});

    $self->{prompt} = '[' . $self->{username} . ' ~]$ ';
}

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

sub handle_input {
    my ($self, $in) = @_;

    $_ = $in;

    /^\s*$/ ? next : chomp;

    s/^\s+//;
    s/\s+$//;

    my $cmd;

    $_ = $self->{alias}->get_alias($_);

    given ($_) {
        when ('ls') {
            $cmd = Client::Commands->new(
                command => 'ls',
                keys    => [ '-l', '-A' ],
            );
        }
        when (/^cp\s+(\S+)\s+(\S+)$/) {
            $cmd = Client::Commands->new(
                command => 'cp',
                args    => [ $self->{path}->join($self->{local_pwd}, '/' . $1), $self->{path}->join($self->{remote_pwd}, '/' . $2, '/' . $1) ]
            );
        }
        when (/^cp\s+(\S+)$/) {
            $cmd = Client::Commands->new(
                command => 'cp',
                args    => [ $self->{path}->join($self->{local_pwd}, '/' . $1), $self->{path}->join($self->{remote_pwd}, '/' . $1) ]
            );
        }
        when (/^mv\s+(\S+)\s+(\S+)$/) {
            $cmd = Client::Commands->new(
                command => 'mv',
                args    => [ $1, $2 ]
            );
        }
        when (/^rm\s+(\S+)$/) {
            $cmd = Client::Commands->new(
                command => 'rm',
                args    => [$1]
            );
        }
        when (/^!(.+)$/) {
            $cmd = Client::Commands->new(
                command => 'shell',
                args    => [$1]
            );
        }
        when (/quit|exit|\\q$/) {
            $self->{alias}->push_alias();

            $self->{history}->push_history();

            say "Bye!";

            exit(0);
        }
        when (/^alias\s+(\w+)=(!?.+)$/) {
            $self->{alias}->set_alias($1, $2);
        }
        default {
            say $_ . ": unknown command";
        }
    }

    $self->{term}->addhistory($_);

    $self->{history}->add_to_history($_);

    my $out;

    if (defined($cmd)) {
        $cmd->{verbose} = $self->{verbose};
        $cmd->{host}    = $self->{host};
        $cmd->{port}    = $self->{port};

        $out = $cmd->call() unless $cmd->{command} eq 'alias';

        print $out unless $self->{silent};
    }

    return $out;
}

1;
