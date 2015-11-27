package File::RDir;

use strict;
use warnings;

use Carp qw(croak);

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(read_rdir) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

sub new {
    my $pkg = shift;
    my ($dir) = @_;
    $dir =~ s{\\}'/'xmsg;

    opendir my $hdl, $dir or croak "Can't opendir '$dir' because $!";

    my $self = { 'root' => $dir, 'ndir' => '', 'dlist' => [], 'hdl' => $hdl };

    bless $self, $pkg;
}

sub match {
    my $self = shift;
    return unless $self->{'hdl'};

    my $ele;
    my $full_dir = $self->{'root'}.$self->{'ndir'};

    LOOP1: {
        $ele = readdir $self->{'hdl'};

        unless (defined $ele) {
            closedir $self->{'hdl'};
            $self->{'hdl'} = undef;

            my $ndir = shift @{$self->{'dlist'}};
            last LOOP1 unless defined $ndir;

            $self->{'ndir'} = $ndir;

            $full_dir = $self->{'root'}.$self->{'ndir'};
            opendir $self->{'hdl'}, $full_dir or croak "Can't opendir '$full_dir' because $!";
            redo LOOP1;
        }

        redo LOOP1 if $ele eq '.' or $ele eq '..'; # <-- This is highly important !!!

        my $full_ele = $full_dir.'/'.$ele;

        if (-d $full_ele) {
            push @{$self->{'dlist'}}, $self->{'ndir'}.'/'.$ele;
            redo LOOP1;
        }
    }

    return unless defined $ele;

    return $self->{'ndir'}.'/'.$ele;
}

sub read_rdir {
    my ($dir) = @_;

    my @FList;

    my $obj = File::RDir->new($dir);

    while (defined(my $file = $obj->match)) {
        push @FList, $file;
    }

    return @FList;
}

1;

__END__

=head1 NAME

File::RDir - List directories and recurse into subdirectories.

=head1 SYNOPSIS

  use File::RDir;

=head1 AUTHOR

Klaus Eichner, November 2015

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Klaus Eichner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
