PRAGMA journal_mode = wal;
PRAGMA wal_autocheckpoint(100);

create table tokens (
	id integer primary key autoincrement,
	oken varchar(255) not null, -- this weird name will make sense later
	unique( oken )
);

insert into tokens( id, oken ) values ( 1, '' );

create table token_sequence (
	id integer primary key autoincrement,
	prev_1 integer not null references tokens ( id ),
	prev_2 integer not null references tokens ( id ),
	next_id integer not null references tokens ( id )
);

create index seq on token_sequence ( prev_1, prev_2 );
