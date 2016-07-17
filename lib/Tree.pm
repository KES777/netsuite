package Tree;

use v5.24;
use strict;
use warnings;

use Scalar::Util 'blessed';
use feature 'current_sub';

use Exporter 'import';
our @EXPORT_OK =  qw/ traverse /;



our $DEBUG;
my @NODE_PROPERTIES =  qw/ id parent_id /;



sub traverse(&@) {
	my( $code, $curr_node, $level ) =  @_;

	$curr_node  //
		die "Starting node should be supplied to traverse the Tree::";

	$level //=  0;

	my $result =  [];

	local $_ =  $curr_node;
	push @$result, $code->( $level );

	for my $next_node ( $curr_node->{ children }->@* ) {
		push @$result,
			__SUB__->( $code, $next_node , $level +1 )->@*;
	}


	return $result;
}



sub new {
	my $class =  shift;
	$class =  blessed( $class )  ||  $class;

	my $self =  {};
	bless $self, $class;

	$self->_init( @_ );

	return $self;
}



sub _init {
	my( $self, $nodes ) =  @_;

	if( ref $nodes  eq  'ARRAY' ) {
		for my $node ( @$nodes ) {
			$self->add_node( $node, 1 );
			$self->check_broken( $node );
		}

		#TODO: implement Tree:: validation
		keys $self->{ broken }->%*   and
			die "Tree:: contain orphan nodes";

		delete $self->{ broken };
	}
}


sub check_broken {
	my( $self, $node ) =  @_;

	return   unless $node;

	if( exists $self->{ broken }{ $node->{ id } } ) {
		my $children =  delete $self->{ broken }{ $node->{ id } };
		push $node->{ children }->@*, $children->@*;
	}

}



sub root {
	my $self =  shift;


	if( @_ ) {
		my $node =  shift;


		if( $node ) { # $node is undef when we are removing root node
			defined $node->{ parent_id }  and
				die "Root node can not have parent";

			defined $self->{ root }  and
				die "Tree:: can contain only one root node";
		}


		return $self->{ root } =  $node;
	}


	return $self->{ root };
}



sub add_node {
	my( $self, $node, $allow_orphan ) =  @_;

	$node->{ id }  //
		die "Node should have ID";

	$node->{ parent_id }  &&  $node->{ id } == $node->{ parent_id }  and
		die "Node can not refer to itself";

	exists $self->{ nodes }{ $node->{ id } }  and
		die "Node with specified ID already in the Tree::";


	if( defined $node->{ parent_id } ) {
		my $parent_id =  $node->{ parent_id };
		if( !exists $self->{ nodes }{ $parent_id } ) {
			die "No such parent in the Tree::"   unless $allow_orphan;

			push $self->{ broken }{ $parent_id }->@*, $node;
		}
		else {
			push $self->{ nodes }{ $parent_id }{ children }->@*, $node;
		}
	}
	else {
		$self->root( $node );
	}

	delete $self->{ _level }; #TODO: IT


	return $self->{ nodes }{ $node->{ id } } =  $node;
}



sub _unlink_nodes {
	my( $self, $deleted_nodes ) =  @_;

	my @ids =  map{ $_->{ id } } @$deleted_nodes;
	delete $self->{ nodes }->@{ @ids };

	return \@ids;
}



sub del_node {
	my( $self, $id ) =  @_;

	my $nodes =  $self->{ nodes };
	if( !$nodes->{ $id } ) {
		warn "No such node"   if $DEBUG;

		return [];
	}

	delete $self->{ _level }; #TODO: IT

	# Get link to the removing node
	my $sub_tree =  $nodes->{ $id };

	if( defined $sub_tree->{ parent_id } ) {
		# We are deleting child node. Unlink it from the parent
		my $parent_node =  $self->{ nodes }{ $sub_tree->{ parent_id } };
		$parent_node->{ children }->@* =  grep{
			$_->{ id } ne $id
		} $parent_node->{ children }->@*;
	}
	else {
		# We are deleting root node. Unlink it from the Tree::
		$self->root( undef );
	}

	# Traverse subtree to get all deleted nodes
	(my $deleted_nodes)->@* =
		map{ { $_->%{ @NODE_PROPERTIES } } } # Remove internal data from nodes
		(traverse{ $_ } $sub_tree)->@*;

	# Remove links from the tree to deleted children
	$self->_unlink_nodes( $deleted_nodes );


	return $deleted_nodes;
}



sub get_node {
	my( $self, $id ) =  @_;

	return $self->{ nodes }{ $id };
}



sub nodes_at_level {
	my( $self, $level ) =  @_;

	my $nodes;
	unless( $self->{ _level } ) {
		$nodes =  traverse {
			my( $node_level ) =  @_;

			push $self->{ _level }[ $node_level ]->@*, $_;

			return $_;
		} $self->root;
	}

	$nodes =  $self->{ _level }[ $level ]   if defined $level;

	# Remove internal data from nodes
	@$nodes =  map{ { $_->%{ @NODE_PROPERTIES } } } @$nodes;


	return $nodes;
}



sub save {
}



sub load {
}



package Tree::Node;



1;
