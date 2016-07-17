package Tree::MySQL;

#TODO: inherit from Tree::Storage::
use parent 'Tree';
use DBI;

my $DBH =  DBI->connect( 'dbi:mysql:test', test => '123456', {()
	,AutoCommit =>  0
});



sub new {
	$self    =  shift;
	$tree_id =  pop;

	$self =  $self->SUPER::new( @_ );
	$self->{ tree_id } =  $tree_id;
	$self->{ dbh } =  DBI->connect( 'dbi:mysql:test', test => '123456', {()
		,AutoCommit =>  0
	});

	return $self;
}


sub load {
	my( $class, $tree_id ) =  @_;

	my $nodes =  $DBH->selectall_arrayref(()
		#TODO: fetch root first
		,'select id, parent_id from trees where tree_id = ?'
		, undef
		, $tree_id
	);

	@$nodes =  map{
		my $h;
		$h->@{ qw/ id parent_id / } =  $_->@[ 0, 1 ];
		$h;
	}  @$nodes;

	my $tree =  Tree::MySQL::->new( $nodes, $tree_id );


	return $tree;
}



sub save {
	my( $self ) =  @_;

	#FIX: query DB for new tree_id
	$self->{ tree_id } //=  1;
	my @nodes;
	@$nodes =  map{
		$_->{ tree_id } =  $self->{ tree_id };
		[ @$_{ qw/ id tree_id parent_id / } ];
	} $self->nodes_at_level->@*;

	# print pp $self->nodes_at_level;

	my $sth =  $self->{ dbh }->prepare( '
		INSERT INTO trees ( id, tree_id, parent_id ) VALUES( ?, ?, ? )
		ON DUPLICATE KEY UPDATE
			id = VALUES( id ),
			tree_id = VALUES( tree_id ),
			parent_id = VALUES( parent_id )
	' );

	#TODO: process errors
	$sth->execute_array({ ArrayTupleFetch =>  sub{ shift @$nodes } });
	$self->{ dbh }->commit;
}



sub _unlink_nodes {
	my $self =  shift;

	my $ids =  $self->SUPER::_unlink_nodes( @_ );
	my $sth =  $self->{ dbh }->prepare('DELETE FROM trees WHERE id = ?');
	(my $rows)->@* =  map{ [ $_ ] } @$ids; # Each tuple should be arrayref
	$sth->execute_array({ ArrayTupleFetch =>  sub{ shift @$rows } });

	return $ids;
}


sub del_node {
	my $self =  shift;

	my $deleted_nodes =  $self->SUPER::del_node( @_ );

	return $deleted_nodes;
}

1;
