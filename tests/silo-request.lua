#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local config_loader = require 'daemonparts.config_loader'

local config = require 'components.config'
local silo = require 'components.silo'


--
-- Monkey patch this to make it identical from test run to test run.
--
local seed = require 'components.seed'
seed.get = function()
	return 'ec708cffc8c154521ced80639449576ff8bd356060eeb20aecfc76e45ec80bbc'
end


require 'busted.runner'()
describe("Silo/Request Builder Module", function()

	--local output = require 'daemonparts.output'
	--output.filter('debug')

	before_each(function()
		config_loader.reset( config )
	end)


	it("Loads and builds a request", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default'
			}
		}

		silo.setup()
		assert.is_equal(1, silo.count())

		local request1 = silo.new_request(
			'default',
			'/fluttering/festoon'
		)

		assert.is_table(request1)
		assert.is_equal('default', request1.silo)
		assert.is_false(request1:is_bogon())

		local request2 = silo.new_request(
			'default',
			'/not-within-the-word-list/festoon'
		)

		assert.is_table(request2)
		assert.is_equal('default', request2.silo)
		assert.is_true(request2:is_bogon())

		local request3 = silo.new_request(
			'some-other-silo',
			'/not-within-the-word-list/festoon'
		)

		assert.is_table(request3)
		assert.is_equal('default', request3.silo)
		assert.is_true(request3:is_bogon())

		local request4 = silo.new_request(
			'some-not-configured-silo',
			'/fluttering/festoon'
		)

		assert.is_table(request4)
		assert.is_equal('default', request4.silo)
		assert.is_false(request4:is_bogon())

	end)


	it("Loads and builds differing requests", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				prefixes = {
					'maze'
				}
			},
			{
				name = 'some-other-silo',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				prefixes = {
					'otherplace'
				}
			}
		}

		silo.setup()
		assert.is_equal(2, silo.count())

		local request1 = silo.new_request(
			'default',
			'/fluttering/festoon'
		)

		assert.is_table(request1)
		assert.is_equal('default', request1.silo)
		assert.is_false(request1:is_bogon())
		assert.is_nil(request1.prefix)

		local request2 = silo.new_request(
			'default',
			'/not-within-the-word-list/festoon'
		)

		assert.is_table(request2)
		assert.is_equal('default', request2.silo)
		assert.is_true(request2:is_bogon())

		local request3 = silo.new_request(
			'some-other-silo',
			'/not-within-the-word-list/festoon'
		)

		assert.is_table(request3)
		assert.is_equal('some-other-silo', request3.silo)
		assert.is_true(request3:is_bogon())

		local request4 = silo.new_request(
			'some-not-configured-silo',
			'/fluttering/festoon'
		)

		assert.is_table(request4)
		assert.is_equal('default', request4.silo)
		assert.is_false(request4:is_bogon())
		assert.is_nil(request4.prefix)


		local request5 = silo.new_request(
			'some-other-silo',
			'/otherplace/festoon'
		)

		assert.is_table(request5)
		assert.is_equal('some-other-silo', request5.silo)
		assert.is_false(request5:is_bogon())
		assert.is_equal('otherplace', request5.prefix)

	end)


	it("Can mark a default silo", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				prefixes = {
					'maze'
				}
			},
			{
				name = 'some-other-silo',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				default = true,
				prefixes = {
					'otherplace'
				}
			}
		}

		silo.setup()
		assert.is_equal(2, silo.count())

		local request1 = silo.new_request(
			'default',
			'/fluttering/festoon'
		)

		assert.is_table(request1)
		assert.is_equal('default', request1.silo)
		assert.is_false(request1:is_bogon())

		local request2 = silo.new_request(
			'default',
			'/not-within-the-word-list/festoon'
		)

		assert.is_table(request2)
		assert.is_equal('default', request2.silo)
		assert.is_true(request2:is_bogon())

		local request3 = silo.new_request(
			'some-other-silo',
			'/not-within-the-word-list/festoon'
		)

		assert.is_table(request3)
		assert.is_equal('some-other-silo', request3.silo)
		assert.is_true(request3:is_bogon())

		local request4 = silo.new_request(
			'some-not-configured-silo',
			'/fluttering/festoon'
		)

		assert.is_table(request4)
		assert.is_equal('some-other-silo', request4.silo)
		assert.is_false(request4:is_bogon())


		local request5 = silo.new_request(
			'some-other-silo',
			'/otherplace/festoon'
		)

		assert.is_table(request5)
		assert.is_equal('some-other-silo', request5.silo)
		assert.is_false(request5:is_bogon())

	end)


	it("Multiple default silos is an error", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				default = true
			},
			{
				name = 'second-default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				default = true
			}
		}

		assert.is_error(function()
			silo.setup()
		end)

	end)


	it("Has a functional Markov babbler #request", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default'
			}
		}

		silo.setup()

		local req = silo.new_request(
			'default',
			'/catastrophic'
		)

		assert.is_table(req.vars)
		assert.is_nil(req.vars.title)
		assert.is_nil(req.vars.header)
		assert.is_nil(req.vars.content)

		req:load_markov()

		assert.is_table(req.vars)
		assert.is_string(req.vars.title)
		assert.is_equal('has either a discrete index set (often', req.vars.title)
		assert.is_string(req.vars.header)
		assert.is_equal('the state of the Russian mathematician Andrey', req.vars.header)
		assert.is_string(req.vars.content)
		assert.is_match('^full history%. In other words, conditional on the state of affairs now%.', req.vars.content)
		assert.is_equal(859, #(req.vars.content))

	end)


	it("Generates list of given URLs in a page #request", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default'
			}
		}

		silo.setup()

		local req = silo.new_request(
			'default',
			'/catastrophic'
		)

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


	it("Respects Prefixes generating URLs", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				prefixes = {
					'/maze'
				}
			}
		}

		silo.setup()

		local req = silo.new_request(
			'default',
			'/maze/catastrophic'
		)

		local urls = req:urllist()

		assert.is_table( urls )
		assert.is_equal( 9, #urls )

		assert.is_equal('/maze/undisturbed/sedate/Paracelsus/crying', urls[1].link)
		assert.is_equal('/maze/shadowboxing/counties/staccatos/graphically', urls[2].link)
		assert.is_equal('/maze/improvable/Huff/Leicester/poling', urls[3].link)
		assert.is_equal('/maze/servant/shadowboxing', urls[4].link)
		assert.is_equal('/maze/Huff/daybreak', urls[5].link)
		assert.is_equal('/maze/Pygmies', urls[6].link)
		assert.is_equal('/maze/sibyl/graphically/dearth/nutritious', urls[7].link)
		assert.is_equal('/maze/varied/teachable/Houyhnhnm/staccatos/bosom', urls[8].link)
		assert.is_equal('/maze/bassos/graphically/catastrophic/poling/Leicester', urls[9].link)

	end)


	it("Respects Prefixes generating URLs when multiple prefixes are present #prefix", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				prefixes = {
					'/otherplace',
					'/maze',
					'/demo'
				}
			}
		}

		silo.setup()

		local req = silo.new_request(
			'default',
			'/maze/catastrophic'
		)

		assert.is_false(req:is_bogon())
		local urls = req:urllist()

		assert.is_table( urls )
		assert.is_equal( 9, #urls )

		assert.is_equal('/maze/undisturbed/sedate/Paracelsus/crying', urls[1].link)
		assert.is_equal('/maze/shadowboxing/counties/staccatos/graphically', urls[2].link)
		assert.is_equal('/maze/improvable/Huff/Leicester/poling', urls[3].link)

		local req2 = silo.new_request(
			'default',
			'/otherplace/sedate/graphically'
		)

		assert.is_false(req2:is_bogon())
		local urls2 = req2:urllist()

		assert.is_table( urls2 )
		assert.is_equal( 6, #urls2 )

		assert.is_equal('/otherplace/Leicester/veranda/crankcase/lousiness/yourself', urls2[1].link)
		assert.is_equal('/otherplace/festoon/mortarboards/ballpark', urls2[2].link)
		assert.is_equal('/otherplace/fright/ruminations/mortifying/boasting/stones', urls2[3].link)
		assert.is_equal('/otherplace/Pygmies', urls2[4].link)
		assert.is_equal('/otherplace/graphically/Khalid/teachable', urls2[5].link)
		assert.is_equal('/otherplace/varied/encyclical/objective/staccatos', urls2[6].link)

	end)


	it("Renders the template #request", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default'
			}
		}

		silo.setup()

		local req = silo.new_request(
			'default',
			'/catastrophic'
		)

		req:load_markov()
		local out = req:render()
		local wait = req:send_delay()

		assert.is_string(out)
		assert.is_match('^%<%!DOCTYPE html%>', out)
		assert.is_match('In other words, conditional on the state of affairs now', out)
		assert.is_number(wait)
		assert.is_equal(8, wait)

	end)


	it("Can have a zero-delay silo", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				zero_delay = true
			}
		}

		silo.setup()
		local req = silo.new_request(
			'default',
			'/catastrophic'
		)

		assert.is_true(req.zero_delay)
		req:load_markov()
		local out = req:render()
		local wait = req:send_delay()

		assert.is_string(out)
		assert.is_match('^%<%!DOCTYPE html%>', out)
		assert.is_match('In other words, conditional on the state of affairs now', out)
		assert.is_number(wait)
		assert.is_equal(0, wait)

	end)


	it("Can disable the bogon filter", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				bogon_filter = false
			}
		}

		silo.setup()
		assert.is_equal(1, silo.count())

		local request1 = silo.new_request(
			'default',
			'/fluttering/festoon'
		)

		assert.is_table(request1)
		assert.is_equal('default', request1.silo)
		assert.is_false(request1:is_bogon())

		local request2 = silo.new_request(
			'default',
			'/not-within-the-word-list/festoon'
		)

		assert.is_table(request2)
		assert.is_equal('default', request2.silo)
		assert.is_false(request2:is_bogon())

		local request3 = silo.new_request(
			'some-other-silo',
			'/not-within-the-word-list/festoon'
		)

		assert.is_table(request3)
		assert.is_equal('default', request3.silo)
		assert.is_false(request3:is_bogon())

		local request4 = silo.new_request(
			'some-not-configured-silo',
			'/fluttering/festoon'
		)

		assert.is_table(request4)
		assert.is_equal('default', request4.silo)
		assert.is_false(request4:is_bogon())

	end)


	it("Occasionally redirects instead", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				redirect_rate = 15
			}
		}

		silo.setup()
		assert.is_equal(1, silo.count())

		--
		-- RNG is 12, lower than 15
		--
		local request1 = silo.new_request(
			'default',
			'/fluttering/festoon'
		)

		assert.is_table(request1)
		assert.is_equal('default', request1.silo)
		local redirect1, location1 = request1:is_redirect()
		assert.is_equal('/Mandeville', location1)
		assert.is_true(redirect1)


		--
		-- RNG is 20, higher than 15
		--
		local request2 = silo.new_request(
			'default',
			'/Mandeville'
		)

		assert.is_table(request2)
		assert.is_equal('default', request2.silo)
		local redirect2, location2 = request2:is_redirect()
		assert.is_nil(location2)
		assert.is_false(redirect2)

		--
		-- RNG is 9, lower
		--
		local request3 = silo.new_request(
			'default',
			'/photon'
		)

		assert.is_table(request3)
		assert.is_equal('default', request3.silo)
		local redirect3, location3 = request3:is_redirect()
		assert.is_equal('/chaplain/chilis/thudding', location3)
		assert.is_true(redirect3)


		--
		-- RNG is 93, higher
		--
		local request4 = silo.new_request(
			'default',
			'/chaplain/chilis/thudding'
		)

		assert.is_table(request4)
		assert.is_equal('default', request4.silo)
		local redirect4, location4 = request4:is_redirect()
		assert.is_nil( location4 )
		assert.is_false( redirect4 )

	end)


	it("Has variable header-delay rate #delay", function()

		config.silos = {
			{
				name = 'default',
				corpus = './tests/share/wiki-markov.txt',
				wordlist = './tests/share/words.txt',
				template = 'default',
				header_min_wait = 5,
				header_max_wait = 10
			}
		}

		silo.setup()
		assert.is_equal(1, silo.count())

		local request1 = silo.new_request(
			'default',
			'/fluttering/festoon'
		)

		assert.is_table(request1)
		assert.is_equal('default', request1.silo)
		assert.is_equal(6, request1:header_wait())

		local request2 = silo.new_request(
			'default',
			'/chaplain/chilis/thudding'
		)

		assert.is_table(request2)
		assert.is_equal('default', request2.silo)
		assert.is_equal(5, request2:header_wait())

	end)

end)
