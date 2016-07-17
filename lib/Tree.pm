package Tree;

use v5.24;
use strict;
use warnings;

use Scalar::Util 'blessed';
use feature 'current_sub';

use Exporter 'import';
our @EXPORT_OK =  qw/ traverse /;



our $DEBUG;


sub traverse(&@) {
	my( $code, $self, $curr_node, $level ) =  @_;

	$curr_node  //
		die "Starting node should be supplied to traverse the Tree::";

	$level //=  0;

	my $result =  [];

	local $_ =  $curr_node;
	push @$result, $self->$code( $level ); # Call $code in context of $self

	for my $next_node ( $curr_node->{ children }->@* ) {
		push @$result,
			__SUB__->( $code, $self, $next_node , $level +1 )->@*;
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
		if( !exists $self->{ nodes }{ $node->{ parent_id } } ) {
			die "No such parent in the Tree::"   unless $allow_orphan;

			push $self->{ broken }{ $node->{ parent_id } }->@*, $node;
		}
	}
	else {
		$self->root( $node );
	}


	return $self->{ nodes }{ $node->{ id } } =  $node;
}



sub del_node {
	my( $self, $id ) =  @_;

	my $nodes =  $self->{ nodes };
	if( !$nodes->{ $id } ) {
		warn "No such node"   if $DEBUG;

		return [];
	}


	$nodes->{ $id }{ parent_id }  //  $self->root( undef );
	my $deleted_nodes =  [ delete $nodes->{ $id } ];

	# Delete all branches and leaves of deleted node
	for my $node_id ( keys $nodes->%* ) {
		my $node =  $nodes->{ $node_id };

		next   unless $node;         # Node was deleted by recursive call

		next   unless                         # Skip delatoin for ...
			$node->{ parent_id  }             # ...root node
			&&  $node->{ parent_id } eq $id;  # ...not children nodes

		push @$deleted_nodes, $self->del_node( $node_id )->@*;
	}


	return $deleted_nodes;
}



sub get_node {
	my( $self, $id ) =  @_;

	return $self->{ nodes }{ $id };
}


sub save {
}



sub load {
}



package Tree::Node;



1;
