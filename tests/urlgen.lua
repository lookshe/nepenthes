#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

--
-- Monkey patch this to make it identical from test run to test run.
--
local seed = require 'components.seed'
seed.get = function()
	return 'anything'
end

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
		local rng = rng_factory.new( '/just/some/whatever/url' )

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

		local ug = urlgen.new( wl, { '/default' } )
		local rng = rng_factory.new( '/just/some/whatever/url' )

		assert.is_equal('/default/sibyl', ug:create( rng ))
		assert.is_equal('/default/shoring/rewinds/yourself', ug:create( rng ))
		assert.is_equal('/default/fascists/insetting', ug:create( rng ))
		assert.is_equal('/default/freebased/internment/dearths/crankcase', ug:create( rng ))

	end)


	it("Generates URLs with a default prefix, when multiple", function()

		local ug = urlgen.new( wl, { '/default', 'someplace' } )
		local rng = rng_factory.new( '/just/some/whatever/url' )

		assert.is_equal('/default/sibyl', ug:create( rng ))
		assert.is_equal('/default/shoring/rewinds/yourself', ug:create( rng ))
		assert.is_equal('/default/fascists/insetting', ug:create( rng ))
		assert.is_equal('/default/freebased/internment/dearths/crankcase', ug:create( rng ))

	end)


	it("Generates URLs with a requested prefix", function()

		local ug = urlgen.new( wl, { '/default', 'someplace' } )
		local rng = rng_factory.new( '/just/some/whatever/url' )

		assert.is_equal('/default/sibyl', ug:create( rng ))
		assert.is_equal('/default/shoring/rewinds/yourself', ug:create( rng ))
		assert.is_equal('/default/fascists/insetting', ug:create( rng ))
		assert.is_equal('/default/freebased/internment/dearths/crankcase', ug:create( rng ))

		local rng2 = rng_factory.new( '/just/some/whatever/url' )
		assert.is_equal('/someplace/sibyl', ug:create( rng2, 'someplace' ))
		assert.is_equal('/someplace/shoring/rewinds/yourself', ug:create( rng2, '/someplace' ))
		assert.is_equal('/someplace/fascists/insetting', ug:create( rng2, 'someplace' ))
		assert.is_equal('/someplace/freebased/internment/dearths/crankcase', ug:create( rng2, '/someplace' ))

		-- default if unknown (instead of error)

		local rng3 = rng_factory.new( '/just/some/whatever/url' )
		assert.is_equal('/default/sibyl', ug:create( rng3, 'otherplace' ))
		assert.is_equal('/default/shoring/rewinds/yourself', ug:create( rng3, 'notconfigured' ))
		assert.is_equal('/default/fascists/insetting', ug:create( rng3, '/notconfigured' ))
		assert.is_equal('/default/freebased/internment/dearths/crankcase', ug:create( rng3, '/otherplace' ))

	end)


	it("Strips a configured prefix during checks", function()

		local ug = urlgen.new( wl, { '/testprefix' })

		assert.is_false( ug:check('/testprefix/sibyl') )
		assert.is_false( ug:check('/testprefix/shoring/rewinds/yourself') )

		assert.is_true( ug:check('/non-existant-path') )
		assert.is_true( ug:check('/defjwejfne4/3krnjk2/egnmi34t/erge8wjt4') )

		assert.is_true( ug:check('/testprefix/non-existant-path') )
		assert.is_true( ug:check('/testprefix/defjwejfne4/3krnjk2/egnmi34t/erge8wjt4') )

	end)

	it("Strips multiple configured prefixes during checks", function()

		local ug = urlgen.new( wl, { '/testprefix', '/secondprefix' })

		assert.is_false( ug:check('/testprefix/sibyl') )
		assert.is_false( ug:check('/testprefix/shoring/rewinds/yourself') )

		assert.is_false( ug:check('/secondprefix/sibyl') )
		assert.is_false( ug:check('/secondprefix/shoring/rewinds/yourself') )

		assert.is_true( ug:check('/non-existant-path') )
		assert.is_true( ug:check('/defjwejfne4/3krnjk2/egnmi34t/erge8wjt4') )

		assert.is_true( ug:check('/testprefix/non-existant-path') )
		assert.is_true( ug:check('/testprefix/defjwejfne4/3krnjk2/egnmi34t/erge8wjt4') )

		assert.is_true( ug:check('/secondprefix/non-existant-path') )
		assert.is_true( ug:check('/secondprefix/defjwejfne4/3krnjk2/egnmi34t/erge8wjt4') )

		assert.is_true( ug:check('/testprefix2/non-existant-path') )
		assert.is_true( ug:check('/testprefix2/defjwejfne4/3krnjk2/egnmi34t/erge8wjt4') )

	end)

	it("Prefix must the first thing to not Bogon out", function()

		local ug = urlgen.new( wl, { '/testprefix', '/secondprefix' })

		assert.is_true( ug:check('/sibyl/testprefix') )
		assert.is_true( ug:check('/shoring/rewinds/testprefix/yourself') )

	end)

	it("Notifies what the prefix is", function()

		local ug = urlgen.new( wl, { '/testprefix', '/secondprefix' })

		local req1, pre1 = ug:check('/sibyl')
		assert.is_nil(pre1)
		assert.is_false(req1)

		local req2, pre2 = ug:check('/shoring/rewinds/yourself')
		assert.is_nil(pre2)
		assert.is_false(req2)

		local req3, pre3 = ug:check('/testprefix/sibyl')
		assert.is_equal('testprefix', pre3)
		assert.is_false(req3)

		local req4, pre4 = ug:check('/testprefix/shoring/rewinds/yourself')
		assert.is_equal('testprefix', pre4)
		assert.is_false(req4)

		local req5, pre5 = ug:check('/secondprefix/sibyl')
		assert.is_equal('secondprefix', pre5)
		assert.is_false(req5)

		local req6, pre6 = ug:check('/secondprefix/shoring/rewinds/yourself')
		assert.is_equal('secondprefix', pre6)
		assert.is_false(req6)

		local req7, pre7 = ug:check('/non-existant-path')
		assert.is_nil(pre7)
		assert.is_true(req7)

		local req8, pre8 = ug:check('/defjwejfne4/3krnjk2/egnmi34t/erge8wjt4')
		assert.is_nil(pre8)
		assert.is_true(req8)

	end)

end)
