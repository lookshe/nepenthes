#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local rng_factory = require 'components.rng'
local wordlist = require 'components.wordlist'
local urlgen = require 'components.urlgen'


require 'busted.runner'()
describe("URL Generator Module", function()

	local wl

	setup(function()
		wl = wordlist.new('./tests/share/words.txt')
	end)


	it("Generates a URL", function()

		local ug = urlgen.new( wl )
		local rng = rng_factory.new( 'anything', '/just/some/whatever/url' )

		assert.is_equal('/sibyl', ug:create( rng ))
		assert.is_equal('/shoring/rewinds/yourself', ug:create( rng ))
		assert.is_equal('/fascists/insetting', ug:create( rng ))
		assert.is_equal('/freebased/internment/dearths/crankcase', ug:create( rng ))

	end)


	it("Identifies a valid URL", function()

		local ug = urlgen.new( wl )

		assert.is_false( ug:check('/sibyl') )
		assert.is_false( ug:check('/shoring/rewinds/yourself') )
		assert.is_false( ug:check('/fascists/insetting') )
		assert.is_false( ug:check('/freebased/internment/dearths/crankcase') )

		assert.is_true( ug:check('/non-existant-path') )
		assert.is_true( ug:check('/defjwejfne4/3krnjk2/egnmi34t/erge8wjt4') )
		assert.is_true( ug:check('/sibyl/but/wrong') )
		assert.is_true( ug:check('/catalogers/drachma/death/posterity') )

	end)


	it("Generates URLs with proper prefix", function()

		local ug = urlgen.new( wl, '/default' )
		local rng = rng_factory.new( 'anything', '/just/some/whatever/url' )

		assert.is_equal('/default/sibyl', ug:create( rng ))
		assert.is_equal('/default/shoring/rewinds/yourself', ug:create( rng ))
		assert.is_equal('/default/fascists/insetting', ug:create( rng ))
		assert.is_equal('/default/freebased/internment/dearths/crankcase', ug:create( rng ))

	end)


	it("Strips a configured prefix during checks", function()

		local ug = urlgen.new( wl, '/testprefix' )

		assert.is_false( ug:check('/testprefix/sibyl') )
		assert.is_false( ug:check('/testprefix/shoring/rewinds/yourself') )

		assert.is_true( ug:check('/non-existant-path') )
		assert.is_true( ug:check('/defjwejfne4/3krnjk2/egnmi34t/erge8wjt4') )

		assert.is_true( ug:check('/testprefix/non-existant-path') )
		assert.is_true( ug:check('/testprefix/defjwejfne4/3krnjk2/egnmi34t/erge8wjt4') )

	end)

end)
