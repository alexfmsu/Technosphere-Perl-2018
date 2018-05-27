package Server::Server;

use 5.16.0;
use strict;
use warnings;
use DDP;

use IO::Socket;
use JSON::XS;
use Path::Resolve;

use Server::CommandHandler;

sub new {
    my ($class, %params) = @_;

    $params{max_connections} ||= 10;
	$params{port} ||= 9000;

    my $pwd = `pwd`;
    chomp($pwd);

    die "root_dir is not defined" unless defined($params{root_dir});

    $params{root_dir} = Path::Resolve->join($pwd, $params{root_dir});
    
    chdir($params{root_dir});

    $params{socket} = IO::Socket::INET->new(
        LocalPort => $params{port},
        Proto     => "tcp",
        Type      => SOCK_STREAM,
        ReuseAddr => 1,
        Listen    => 10,
        Reuse     => 1
    ) or die "Can't create server: $!";

    return bless \%params, $class;
}

sub connect {

}

$SIG{CHLD} = sub {};

sub run {
    my $self = shift;

    my $server          = $self->{socket};
    my $root_dir        = $self->{root_dir};
    my $max_connections = $self->{max_connections};
    my $connections_cnt = $self->{connections_cnt} = 0;

    open(my $log, '>>', 'log');

    while (my $client = $server->accept()) {
        if ($connections_cnt > $max_connections - 1) {
            my $answer = encode_json(
                {
                    err_code => 1,
                    err_msg  => "Unable to connect: too many connections ($max_connections)"
                }
            );

            print $client $answer . "\n";

            close($client);
            next;
        }

        my $child = fork();

        if ($child) {
            $connections_cnt++;
            close($client);
            next;
        }

        if (defined $child) {
            close($server);

            $client->autoflush(1);

            my $message;
            
            my $cl = Server::CommandHandler->new(
                root_dir => $self->{root_dir},
                verbose    => 0,
            );

            while ($message = <$client>) {
                chomp($message);

                $message = decode_json($message);
                p $message;
                my $res = $cl->handle_input($message);

                say $log "command: $message->{command}";
                say $log "answer: $res" if defined($res);
                say $log "-" x 100;

                $res = encode_json({ result => $res });

                print $client $res . "\n";
            }

            close($client);

            exit(0);
        }
        else {
            die "Can't fork: $!";
        }
    }
}

1;

# $SIG{CHLD} = sub {
#     while (my $pid = waitpid(-1, WNOHANG)) {
#         last if $pid == -1;

#         if (WIFEXITED($?)) {
#             my $status = $? >> 8;

#             if ($status == 0) {
#                 $connections_cnt--;
#             }
#         }
#     }
# };
