#!/usr/bin/env lua5.4

---
-- Simple direct one-to-one line rewrite of the xoshiro128* generator
-- into a pure Lua, reentrant module.
--
-- This is the same algorithm used by Lua itself; however Nepenthes
-- requires multiple independent generator states to function correctly,
-- Thus this interpretation.
--
-- It is very possible it is not entirely correct, due to semantics of
-- Lua and C being very different. However it appears to work well enough
-- (so far) for Nepenthes' purposes.
--
-- For the original algorithm, see: https://prng.di.unimi.it/
--


local _methods = {}

local function rotl( x, k )

	return (x << k) | (x >> (32 - k))

end

function _methods.random( s )

	local result = rotl(  s[1]
						+ s[2]
						+ s[3]
						+ s[4],
					7) + s[1]

	local t = s[2] << 9

	s[3] = s[3] ~ s[1]
	s[4] = s[4] ~ s[2]
	s[2] = s[2] ~ s[3]
	s[1] = s[1] ~ s[4]

	s[2] = s[2] ~ t

	s[4] = rotl(s[4], 11)

	return result

end

function _methods.reseed( s, a, b, c, d )

	s[1] = a
	s[2] = b
	s[3] = c
	s[4] = d

end


function _methods.between( s, upper, lower )

	if (upper - lower) <= 0 then
		error("Requested random value range invalid")
	end

	return ((s:random() % (1 + upper - lower)) + lower)

end


local _M = {}

function _M.new( a, b, c, d )

	local s = { a, b, c, d }
	return setmetatable( s, { __index = _methods } )

end

return _M
