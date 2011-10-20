package Ignite::Event;

use strict;
use warnings;

use Mojo::Base -base;
use Mojo::JSON;

has [qw/ version channel data /];

sub versionCacheKey {
    return 'v'.shift->version;
}

sub to_json {
    return Mojo::JSON->encode( shift->data );
}

# server sent event
sub to_sse {
    my $self = shift;
    return join("\n", 'id:'.$self->versonCacheKey, 'data:'.$self->to_json )."\n";
}

1;
