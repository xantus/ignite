#!/usr/bin/perl

# vim: set syntax=perl

use Test::More tests => 9;

BEGIN {
    use_ok 'Mojo';
    use_ok 'Ignite';
    use_ok 'Ignite::Client';
    use_ok 'Ignite::Event';
    use_ok 'Ignite::ClusterLock';
    use_ok 'Ignite::Cache::LRU';
    use_ok 'Ignite::ClientData::Memory';
    use_ok 'Ignite::Mailbox::Memory';
}

Test::More::pass("ignite defined") if *ignite;
