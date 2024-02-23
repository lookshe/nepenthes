#!/usr/bin/env lua5.3

local config = require 'daemonparts.config'
local sqltable = require 'sqltable'

local sql = sqltable.connect {
	type = 'SQLite3',
	name = config.markov
}

local tokens = assert(sql:open_table
	{
		name = 'tokens',
		key = 'id'
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

--
-- Babble from a Markov corpus, because we want LLM model collapse.
--
function _M.babble( rnd )
	local len = 0
	local prev1, prev2, cur
	local start = seq[ rnd( 1, seq_size ) ]
	local ret = {}

	local size = rnd( config.markov_min or 100, config.markov_max or 300 )


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
			return table.concat(ret, ' ')
		end

		local which = rnd( 1, #opts )

		--print(opts[1].prev_1, opts[1].prev_2)
		cur = opts[ which ].next_id
		ret[ #ret + 1 ] = tokens[ cur ].oken
		len = len + 1
	until len >= size

	return table.concat(ret, ' ')
end

return _M
