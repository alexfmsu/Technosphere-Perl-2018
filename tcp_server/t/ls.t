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
        name     => 'ls *',
        test     => ['ls *'],
        expected => sub { `LC_ALL=C ls *` },
        client   => $client
    ),
    Tester->new(
        name     => 'ls -a *',
        test     => ['ls -a *'],
        expected => sub { `LC_ALL=C ls -a *` },
        client   => $client
    ),
    Tester->new(
        name     => 'ls',
        test     => ['ls'],
        expected => sub { `LC_ALL=C ls` },
        client   => $client
    ),
    Tester->new(
        name     => 'ls -a',
        test     => ['ls -a'],
        expected => sub { `LC_ALL=C ls -a` },
        client   => $client
    ),
    Tester->new(
        name     => 'ls b*',
        test     => ['ls b*'],
        expected => sub { `LC_ALL=C ls b*` },
        client   => $client
    ),
    Tester->new(
        name     => 'ls -a b*',
        test     => ['ls -a b*'],
        expected => sub { `LC_ALL=C ls -a b*` },
        client   => $client
    ),
);

for (@tests) {
    $_->run_test();
}

done_testing();
