package Ignite::ClusterLock;

use strict;
use warnings;

use Mojo::Base -base;
use Mojo::IOLoop;

has ioloop => sub {
    Mojo::IOLoop->singleton;
};

sub doWithLock {
    my ( $self, $key, $cb ) = @_;

    # TODO

    #$cb->();

    $self->ioloop->timer( 1 => $cb );

    return;
}

1;
