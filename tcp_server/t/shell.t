use 5.16.0;
use strict;
use warnings;

use Test::More;
use Test::TCP;

use lib 't';

use Tester;

my $server = Test::TCP->new(
    listen => 10,
    code   => sub {
        Server::Server->new(
            port            => 9000,
            root_dir        => '.',
            max_connections => 10,
        )->process();
    },
);

sleep(1);

my $client = Client::Client->new(
    host    => 'localhost',
    port    => 9000,
    verbose => 0,
    silent  => 1,
);

my @tests = (
    Tester->new(
        name     => '!whoami',
        test     => ['!whoami'],
        expected => sub { `whoami 2>&1` },
        client   => $client
    ),
    Tester->new(
        name     => '!pwd',
        test     => ['!pwd'],
        expected => sub { `pwd 2>&1` },
        client   => $client
    ),
    Tester->new(
        name     => '!ls',
        test     => ['!ls'],
        expected => sub { `ls` },
        client   => $client
    ),
    Tester->new(
        name       => '!touch file1',
        test       => [ '!touch file1', '!ls file1' ],
        expected   => sub { `ls file1` },
        after_test => sub { `rm file1 2>/dev/null || true` },
        client     => $client
    ),
);

for (@tests) {
    $_->run_test();
}

done_testing();
