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
            root_dir        => 'bin',
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
        expected => sub { `cd bin && LC_ALL=C ls *` },
        client   => $client
    ),
    Tester->new(
        name     => 'ls -a *',
        test     => ['ls -a *'],
        expected => sub { `cd bin && LC_ALL=C ls -a *` },
        client   => $client
    ),
    Tester->new(
        name     => 'ls',
        test     => ['ls'],
        expected => sub { `cd bin && LC_ALL=C ls` },
        client   => $client
    ),
    Tester->new(
        name     => 'ls -a',
        test     => ['ls -a'],
        expected => sub { `cd bin && LC_ALL=C ls -a` },
        client   => $client
    ),
    Tester->new(
        name     => 'ls cl*',
        test     => ['ls cl*'],
        expected => sub { `cd bin && LC_ALL=C ls cl*` },
        client   => $client
    ),
    Tester->new(
        name     => 'ls -a cl*',
        test     => ['ls -a cl*'],
        expected => sub { `cd bin && LC_ALL=C ls -a cl*` },
        client   => $client
    ),
);

for (@tests) {
    $_->run_test();
}

done_testing();
