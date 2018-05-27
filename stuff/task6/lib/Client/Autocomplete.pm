package Client::Autocomplete;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(cmd_autocomplete);

my $var_CompleteAddsuffix = 1;

sub rl_filename_list {
    my $pattern = shift;

    my @files = (<$pattern*>);

    if ($var_CompleteAddsuffix) {
        foreach (@files) {
            if (-l $_) {
                $_ .= '@';
            }
            elsif (-d _ ) {
                $_ .= '/';
            }
            elsif (-x _ ) {
                $_ .= '*';
            }
            elsif (-S _ || -p _ ) {
                $_ .= '=';
            }
        }
    }

    return @files;
}

sub cmd {
    my ($text, $cur_hr) = ($_[0], $_[1]);

    my $is_shell_cmd = $text =~ s/^!//;

    my @cmd = grep { /^$text.+$/im } sort @$cur_hr;

    if ($is_shell_cmd) {
        $_ = '!' . $_ for @cmd;
    }

    return @cmd;
}

sub cmd_autocomplete {
    my ($term, $cur_hr) = @_;

    $term->Attribs->{completion_function} = sub {
        my $text = $_[1];

        my @comp = cmd($text, $cur_hr);

        return @comp if @comp;

        @comp = rl_filename_list($_[0]);

        return @comp;
      }
}

1;
