#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local config = require 'components.config'
config.words = './tests/share/words.txt'
config.markov_corpus = './tests/share/wiki-markov.txt'


--
-- Monkey patch this to make it identical from test run to test run.
--
local seed = require 'components.seed'
seed.get = function()
	return 'ec708cffc8c154521ced80639449576ff8bd356060eeb20aecfc76e45ec80bbc'
end

local markov = require 'components.markov'
local request = require 'components.request'


require 'busted.runner'()
describe("Request Processor Module", function()

	local mk

	setup(function()
		mk = markov.new()
		mk:train_file( './tests/share/wiki-markov.txt' )
	end)


	it("Checks for Bogons", function()

		local req = request.new( '/', '/not-a-valid-url-3458j2345t3m24rk34' )

		assert.is_table(req)
		assert.is_true(req:is_bogon())


		local req2 = request.new( '/', '/some/where/else' )

		assert.is_table(req2)
		assert.is_true(req2:is_bogon())


		local req3 = request.new( '/maze', '/maze/some/where/else' )

		assert.is_table(req3)
		assert.is_true(req3:is_bogon())

	end)


	it("Passes valid URLs", function()

		local req = request.new( '/', '/catastrophic' )

		assert.is_table(req)
		assert.is_false(req:is_bogon())


		local req2 = request.new( '/', '/Dayton/fin/stabilizer' )

		assert.is_table(req2)
		assert.is_false(req2:is_bogon())


		local req3 = request.new( '/maze', '/maze/fermentation/Leicester/photon' )

		assert.is_table(req3)
		assert.is_false(req3:is_bogon())

	end)


	it("Generates list of given URLs in a page", function()

		local req = request.new( '/', '/catastrophic' )
		local urls = req:urllist()

		assert.is_table( urls )
		assert.is_equal( 8, #urls )

		assert.is_equal('/catalogers/Wise', urls[1].link)
		assert.is_equal('/rewinds/Paracelsus/tendinitis', urls[2].link)
		assert.is_equal('/Victorville/estrangement/tapioca/catastrophic/inapt', urls[3].link)
		assert.is_equal('/photon/Shea/isolationists/exit', urls[4].link)
		assert.is_equal('/succinctness/Houyhnhnm/muckraked', urls[5].link)
		assert.is_equal('/catalogers/unmarked/begs/daybreak/ruminations', urls[6].link)
		assert.is_equal('/servant', urls[7].link)
		assert.is_equal('/Huff/ruminations/chilis', urls[8].link)

	end)


	it("Loads Markov", function()

		local req = request.new( '/', '/catastrophic' )

		assert.is_table(req.vars)
		assert.is_nil(req.vars.title)
		assert.is_nil(req.vars.header)
		assert.is_nil(req.vars.content)

		req:load_markov( mk )

		assert.is_table(req.vars)
		assert.is_string(req.vars.title)
		assert.is_equal('has either a discrete index set (often', req.vars.title)
		assert.is_string(req.vars.header)
		assert.is_equal('the state of the Russian mathematician Andrey', req.vars.header)
		assert.is_string(req.vars.content)
		assert.is_match('^full history%. In other words, conditional on the state of affairs now%.', req.vars.content)
		assert.is_equal(859, #(req.vars.content))

	end)


	it("Renders the template", function()

		local req = request.new( '/', '/catastrophic' )
		req:load_markov( mk )
		local out = req:render()

		assert.is_string(out)
		assert.is_match('^%<%!DOCTYPE html%>', out)
		assert.is_match('In other words, conditional on the state of affairs now', out)

	end)

end)
