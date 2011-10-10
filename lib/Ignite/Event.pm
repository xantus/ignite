package Ignite::Event;

use strict;
use warnings;

use Mojo::Base -base;

has [qw/ version channel payload /];

sub versionCacheKey {
    return 'v'.shift->version;
}

1;
