#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local wordlist = require 'components.wordlist'
local rng_factory = require 'components.rng'


require 'busted.runner'()
describe("Word List / Dictionary Module", function()

	local wl

	setup(function()
		wl = wordlist.new('/usr/share/dict/words')
	end)

	it("Loads", function()
		assert.is_table(wl)
		assert.is_function(wl.count)
		assert.is_function(wl.choose)
		assert.is_function(wl.lookup)

		--
		-- NetBSD 9.1 is 235972 entries, Debian 11 is 102774.
		-- So more than 10,000 should be fine, right? Right?
		--
		assert.is_true( wl.count() > 10000 )
	end)


	it("Rejects missing file", function()
		assert.is_error(function()
			wordlist.new('./does-not-exist-ejkfn23jrn23jrn23jrtn32jnrj33')
		end)

		assert.is_error(function()
			wordlist.new('/dev/null')
		end)
	end)

	it("Verifies", function()

		--
		-- XXX: I'm assuming English/UTF-8
		--
		assert.is_true( wl.lookup( 'this' ) )
		assert.is_true( wl.lookup( 'and' ) )
		assert.is_true( wl.lookup( 'left' ) )

		assert.is_false( wl.lookup( 'snaaerf34mr443' ) )
		assert.is_false( wl.lookup( '65156415641515' ) )
		assert.is_false( wl.lookup( '' ) )
		assert.is_false( wl.lookup( true ) )
		assert.is_false( wl.lookup( function() end ) )

	end)

	it("Selects", function()

		local rng = rng_factory.new( 'anything', '/just/some/whatever/url' )

		local words = {}

		for i = 1, 5 do	-- luacheck: ignore 213
			local word = wl.choose( rng )
			assert.is_string(word)
			assert.is_true(#word > 2)
			assert.is_true( wl.lookup( word ) )
			assert.is_nil( words[word] )
			words[ word ] = true
		end

	end)

end)
