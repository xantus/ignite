package Ignite;

use strict;
use warnings;

use Mojo::Base -base;
use Ignite::Mailbox::Memory;
use Ignite::Cache::LRU;
use Ignite::ClusterLock;
use Ignite::Event;
use Scalar::Util qw( weaken );

our $singleton;

has [qw/ noBugs /]; # haha

has mbox => sub {
    Ignite::Mailbox::Memory->new;
};

has cache => sub {
    Ignite::Cache::LRU->new;
};

has clusterLock => sub {
    Ignite::ClusterLock->new;
};

sub import {
    my $caller = caller;

    # could auto use mojo lite here
    eval( "package $caller;" );

    # Prepare exports
    no strict 'refs';
    no warnings 'redefine';

    my $ignite = undef;

    *{"${caller}::on_event"} = sub {
        my $event = shift or die 'usage: socketio \'event\' => sub { ... }';

        die "You must ignite->init( \$couchurl ) first\n" unless defined $ignite;

        $ignite->plugins->add_hook( $event => @_ );
    };

    *{"${caller}::ignite"} = sub {
        # auto load the plugin
        #unless ( defined $ignite ) {
        #    $ENV{IGNITE_PLUGIN} = $ignite = $app->plugins->load_plugin( $app, 'ignite' );
        #}
        #return $ignite;
        return Ignite->singleton;
    };
}

sub new {
    my $class = shift;
    my $self;

    my $single = $singleton;
    local $singleton = undef;

    if ($single) {
        $self = $singleton->new( @_ );
        $self->cache( $single->cache->new );
        $self->mbox( $single->mbox->new );
        $self->clusterLock( $single->clusterLock->new );
    } else {
        $self = $class->SUPER::new( @_ );
    }

    return $self;
}

sub singleton { $singleton ||= shift->new(@_) }

sub publishTo {
    my ( $self, $channel, $payload ) = @_;

    $self->publish( Ignite::Event->new( channel => $channel, payload => $payload ) );

    return;
}

sub publish {
    my ( $self, $event ) = @_;

    # XXX we've seen this event already?
    return if defined $event->version;

    my $key = $event->versionCacheKey;
    my $cache = $self->cache;

    my $version = $cache->get( $key );

    $version = $self->mbox->getVersion( $event->channel ) unless defined $version;

    weaken $self;
    weaken $cache;

    $self->clusterLock->doWithLock( $key, sub {
        $event->version( ++$version );
        $self->mbox->append( $event );
        $cache->put( $key, $version );
    });

    return;
}

1;
