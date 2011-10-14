package Ignite::ClientData::Memory;

use base 'Ignite::Cache::LRU';

sub new {
    shift->SUPER::new( @_ );
}

1;
