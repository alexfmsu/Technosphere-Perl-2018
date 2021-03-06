package Client::config;

use 5.16.0;
use strict;
use warnings;

sub CONFIG_DIR {
    "$ENV{HOME}/.local/share/client";
}

sub new {
    my ($self, %params) = @_;

    $params{config_dir} ||= CONFIG_DIR;

    unless (-d $params{config_dir}) {
        system("mkdir -p " . $params{config_dir});
    }

    return bless \%params, $self;
}

1;
