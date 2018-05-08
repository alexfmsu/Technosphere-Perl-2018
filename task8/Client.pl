use 5.16.0;
use strict;
use warnings;
# -----------
use DDP;
use JSON::XS;
use Getopt::Long;
# ---------------
use lib '.';

use Client::client;
# -----------------
use EV;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::ReadLine::Gnu;
# --------------------------
no warnings 'experimental';

my $help;
my $verbose = 0;

my $host;
my $port = 9000;

my $cv = AE::cv;

GetOptions(
    "verbose+" => \$verbose,
    "host=s"   => \$host,
    "port=i"   => \$port,
);

our $help_message = <<'HELP_MESSAGE';
perl client.pl [-h] [-p] /path/to/somewhere
        
        -h | --host        - host
        -p | --port        - port
HELP_MESSAGE

if ($help || !defined($host) || !defined($host)) {
    say $help_message;
    exit(0);
}

my $handle;
$handle = AnyEvent::Handle->new(
    connect  => [ $host, $port ],
    on_error => sub {
        shift;
        my ($fatal, $msg) = @_;
        warn "Error: $msg\n";
        $cv->send;
    },
    on_eof => sub {
        warn "EOF\n";
        $handle->destroy;
        $cv->send;
    },
    on_prepare => sub {
        warn "Connecting to $host on port $port\n";
    },
);

my $prompt = `whoami`;
chomp($prompt);
$prompt = '[' . $prompt . ' ~]$ ';

my $rl = new AnyEvent::ReadLine::Gnu
  prompt  => $prompt,
  on_line => sub {
    $_ = shift;

    s/^\s+//;
    s/\s+$//;

    my @exit = qw(\\q exit quit);

    if ($_ ~~ @exit) {
        say "Bye!";

        exit(0);
    }

    say "Command: $_";

    my $cmd = encode_json({ cmd => $_, verbose => $verbose });

    # AnyEvent::ReadLine::Gnu->print("you entered: $_\n");

    $handle->push_write($cmd . "\n");
    $handle->push_read(line => \&listener);
  };

sub listener {
    my ($h, $line) = @_;

    if ($line =~ /^(bye|quit|exit)$/i) {
        warn "Server Disconnected !!!\n";
        $h->destroy;
        $cv->send;
    }
    else {
        $line = decode_json($line)->{result};
        warn "<Server>: $line\n";

        $h->push_read(line => \&listener);
    }
}

$cv->recv;

1;
