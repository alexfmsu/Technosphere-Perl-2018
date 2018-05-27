use Test::More;
use Test::TCP;

use lib 't';

use Tester;

use DDP;

my $server_test = Test::TCP->new(
    listen => 10,
    code   => sub {
        my $port = shift;

        Server::Server->new(
            port            => 9000,
            root_dir        => '.',
            max_connections => 10,
        )->process();
    },
);

sleep(1);

my $client = Client::Client->new(
    host       => 'localhost',
    port       => 9000,
    remote_pwd => '.',
    verbose    => 0,
    silent     => 1,
);

my @tests = (
    Tester->new(
        name     => 'ls',
        test     => ['ls .'],
        expected => sub { `ls .` },
        client   => $client
    ),
    # Tester->new(
    #     name     => 'rm',
    #     test     => ['rm ../log', 'ls ../log'],
    #     expected => sub { `ls log` },
    #     client=>$client
    # ),
    # Tester->new(
    #     name     => 'ls',
    #     test     => ['ls && ls'],
    #     expected => sub { `ls` },
    #     client=>$client
    # ),
    # Tester->new(
    #     name     => 'cd',
    #     test     => ['cd ../*', '!pwd'],
    #     expected => sub { `cd * 2>&1` },
    #     client=>$client
    # ),
    # Tester->new(
    #     name     => '!whoami',
    #     test     => ['!whoami'],
    #     expected => sub { `whoami  2>&1` },
    #     client=>$client
    # ),
    # Tester->new(
    #     name       => '!touch',
    #     test       => [ '!touch file1', '!ls file1' ],
    #     expected   => sub { `cd bin && ls file1` },
    #     after_test => sub { `cd bin && rm file1` },
    #     client=>$client
    # ),
    # Tester->new(
    #     name        => 'mv file1 file2',
    #     before_test => sub { `touch file1` },
    #     test        => [ 'mv file1 file2', '!ls file2' ],
    #     expected    => sub { `ls file2` },
    #     after_test  => sub { `rm file2` },
    #     client=>$client
    # ),
    # Tester->new(
    #     name     => '!ls',
    #     test     => ['!ls'],
    #     expected => sub { `ls` },
    #     client=>$client
    # ),
    # Tester->new(
    #     name     => 'mkdir tmp',
    #     test     => ['mkdir tmp', '!ls tmp'],
    #     expected => sub { `ls tmp` },
    #     after_test  => sub { `rm -r tmp` },
    #     client=>$client
    # ),
);

for (@tests) {
    $_->run_test();
}

done_testing();
