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



local _M = {}

function _M.new( wordlist )
	local ret = {
		wordlist = wordlist
	}

	return setmetatable(
		ret, { __index = _methods }
	)
end

return _M
