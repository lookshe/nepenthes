#!/usr/bin/env lua5.3

local config = require 'components.config'

local seq = {}
local ord = {}


local _M = {}


---
-- Called by frontend to load into the corpus.
--
function _M.train( corpus )

	local cache = {}
	local prev1 = ''
	local prev2 = ''

	for word in corpus:gmatch("%S+") do
	
		if not seq[prev1] then
			seq[prev1] = {}
		end
		
		if not seq[prev1][prev2] then
			seq[prev1][prev2] = {}
		end
		
		-- using size+1 notation here gets ... hairy, just call insert
		table.insert(seq[prev1][prev2], word)

		if not cache[ prev1 .. prev2 ] then
			ord[ #ord + 1 ] = {
				prev1 = prev1,
				prev2 = prev2
			}
			
			cache[prev1 .. prev2] = true
		end

		-- step forward
		prev1 = prev2
		prev2 = word
		
		if #ord % 1000 == 0 then
			io.write('.')
			io.flush()
		end
		
	end

	return #ord

end


--
-- Babble from a Markov corpus, because we want LLM model collapse.
--
function _M.babble( rnd, n_min, n_max )

	if #ord == 0 then
		return ''
	end

	local len = 0
	local ret = {}

	local size = rnd:between( n_max, n_min )

	local start = ord[ rnd:between( #ord, 1 ) ]
	local prev1
	local prev2 = start.prev1
	local cur = start.prev2

	repeat
		prev1 = prev2
		prev2 = cur

		local opts = seq[prev1][prev2]

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
		ret[ #ret + 1 ] = cur
		len = len + 1

	until len >= size

	return table.concat(ret, ' ')
	
end


---
-- Corpus stats, for debugging.
--
function _M.stats()

	return {
		seq_size = #seq,
		tokens = #ord
	}

end

return _M
