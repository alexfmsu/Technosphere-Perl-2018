use 5.16.0;
use strict;
use warnings;
use utf8;
use DDP;

# print "$_\n" for <"./bin/*">;
# print "$_\n" for <"*">;

# my %files = ();

# sub ls {
#     my ($path, $files) = shift;
#     # p $path;
#     for (<"$path">) {
#         if (-d $_) {
#             # p $_;
#             # sleep(1);

#             push @$files, { $_ => ls("$_/*", $files) };
#         }
#         elsif (-e $_) {
#             /([^\/]*)$/;
#             push @$files, $1;
#         }
#     }

#     # p $files;

#     $files;
# }

sub ls {
    my ($path, $files) = shift;
    # p $path;
    for (<"$path">) {
        if (-d $_) {
            # p $_;
            # sleep(1);
            # s/^[^\/]+//;
            # p $_;
            /([^\/]*)$/;
            push @$files, $1;

            #    if($_){
            #    	push @$files, { $_ => ls("$_/*", $files) };
            # }
        }
        elsif (-e $_) {
            /([^\/]*)$/;
            push @$files, $1;
        }
    }

    # p $files;

    $files;
}

sub print_tree {
    my ($tree) = @_;

    my $print_dir = 0;

    if (scalar @$tree > 1) {
        $print_dir = 1;
    }

    for (@$tree) {
        if (ref $_ eq 'HASH') {
            while (my ($k, $v) = each %$_) {
                say "$k:" if $print_dir;
                print "$_\t" for @$v;

                say "";
            }
        }
    }

    my @f;
    
    for (@$tree) {
        unless (ref $_ eq 'HASH') {
           	push @f, $_;
        }
    }

    local $, = "  ";
    print @f, "\n";
}
# for(<"*">){
# 	if(-d $_){
# 		$files{$_} = {};
# 	}elsif(-e $_){
# 		$files{$_} = 'f';
# 	}
# }
my @files;

my $f;
# $f = ls("bi*", \@files);
$f = ls("*", \@files);

# p $f;
# sub list

sub ls_item {
    my $path = shift;

    if (-d $path) {
        my @files;
        p $_;

        for (<"$path/*">) {
            /([^\/]*)$/;

            push @files, $1;
        }

        return { $path => \@files };
    }
    else {
        return $_;
    }
}

sub filter {
    my $path = shift;

    my $files;

    for (<"$path">) {
        push @$files, ls_item($_);
    }

    $files;
}

my $ff = filter("bin/*");
# p $ff;

print_tree($ff);
