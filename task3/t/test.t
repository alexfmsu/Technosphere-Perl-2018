use Test::More;

use lib 't';

use Tester;

my $client = Client::client->new(
    host       => '127.0.0.1',
    port       => 80,
    remote_pwd => '.',
    verbose    => 0,
    silent     => 1,
);

my @tests = (
    Tester->new(
        name     => '!pwd',
        test     => ['!pwd'],
        expected => sub { `pwd` },
        client   => $client,
    ),
    Tester->new(
        name     => '!whoami',
        test     => ['!whoami'],
        expected => sub { `whoami  2>&1` },
        client   => $client,
    ),
    Tester->new(
        name       => '!touch',
        test       => [ '!touch file1', '!ls file1' ],
        expected   => sub { `ls file1` },
        after_test => sub { `rm file1` },
        client     => $client,
    ),
    Tester->new(
        name        => 'mv file1 file2',
        before_test => sub { `touch file1` },
        test        => [ 'mv file1 file2', '!ls file2' ],
        expected    => sub { `ls file2` },
        after_test  => sub { `rm file2` },
        client      => $client,
    ),
    Tester->new(
        name     => '!ls',
        test     => ['!ls'],
        expected => sub { `ls` },
        client   => $client
    ),
);

for (@tests) {
    $_->run_test();
}

done_testing(1 + scalar @tests);
