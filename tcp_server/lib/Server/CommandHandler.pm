package Server::CommandHandler;

use 5.16.0;
use strict;
use warnings;

use DDP;

use Getopt::Long;

use Term::ReadLine;
# use Path::Resolve;

use Server::Command;

no warnings 'experimental';

sub new {
    my ($self, %params) = @_;

    my $obj = bless \%params, $self;

    return $obj;
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
    my ($self, $in) = (shift, shift);

    # p $in;

    # $in = decode_json($in);
    # $_ = $in;

    # /^\s*$/ ? next : chomp;

    # s/^\s+//;
    # s/\s+$//;

    my $cmd;

    # $_ = $self->{alias}->get_alias($_);

    my $h = $in;

    $h->{root_dir} = $self->{root_dir};

    if ($h->{shell} == 1) {
        $cmd = Client::Command->new(%$h);
    }
    else {
        if ($h->{command} eq 'cp') {
            my $arg0;
            my $arg1;

            if (scalar @{ $h->{args} } == 2) {
                $arg0 = $self->{path}->join($self->{local_pwd}, '/' . $h->{args}->[0]);
                $arg1 = $self->{path}->join($self->{remote_pwd}, '/' . ($h->{args}->[1]), '/' . ($h->{args}->[0]));
            }
            elsif (scalar @{ $h->{args} } == 1) {
                $arg0 = $self->{path}->join($self->{local_pwd}, '/' . $h->{args}->[0]);
                $arg1 = $h->{args}->[0];
            }

            $h->{args}->[1] = $arg1;
            $h->{args}->[0] = $arg0;
        }

        if ($h->{command} ~~ [ 'exit', 'quit', '\q' ]) {
            # $self->{alias}->push_alias();

            # $self->{history}->push_history();

            # say "Bye!";

            # exit(0);
        }

        $cmd = Client::Command->new(%$h);
    }

    my $out;

    if (defined($cmd)) {
        # $cmd->{verbose} = $self->{verbose};
        $cmd->{host} = $self->{host};
        $cmd->{port} = $self->{port};

        if ($cmd->{shell} == 1) {
            $out = $cmd->shell_call();
        }
        elsif ($cmd->{command} ne 'alias') {
            p $cmd;
            $out = $cmd->call();
        }

        # print $out unless $self->{silent};
    }

    return $out;
}

1;
