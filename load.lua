#!/usr/bin/env lua5.3

require 'luarocks.loader'
local sqltable = require 'sqltable'


local function allwords ( f )
	local line = f:read("*line")    -- current line
	local pos = 1             -- current position in the line
	return function ()        -- iterator function
		while line do           -- repeat while there are lines
			local s, e = string.find(line, "[%w%p]+", pos)
			if s then      -- found a word?
				pos = e + 1  -- update next position
				return string.sub(line, s, e)   -- return the word
			else
				line = f:read("*line")    -- word not found; try next line
				pos = 1             -- restart from first position
			end
		end
		return nil            -- no more lines: end of traversal
	end
end


assert(arg[1], "Provide corpus filename")
assert(arg[2], "Provide SQLite database filename")

local sql = sqltable.connect {
	type = 'SQLite3',
	name = arg[2]
}

local tokens = assert(sql:open_table
	{
		name = 'tokens',
		key = 'oken'
	})
	
local seq = assert(sql:open_table
	{
		name = 'token_sequence',
		key = 'id'
	})

local f = assert(io.open(arg[1], "r"))
local seen = {
	[''] = 1
}

local prev1 = ''
local prev2 = ''
local count = 0
for word in allwords(f) do
	if count % 100 == 0 then
		io.write('.')
		io.flush()
	end

	-- insert word, if needed
	if not seen[word] then
		tokens[ sql.next ] = { oken = word }
		seen[word] = tokens[ word ].id
	end
	
	-- insert token sequence
	seq[ sql.next ] = {
		prev_1 = seen[prev1],
		prev_2 = seen[prev2],
		next_id = seen[word]
	}
	
	-- step forward
	prev1 = prev2
	prev2 = word
	count = count + 1
end
f:close()
print("done")
