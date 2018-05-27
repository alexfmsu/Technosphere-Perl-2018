package Client::Config::Alias;

use 5.16.0;
use strict;
use warnings;
use DDP;

sub ALIAS_FILENAME {
    ".rc";
}

sub new {
    my ($self, %params) = @_;

    $params{filename} ||= ALIAS_FILENAME;

    $params{alias_path} = $params{config}->{config_dir} . '/' . $params{filename};

    return bless \%params, $self;
}

sub load {
    my $self = shift;

    `touch $self->{alias_path}` unless -e $self->{alias_path};
    
    open(my $fh_alias, '<', $self->{alias_path}) or die $!;

    %{ $self->{alias} } = map { $1, $2 if /(\w+)=(!?\w+)/ } grep { /\w+=!?\w+\n/ } <$fh_alias>;

    close $fh_alias;

}

sub get_alias {
    my ($self, $text) = @_;

    exists($self->{alias}->{$text}) ? $self->{alias}->{$text} : $_;
}

sub push_alias {
    my $self = shift;

    if (keys %{ $self->{alias} }) {
        open(my $fh_alias, '>', $self->{alias_path}) or die $!;

        my @alias = map { $_ . '=' . $self->{alias}->{$_} } keys %{ $self->{alias} };

        print $fh_alias join "\n", @alias, "";

        close($fh_alias);
    }
}

sub set_alias {
    my ($self, $cmd1, $cmd2) = @_;

    $self->{alias}->{$cmd1} = $cmd2;
}

1;
