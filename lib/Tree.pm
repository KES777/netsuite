package Tree;

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
}



sub add_node {

}



sub del_node {

}



sub save {
}



sub load {
}



1;
