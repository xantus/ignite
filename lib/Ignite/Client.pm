package Ignite::Client;

use Mojo::Base 'Mojo::EventEmitter';

has [qw/ active cid data /];

has ssePingTime => 15;

use Scalar::Util qw( weaken );

sub startSSE {
    my ( $self, $app ) = @_;

    # TODO Last-Event-ID
#    my $version = $app->req->headers->header("Last-Event-ID");

    weaken $self;
    weaken $app;

    $self->active( time );

    my @events = $self->getEvents;
    my $out;
    foreach ( @events ) {
        $out .= $_->to_sse;
    }
    $app->write( $out ) if $out;

    # TODO subscriptions from client data
    $self->on(notify => sub {
        my $ev = pop;
        warn "event fired on ".$ev->channel."\n";
        $self->active( time );
        $app->write($ev->to_sse);
    });

    my $id = Mojo::IOLoop->singleton->recurring($self->ssePingTime => sub {
        # TODO active
        $app->write(":\n");
    });

    $self->on(_finish => sub {
        Mojo::IOLoop->singleton->drop($id);
        $self->unsubscribe_all;
        return;
    });

    my $cb = $app->on_finish;
    $app->on_finish(sub { $cb->(@_) if $cb; $self->emit('_finish', @_); });

    return;
}

1;
