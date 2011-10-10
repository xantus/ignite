package Ignite::Mailbox::Memory;

use strict;
use warnings;

use Mojo::Base -base;

has [qw/ noBugs /];

has events => sub { {} };
has versions => sub { {} };

sub getVersion {
    my ( $self, $channel ) = @_;

    return $self->versions->{$channel} || 0;
}

sub append {
    my ( $self, $event ) = @_;

    my $version = $event->version;
    my $channel = $event->channel;

    $self->versions->{$channel} = $version;

    # TODO limit num of events?
    my $ev = $self->events->{$channel} ||= [];

    push( @$ev, $event );

    return;
}

1;
