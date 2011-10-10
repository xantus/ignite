package Ignite::Cache::LRU;

use strict;
use warnings;

use Mojo::Base -base;

# Converted from code I wrote at Six Apart
# http://code.sixapart.com/svn/js/trunk/common/Cache.js
# See the end of the file for the 

has lru => 0;
has mru => 0;
has size => 0;
has maxSize => 10_000;
has hits => 0;
has misses => 0;

has idx => sub { {} };
has key => sub { [] };
has value => sub { [] };
has next => sub { [] };
has prev => sub { [] };

sub flush {
    my $self = shift;

    $self->size( 0 );
    # least recently used
    $self->lru( 0 );
    # most recently used
    $self->mru( 0 );

    # idx to position in value,prev,next arrays
    $self->idx( {} );

    # each node has the same offset in:
    $self->key( [] );
    $self->value( [] );
    $self->prev( [] );
    $self->next( [] );

    return;
}

sub getItemsOrdered {
    my $self = shift;
    my $offset = shift || 0;
    my $count = shift || $self->size;

    my @k;
    my @v;

    my $idx = $self->mru;
    my $c = 0;

    for my $i ( 0 .. $self->size ) {
        # walk until it reaches the needed offset
        if ( $i < $offset ) {
            $idx = $self->next->[ $idx ];
            next;
        }

        #push( @k, $self->key->[ $idx ] );
        push( @k, $self->value->[ $idx ]->[ 0 ] );
        push( @v, $self->value->[ $idx ]->[ 1 ] );

        $c++;

        # keep pulling keys/values until count is reached, or end of array
        last if $c >= $count;

        $idx = $self->next->[ $idx ];
    }

    return [ \@k, \@v ];
}

sub deleteItem {
    my ( $self, $key ) = @_;
    return unless exists $self->idx->{ $key };

    my $value = $self->value->[ $self->idx->{ $key } ];
    $self->deleteNode( $key );
    return $value;
}

*put = *setItem;

sub setItem {
    my ( $self, $key, $value ) = @_;

    return if ( !defined( $key ) || !defined( $value ) );

    my $lru = $self->lru;

    my $idx;

    if ( $self->idx->{ $key } ) {
        $idx = $self->deleteNode( $key );
    } elsif ( $self->size >= $self->maxSize && defined( $self->value->[ $lru ] ) ) {
        $idx = $self->deleteNode( $self->value->[ $lru ]->[ 0 ] );
    } elsif ( @{$self->key} && !defined $self->value->[ $lru ] ) {
        $idx = $lru;
    }

    $self->insertNode( $key, $value, $idx );

    return $value;
}

*get = *getItem;

sub getItem {
    my ( $self, $key ) = @_;

    # index of node requested
    my $idx = $self->idx->{ $key };

    # does this node exist
    if ( !$self->idx->{ $key } || $idx < 0 || $idx >= $self->size || !defined( $self->value->[ $idx ] ) ) {
        # cache miss stat
        $self->{misses}++;
        return;
    }

    #cache hit stat
    $self->{hits}++;

    # move it to the front
    $self->setMRU( $idx );

    return $self->value->[ $idx ];
}

sub getItems {
    my ( $self, $ids ) = @_;

    my @items;

    for my $i ( 0 .. $#{ $ids } ) {
        next unless my $item = $self->getItem( $i );
        push( @items, $item );
    }

    return wantarray ? @items : \@items;
}

sub touchItem {
    my ( $self, $key ) = @_;

    # index of node requested
    my $idx = $self->idx->{ $key };

    # does this node exist
    return if ( !$self->idx->{ $key } || $idx < 0 || $idx >= $self->size || !defined( $self->value->[ $idx ] ) );

    # move it to the front
    $self->setMRU( $idx );

    return;
}

# private functions
sub setMRU {
    my ( $self, $idx ) = @_;

    my $prevnode = $self->prev->[ $idx ];
    my $nextnode = $self->next->[ $idx ];

    if ( $prevnode == -1 ) {
        # this can happen if you select the mru
        warn "LRUCache::setMRU idx:$idx has an inconsistent PREV key (PREV:-1 but MRU != idx)"
            if ($self->mru != $idx);
        return;
    }

    $self->connectNodes( $prevnode, $nextnode );

    # make this node the mru by making the current mru a peer of this node
    $self->prev->[ $self->mru ] = $idx;
    $self->next->[ $idx ] = $self->mru;

    $self->prev->[ $idx ] = -1;
    $self->mru( $idx );
}

sub setLRU {
    my ( $self, $idx ) = @_;

    my $nextnode = $self->next->[ $idx ];
    my $prevnode = $self->prev->[ $idx ];

    if ( $nextnode == -1 ) {
        warn "LRUCache::setLRU  idx:$idx has an inconsistent NEXT key (NEXT:-1 but LRU != idx)"
            if ($self->lru != $idx);
        return;
    }

    $self->connectNodes( $prevnode, $nextnode );

    # move it to the end
    $self->next->[ $self->lru ] = $idx;
    $self->prev->[ $idx ] = $self->lru;

    $self->next->[ $idx ] = -1;
    $self->lru( $idx );
}

sub connectNodes {
    my ( $self, $prevnode, $nextnode ) = @_;

    # match peers to each other

    if ( $prevnode == -1 ) {
        $self->mru( $nextnode );
    } else {
        $self->next->[ $prevnode ] = $nextnode;
    }

    if ($nextnode == -1) {
        $self->lru( $prevnode );
    } else {
        $self->prev->[ $nextnode ] = $prevnode;
    }

}


# reposition a nodes peers and return the index
sub deleteNode {
    my ( $self, $key ) = @_;
    my $idx = $self->idx->{ $key };

    # move it to the end
    $self->setLRU( $idx );

    delete $self->idx->{ $key };

    $self->key->[ $idx ] = undef;
    $self->value->[ $idx ] = undef;

    # the node isnt actually deleted, it is reused
    return $idx;
}

sub insertNode {
    my ( $self, $key, $value, $idx ) = @_;

    # insert new node
    if ( !defined( $idx ) ) {
        $idx = $self->{size}++;
    }

    # move it to the front
    $self->setMRU( $idx );

    $self->value->[ $idx ] = [ $key, $value ];
    #$self->key->[ $idx ] = $key;
    $self->idx->{ $key } = $idx;

    return $idx;
}


# for debugging
sub visualize {
    my $self = shift;

    my $c = $self->lru;
    warn "LRUCache::visualize MRU: $c";

    for my $i ( 0 .. $self->size ) {
        warn "LRUCache::visualize [ ".$self->key->[ $c ]." ] $c ". (($self->lru == $c) ? " - LRU" : "") . (($self->mru == $c) ? " - MRU" : "");
        $c = $self->prev->[ $c ];
    }
}

1;

__END__

Converted from code I wrote at Six Apart
http://code.sixapart.com/svn/js/trunk/common/Cache.js

Changes Copyright (c) 2011 David Davis <xantus@xant.us> http://xant.us/

Copyright (c) 2005, Six Apart, Ltd.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the
distribution.

    * Neither the name of "Six Apart" nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

