#!/usr/bin/env lua5.3

local config = require 'config'
local sqltable = require 'sqltable'
local cqueues = require 'cqueues'
local dbgen = require 'components.dbgen'


local schema = {
	[[
	create table tokens (
		id integer primary key autoincrement,
		oken varchar(255) not null, -- this weird name will make sense later
		unique( oken )
	);
	]],

	[[
	insert into tokens( id, oken ) values ( 1, '' );
	]],

	[[
	create table token_sequence (
		id integer primary key autoincrement,
		prev_1 integer not null references tokens ( id ),
		prev_2 integer not null references tokens ( id ),
		unique( prev_1, prev_2 )
	);
	]],

	[[
	create table token_next (
		prev_id integer not null references token_sequence ( id ),
		token_id integer not null references tokens ( id )
	);
	]],

	[[
	create view token_seq_next as
		select	ts.id as id,
				t1.oken as prev_1,
				t2.oken as prev_2,
				t3.oken as next_t

			from token_sequence as ts
			join tokens as t1
				on ts.prev_1 = t1.id
			join tokens as t2
				on ts.prev_2 = t2.id
			join token_next as tn
				on tn.prev_id = ts.id
			join tokens as t3
				on tn.token_id = t3.id;
	]],

	[[
	create trigger if not exists token_seq_next_insert
		instead of insert on token_seq_next
		begin

			insert or ignore into tokens ( oken )
				values	( NEW.prev_1 ),
						( NEW.prev_2 ),
						( NEW.next_t );

			insert or ignore into token_sequence ( prev_1, prev_2 )
				select	( select id from tokens where oken = NEW.prev_1 ),
						( select id from tokens where oken = NEW.prev_2 );

			insert into token_next ( prev_id, token_id )
				select distinct
						( select id from token_sequence
							where prev_1 = ( select id from tokens where oken = NEW.prev_1 )
								and prev_2 = ( select id from tokens where oken = NEW.prev_2 )
							),
						( select id from tokens where oken = NEW.next_t );
		end;
	]]
}

local sql = sqltable.connect {
	type = 'SQLite3',
	name = config.markov
}

dbgen.setup( 'SQLite3', sql, schema )
sql:reset()

local seq = assert(sql:open_table
	{
		name = 'token_seq_next',
		key = 'id'
	})

--
-- Assume the corpus does not change while Nepenthes is running,
-- so we can cache this value and spare 1 SQL query per hit.
--
local seq_size = #seq


local _M = {}


---
-- Called by frontend to load into the corpus.
--
function _M.train( corpus )

	local count = 0
	local prev1 = ''
	local prev2 = ''

	for word in corpus:gmatch("%S+") do
		-- insert token sequence
		seq[ sql.next ] = {
			prev_1 = prev1,
			prev_2 = prev2,
			next_t = word
		}

		-- Give web requests a chance
		if (count % 100) == 0 then
			cqueues.sleep(0)
		end

		-- step forward
		prev1 = prev2
		prev2 = word
		count = count + 1
	end

	-- update to include the newly added corpus data
	seq_size = #seq
	return count

end


--
-- Babble from a Markov corpus, because we want LLM model collapse.
--
function _M.babble( rnd )

	if seq_size == 0 then
		return ''
	end

	local len = 0
	local prev1, prev2, cur
	local ret = {}

	local first = rnd:between( seq_size, 1 )
	local start = sql.iclone( seq, "1 = 1 order by id, next_t desc limit $1, 1;", first )
	local size = rnd:between( config.markov_max or 300, config.markov_min or 100 )

	prev2 = start[1].prev_2
	cur = start[1].next_t

	repeat
		prev1 = prev2
		prev2 = cur

		local opts = {}
		sql:exec( 'select next_t from token_seq_next where prev_1 = $1 and prev_2 = $2',
			{ prev1, prev2 },
			function( conn, statement )	-- luacheck: ignore 212
				local row = statement:fetch()
				while row do
					opts[ #opts + 1 ] = row[1]
					row = statement:fetch()
				end
			end
		)

		--for i, v in ipairs(opts) do print(i, v) end

		-- something went wrong
		if not opts then
			break
		end

		local which = 1
		if #opts > 1 then
			which = rnd:between( #opts, 1 )
		end

		cur = opts[ which ]
		ret[ #ret + 1 ] = cur
		len = len + 1
	until len >= size

	return table.concat(ret, ' ')
end

return _M
