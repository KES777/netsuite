package Tree;

use strict;
use warnings;

use Scalar::Util 'blessed';



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
			$self->add_node( $node );
		}
	}
}



sub root {
	my $self =  shift;

	return $self->{ root } =  shift   if @_;

	return $self->{ root };
}



sub add_node {
	my( $self, $node ) =  @_;

	$node->{ id }  //
		die "Node should have ID";

	$node->{ parent_id }  &&  $node->{ id } == $node->{ parent_id }  and
		die "Node can not refer to itself";

	exists $self->{ nodes }{ $node->{ id } }  and
		die "Node with specified ID already in the Tree::";


	if( $self->root ) {
		$node->{ parent_id }  //
			die "Tree:: can contain only one root node";
	}
	else {
		$node->{ parent_id }  and
			die "Root node can not have parent";

		$self->root( $node );
	}

	$self->{ nodes }{ $node->{ id } } =  $node;
}



sub del_node {

}



sub save {
}



sub load {
}



package Tree::Node;



1;
