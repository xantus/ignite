#!/usr/bin/perl

# vim: set syntax=perl

use Test::More tests => 9;

BEGIN {
    use_ok 'Mojo';
    use_ok 'Ignite';
    use_ok 'Ignite::Cache::LRU';
}

use strict;
use warnings;

my $c = Ignite::Cache::LRU->new( maxSize => 5 );

Test::More::pass("started");

eval {
    warn "inserting 6\n";
    $c->put('six',   6);
    warn "inserting 5\n";
    $c->put('five',  5);
    warn "inserting 4\n";
    $c->put('four',  4);
    warn "inserting 3\n";
    $c->put('three', 3);
    warn "inserting 2\n";
    $c->put('two',   2);
    warn "inserting 1\n";
    $c->put('one',   1); # should push 6 out of the stack

    Test::More::pass("got one") if $c->get('one');
    Test::More::pass("got two") if $c->get('two');
    Test::More::pass("got three") if $c->get('three');
    Test::More::pass("got four") if $c->get('four');
    Test::More::pass("got five") if $c->get('five');
    Test::More::pass("no six (good)") unless $c->get('six');
};

Test::More::fail($@) if $@;

