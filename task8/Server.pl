#!/usr/local/bin/perl -w

use strict;
use warnings;
use EV;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use JSON::XS;

my $port = $ARGV[0] || '9000';
my $cv = AE::cv;

use lib '.';

use Client::client;

tcp_server undef, $port, sub {
    my $fh = shift or die "Couldn't accept client: $!";
    my ($host, $port) = @_;


    my $handle;
    $handle = AnyEvent::Handle->new(
        fh       => $fh,
        on_error => sub {
            shift;
            my ($fatal, $msg) = @_;
            warn "Error: [$msg]\n";
            $cv->send;
        },
        on_eof => sub {
            warn "Reached EOF\n";
            $handle->destroy;
            $cv->send;
        },
    );

    $handle->push_read(line => \&listener);
};

sub listener {
    my ($h, $line) = @_;
    warn "<Client>: $line\n";
    $cv->send if $line =~ /^(bye|quit|exit)$/i;

    my $cl = Client::client->new(
        remote_pwd => '.',
        verbose    => 0,
    );

    my $message = decode_json($line);
    my $cmd     = $message->{cmd};

    if (exists $message->{verbose}) {
        $cl->{verbose} = $message->{verbose};
    }

    my $res = $cl->handle_input($cmd);

    $res = encode_json({ result => $res });

    # print $res;

    $h->push_write($res."\n");

    $h->push_read(line => \&listener);
}

$cv->recv;
1;
