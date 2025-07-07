#!/usr/bin/env lua5.4

local _methods = {}


function _methods.create( this, rng )
	local size = rng:between( 5, 1 )
	local parts = {}

	for i = 1, size do
		parts[ i ] = this.wordlist.choose( rng )
	end

	return '/' .. table.concat(parts, "/")
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

		if this.prefix then
			url = url:sub( #(this.prefix) + 1 )
		end

		local is_bogon = false
		for word in url:gmatch('/([^/]+)') do
			if not this.wordlist.lookup( word ) then
				is_bogon = true
			end
		end

		return is_bogon

end


local _M = {}

function _M.new( wordlist, prefix )
	local ret = {
		wordlist = wordlist,
		prefix = prefix
	}

	return setmetatable(
		ret, { __index = _methods }
	)
end

return _M
