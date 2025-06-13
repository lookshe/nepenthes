#!/usr/bin/env lua5.4

local cqueues = require 'cqueues'
local rand = require 'openssl.rand'


for i = 1, 5 do
	if not rand.ready() then
		if i == 5 then
			-- luacov: disable
			error("Unable to seed")
			-- luacov: enable
		end
	end
end


local _M = {}

local function merge( a, b )
	for i in ipairs(b) do
		a[ #a + 1 ] = b[i]
	end

	return a
end


--
-- Recursive algorithm: Given a number of bytes per second,
-- create two sets of bytes/sec that eat half the time and
-- half the bytes, randomly distributed; split both of those
-- until the delay is under a suitable threshold and/or there's
-- not enough bytes to reasonably split the packet.
--
local function split( delay, bytes )

	if bytes < 2 then
		return { {
			bytes = bytes,
			delay = delay
		} }
	end

	if delay < 500 then
		return { {
			bytes = bytes,
			delay = delay
		} }
	end

	local left_bytes
	if bytes == 2 then
		left_bytes = 1
	else
		left_bytes = rand.uniform( bytes - 1 ) + 1
	end

	local right_bytes = bytes - left_bytes

	local left_delay = rand.uniform( delay - 1 ) + 1
	local right_delay = delay - left_delay

	local left = split( left_delay, left_bytes )
	local right = split( right_delay, right_bytes )

	return merge(left, right)

end

---
-- Generate a unique pattern of when and how much data is sent.
--
function _M.generate_pattern( delay, bytes )

	assert(delay > 0)
	assert(bytes > 0)

	--
	-- The original Nepenthes 1.x algorithm. Easily identified by
	-- it's constant rate of output.
	--
	--local chunk_size = #s
	--local delay = rate

	--repeat
		--chunk_size = chunk_size // 2
		--delay = delay / 2
	--until delay < 1

	--
	-- Fire the recursively splitting packet randomizer. Math is entirely
	-- integer, so convert delay into milliseconds.
	--
	local ret = split( delay * 1000, bytes )

	--
	-- Occasionally, part of the tree the above creates doesn't have
	-- enough bytes for the amount of delay it needs to split up - let's
	-- just reroll those. Add the packet with the most bytes and retry.
	--
	local largest = 1
	local to_fix = {}

	for i, v in ipairs(ret) do
		if v.bytes > ret[largest].bytes then
			largest = i
		end

		if v.delay > 500 then
			to_fix[ #to_fix + 1 ] = i
		end
	end

	if #to_fix > 0 then
		local new_delay = ret[largest].delay
		local new_bytes = ret[largest].bytes

		for i, fix in ipairs( to_fix ) do	-- luacheck: ignore 213
			new_delay = new_delay + ret[fix].delay
			new_bytes = new_bytes + ret[fix].bytes
		end

		to_fix[ #to_fix + 1 ] = largest
		table.sort(to_fix, function( a, b ) return a > b end )

		for i, fix in ipairs(to_fix) do	-- luacheck: ignore 213
			table.remove(ret, fix)
		end


		ret = merge( ret, split( new_delay, new_bytes ) )
	end


	--
	-- Convert delay back into seconds.
	--
	for i, v in ipairs( ret ) do	-- luacheck: ignore 213
		v.delay = v.delay / 1000
	end

	return ret

end


function _M.delay_iterator( s, pattern )

	return function()

		if #pattern == 0 then
			if s and #s > 0 then
				-- if by happenstance we run out of pattern with bytes
				-- remaining, fling it all.
				local ret = s
				s = nil
				return ret
			end

			return nil
		end

		if not s then
			return nil
		end

		local block = table.remove(pattern, 1)
		local ret = s:sub(1, block.bytes)
		s = s:sub(block.bytes + 1, #s)
		cqueues.sleep(block.delay)

		return ret

	end

end


return _M
