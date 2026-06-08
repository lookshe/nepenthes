#!/usr/bin/env lua5.4


local _M = {}

function _M.new( file )

	local f <close> = assert( io.open( file, "r" ) )

	local dict = {}
	local dict_lookup = {}

	for line in f:lines() do
		if not line:match("%'") then
			--
			-- Gracefully cleanup CRLF terminated lines.
			--
			if line:sub( #line ):match('%s') then
				line = line:sub(1, #line - 1)
			end

			dict[ #dict + 1 ] = line
			dict_lookup[ line ] = true
		end
	end

	if #dict <= 2 then
		-- this is probably not a usable wordlist file.
		error("Wordlist failed to load - check file type?")
	end

	return {
		count = function()
			return #(dict)
		end,

		choose = function( rnd )
			return dict[ rnd:between( #dict, 1 ) ]
		end,

		lookup = function( word )

			if dict_lookup[ word ] then
				return true
			end

			return false

		end
	}

end

return _M
