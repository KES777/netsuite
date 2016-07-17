#!/usr/bin/env perl


use strict;
use warnings;

use Test::More 'no_plan';
use Test::Deep;

use Data::Dump qw/ pp /;
use lib '../lib';


my $tree;
BEGIN{ use_ok( 'Tree' ); }

cmp_deeply
	+Tree::->new()
	,noclass({})
	,"Create Tree::";


cmp_deeply
	+Tree::->new( [{ id =>  1 }] )
	,noclass({ root =>  { id =>  1 }, nodes =>  {  1 =>  { id =>  1 } } })
	,"Create Tree:: with one node";

eval{ Tree::->new( [{ id =>  undef }] ) };
cmp_deeply
	$@ =~ s/ at.*$//r                                               #/
	,"Node should have ID\n"
	,"Node should have ID";

eval{ Tree::->new( [{ id =>  1, parent_id =>  1 }] ) };
cmp_deeply
	$@ =~ s/ at.*$//r                                               #/
	,"Node can not refer to itself\n"
	,"Node can not refer to itself";

eval{ Tree::->new()->root({ id =>  1, parent_id =>  2 }) };
cmp_deeply
	$@ =~ s/ at.*$//r                                               #/
	,"Root node can not have parent\n"
	,"Root node can not have parent";

$tree =  Tree::->new();
$tree->add_node( { id =>  1, parent_id =>  2 }, 1 );
cmp_deeply
	$tree
	,noclass({()
		,broken =>  { 2 =>  [{ id=>1, parent_id=>2}] }
		,nodes  =>  { 1 =>   { id=>1, parent_id=>2}  }
	})
	,"Create orphan node in the Tree::";


$tree =  Tree::->new();
$tree->add_node( { id =>  1 } );
cmp_deeply
	$tree
	,noclass({ root =>  { id =>  1 }, nodes =>  {  1 =>  { id =>  1 } } })
	,"Add root node to the empty Tree::";

eval{ $tree->add_node( { id =>  2 } ) };
is
	$@ =~ s/ at.*$//r                                               #/
	,"Tree:: can contain only one root node\n"
	,"Tree:: can contain only one root node";

eval{ $tree->add_node( { id =>  2, parent_id =>  0 } ) };
cmp_deeply
	$@ =~ s/ at.*$//r                                               #/
	,"No such parent in the Tree::\n"
	,"Allow false value as parent_id";

eval{ $tree->add_node( { id =>  1, parent_id =>  2 } ) };
is
	$@ =~ s/ at.*$//r                                               #/
	,"Node with specified ID already in the Tree::\n"
	,"Tree:: can not contain nodes with same ID";

eval{ $tree->add_node( { id =>  3, parent_id =>  2 } ) };
is
	$@ =~ s/ at.*$//r                                               #/
	,"No such parent in the Tree::\n"
	,"Parent node should exists in the Tree::";


$tree->add_node( { id =>  2, parent_id =>  1 } );
$tree->add_node( { id =>  3, parent_id =>  2 } );
$tree->add_node( { id =>  4, parent_id =>  1 } );
cmp_deeply
	$tree
	,noclass({ root =>  { id =>  1 }, nodes =>  {()
		,1 =>  { id =>  1 }
		,2 =>  { id =>  2,  parent_id =>  1 }
		,3 =>  { id =>  3,  parent_id =>  2 }
		,4 =>  { id =>  4,  parent_id =>  1 }
	} })
	,"Add leaves into the Tree::";



## Node delation tests
cmp_deeply
	$tree->del_node( 5 )
	,[]
	,"Delete not existing node from the Tree::";


cmp_deeply
	$tree->del_node( 4 )
	,[ { id =>  4,  parent_id =>  1 } ]
	,"Delete leaf from the Tree::";

cmp_deeply
	$tree
	,noclass({ root =>  { id =>  1 }, nodes =>  {()
		,1 =>  { id =>  1 }
		,2 =>  { id =>  2,  parent_id =>  1 }
		,3 =>  { id =>  3,  parent_id =>  2 }
	} })
	,"Check nodes after leaf delation from the Tree::";



cmp_deeply
	$tree->del_node( 2 )
	,[ { id =>  2,  parent_id =>  1 }, { id =>  3,  parent_id =>  2 } ]
	,"Delete branch from the Tree::";

cmp_deeply
	$tree
	,noclass({ root =>  { id =>  1 }, nodes =>  {()
		,1 =>  { id =>  1 }
	} })
	,"Check nodes after branch delation from the Tree::";



cmp_deeply
	$tree->del_node( 1 )
	# We do not require parent_id key should exist for root node
	,[ subhashof({ id =>  1,  parent_id =>  undef }) ]
	,"Delete root node from the Tree:: when only root node exists";

cmp_deeply
	$tree
	,noclass({ root =>  undef, nodes =>  {} })
	,"Check the Tree:: after root delation";


$tree->add_node({ id =>  1 });
$tree->add_node({ id =>  2, parent_id =>  1 });
cmp_deeply
	$tree->del_node( 1 )
	# We do not require parent_id key should exist for root node
	,[ subhashof({ id =>  1, parent_id => undef }), { id =>  2, parent_id =>  1 } ]
	,"Delete root node from the Tree:: when children nodes exist";

cmp_deeply
	$tree
	,noclass({ root =>  undef, nodes =>  {} })
	,"Check the Tree:: after root delation";
