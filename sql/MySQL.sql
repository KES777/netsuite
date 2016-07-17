create table trees (
	id integer unsigned not null auto_increment primary key,
	tree_id integer not null,
	parent_id integer
);
