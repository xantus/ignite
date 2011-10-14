package Ignite::Event;

use strict;
use warnings;

use Mojo::Base -base;

has [qw/ version channel data /];

sub versionCacheKey {
    return 'v'.shift->version;
}

1;
