#!/usr/bin/env lua5.3

local config = require 'config'
local sqltable = require 'sqltable'
local cqueues = require 'cqueues'
local dbgen = require 'components.dbgen'


local schema = {
	--[[
	--PRAGMA journal_mode = wal;
	--]]

	--[[
	--PRAGMA wal_autocheckpoint(100);
	--]]

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
		next_id integer not null references tokens ( id )
	);
	]],

	[[
	create index seq on token_sequence ( prev_1, prev_2 );
	]]
}

local sql = sqltable.connect {
	type = 'SQLite3',
	name = config.markov
}

dbgen.setup( 'SQLite3', sql, schema )
sql:reset()

local tokens = assert(sql:open_table
	{
		name = 'tokens',
		key = 'id'
	})

local load_tokens = assert(sql:open_table
	{
		name = 'tokens',
		key = 'oken'
	})

local seq = assert(sql:open_table
	{
		name = 'token_sequence',
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

	-- cache of seen words by ID.
	local seen = {
		[''] = 1
	}

	local count = 0
	local prev1 = ''
	local prev2 = ''

	for word in corpus:gmatch("%S+") do
		-- insert word, if needed
		if not seen[word] then
			local ct = load_tokens[ word ]

			if not ct then
				load_tokens[ sql.next ] = { oken = word }
				ct = load_tokens[ word ]
			end

			seen[word] = ct.id
		end

		-- insert token sequence
		seq[ sql.next ] = {
			prev_1 = seen[prev1],
			prev_2 = seen[prev2],
			next_id = seen[word]
		}

		-- Give web requests a chance
		cqueues.sleep(0)

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
	local start = seq[ rnd( 1, seq_size ) ]
	local ret = {}

	local size = rnd( config.markov_min or 100, config.markov_max or 300 )

	--local stime = os.clock()

	prev2 = start.prev_2
	cur = start.next_id

	repeat
		prev1 = prev2
		prev2 = cur

		local opts = sql.iclone( seq, 'prev_1 = $1 and prev_2 = $2',
			prev1, prev2
		)

		-- something went wrong
		if not opts then
			break
		end

		local which = rnd( 1, #opts )

		cur = opts[ which ].next_id
		ret[ #ret + 1 ] = tokens[ cur ].oken
		len = len + 1
	until len >= size

	--::terminate::
	--local etime = os.clock()

	return table.concat(ret, ' ')
end

return _M
