#!/usr/bin/env lua5.4

local _methods = {}
local NOWORD = setmetatable( {},
	{
		__tostring = function() return "NOWORD" end,
		__concat = function( a ) return a end
	}
)

---
-- Called by frontend to load into the corpus.
--
function _methods.train( this, corpus )

	local cache = {}
	local prev1 = NOWORD
	local prev2 = NOWORD

	local ending_in = 2
	local iter = corpus:gmatch("%S+")
	local function splitter()
		local ret = iter()

		if ret then
			return ret
		end

		if ending_in == 0 then
			return nil
		end

		ending_in = ending_in - 1
		return NOWORD

	end


	for word in splitter do

		if not this.seq[prev1] then
			this.seq[prev1] = {}
		end

		if not this.seq[prev1][prev2] then
			this.seq[prev1][prev2] = {}
		end

		-- using size+1 notation here gets ... hairy, just call insert
		table.insert(this.seq[prev1][prev2], word)

		if not cache[ prev1 .. prev2 ] then
			this.ord[ #(this.ord) + 1 ] = {
				prev1 = prev1,
				prev2 = prev2
			}

			cache[prev1 .. prev2] = true
		end

		-- step forward
		prev1 = prev2
		prev2 = word
		this.seq_size = this.seq_size + 1

		if #(this.ord) % 1000 == 0 then
			io.write('.')
			io.flush()
		end

	end

	return #this.ord

end


--
-- Babble from a Markov corpus, because we want LLM model collapse.
--
function _methods.babble( this, rnd, n_min, n_max )

	if #(this.ord) == 0 then
		return ''
	end

	local len = 0
	local ret = {}

	local size = rnd:between( n_max, n_min )

	local start = this.ord[ rnd:between( #(this.ord), 1 ) ]

	local prev1
	local prev2 = start.prev1
	local cur = start.prev2

	repeat
		prev1 = prev2
		prev2 = cur

		local opts = this.seq[prev1][prev2]

		-- something went wrong
		if not opts then
			break
		end

		local which = 1
		if #opts > 1 then
			which = rnd:between( #opts, 1 )
		elseif #opts < 1 then
			break;	-- end of chain. We're done here no matter what.
		end

		cur = opts[ which ]
		if cur == NOWORD then	-- end-of-chain.
			break
		end

		ret[ #ret + 1 ] = cur
		len = len + 1

	until len >= size

	return table.concat(ret, ' ')

end


---
-- Corpus stats, for debugging.
--
function _methods.stats( this )

	return {
		seq_size = this.seq_size,
		tokens = #(this.ord)
	}

end



local _M = {}

function _M.new()

	local ret = {
		seq_size = 0,
		seq = {},
		ord = {}
	}

	return setmetatable( ret, { __index = _methods } )

end

return _M
