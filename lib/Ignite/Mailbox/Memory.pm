package Ignite::Mailbox::Memory;

use strict;
use warnings;

use Mojo::Base -base;

has [qw/ noBugs /];

has events => sub { {} };
has versions => sub { {} };
has eventLimit => 1_000;

sub getVersion {
    my ( $self, $channel ) = @_;

    return $self->versions->{$channel} || 0;
}

sub append {
    my ( $self, $event ) = @_;

    my $version = $event->version;
    my $channel = $event->channel;

    $self->versions->{$channel} = $version;

    my $ev = $self->events->{$channel} ||= [];
    if ( @$ev > $self->eventLimit ) {
        my $l = @$ev - $self->eventLimit;
        splice( @$ev, $l * -1, $l, $event );
    } else {
        push( @$ev, $event );
    }

    return;
}

1;
