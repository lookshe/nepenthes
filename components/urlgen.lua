#!/usr/bin/env lua5.4

local _methods = {}


function _methods.create( this, rng )

	local size = rng:between( 5, 1 )
	local parts = {}


	for i = 1, size do
		parts[ i ] = this.wordlist.choose( rng )
	end

	if this.prefix then
		table.insert(parts, 1, this.prefix)
	end

	return '/' .. table.concat(parts, '/')

end

---
-- URL Bogon detection.
--
-- I would like to thank the Slashdot commenter for his very
-- clever idea for detecting tarpits. It's quite clever, I'll
-- admit. It's also easy to defeat, which we do here.
--
-- Since the URLs are built from a known dictionary, it's not
-- hard to sanity check them. If a crawler deliberately munges a
-- URL to force the tarpit to reveal itself, depending on how it
-- does so, there's a very good chance the result will be a 404
-- as expected from a real site.
--
function _methods.check( this, url )

	local is_bogon = false
	local count = 1

	for word in url:gmatch('/([^/]+)') do
		if count == 1 and this.prefix then
			if word ~= this.prefix then
				is_bogon = true
				break
			end
		else
			if not this.wordlist.lookup( word ) then
				is_bogon = true
				break
			end
		end

		count = count + 1
	end

	return is_bogon

end


local _M = {}

function _M.new( wordlist, prefix )

	assert(wordlist, "Wordlist not provided")

	--
	-- Normalize the leading slash to simplify the rest of this module.
	--
	if prefix then
		if prefix == '/' then
			prefix = ""
		end

		if prefix:sub(1, 1) == '/' then
			prefix = prefix:sub(2, -1)
		end

		if prefix == '' then
			prefix = nil
		end
	end

	local ret = {
		wordlist = wordlist,
		prefix = prefix
	}

	return setmetatable(
		ret, { __index = _methods }
	)

end

return _M
