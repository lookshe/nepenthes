#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local rng_factory = require 'components.rng'
local wordlist = require 'components.wordlist'
local urlgen = require 'components.urlgen'


require 'busted.runner'()
describe("URL Generator Module", function()

	local ug

	setup(function()
		local wl = wordlist.new('./tests/share/words.txt')
		ug = urlgen.new( wl )
	end)


	it("Generates a URL", function()

		local rng = rng_factory.new( 'anything', '/just/some/whatever/url' )

		assert.is_equal('/sibyl', ug:create( rng ))
		assert.is_equal('/shoring/rewinds/yourself', ug:create( rng ))
		assert.is_equal('/fascists/insetting', ug:create( rng ))
		assert.is_equal('/freebased/internment/dearths/crankcase', ug:create( rng ))

	end)


	it("Identifies a valid URL", function()
		pending("To be written")
	end)


	it("Detects Bogons", function()
		pending("To be written")
	end)

end)
