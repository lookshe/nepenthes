#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local cqueues = require 'cqueues'

local config = require 'components.config'
local stats = require 'components.stats'
--local pl = require 'pl.pretty'

--
-- Real hits from a Nepenthes 1.2 instance - except delay and CPU,
-- those were made up as they were not in access_log.
--
local entries = {
	{
		address = '202.76.160.166',
		agent = "Mozilla/5.0 (Windows; U; Windows NT 6.1; ca; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (.NET CLR 3.5.30729)",
		uri = '/maze/digynian/phellem/Adelbert/jug/bemat',
		when = os.time() - 10,
		silo = 'default',
		bytes = 1809,
		response = 200,
		delay = 13,
		cpu = 0.000305
	},
	{
		address = '146.174.188.199',
		agent = "Mozilla/5.0 (X11; U; Linux i686; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Ubuntu/10.10 Chromium/10.0.648.133 Chrome/10.0.648.133 Safari/534.16",
		uri = '/maze/refectory/punnology/resorb/zoosphere',
		when = os.time() - 9,
		silo = 'default',
		bytes = 1569,
		response = 200,
		delay = 20,
		cpu = 0.000219
	},
	{
		address = '44.205.74.196',
		agent = "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amazonbot/0.1; +https://developer.amazon.com/support/amazonbot) Chrome/119.0.6045.214 Safari/537.36",
		uri = '/maze/yacht/herringbone',
		when = os.time() - 8,
		silo = 'default',
		bytes = 1515,
		response = 200,
		delay = 5,
		cpu = 0.000372
	},
	{
		address = '114.119.132.202',
		agent = "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)",
		uri = '/maze/unchafed/stolewise',
		silo = 'default',
		when = os.time() - 7,
		bytes = 1887,
		response = 200,
		delay = 11,
		cpu = 0.000248
	},
	{
		address = '5.255.231.147',
		agent = "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)",
		uri = '/maze/boobook/bandhu',
		silo = 'default',
		when = os.time() - 6,
		bytes = 1805,
		response = 200,
		delay = 8,
		cpu = 0.000401
	},
	{
		address = '146.174.187.165',
		agent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:2.0.1) Gecko/20110606 Firefox/4.0.1",
		uri = '/maze/estamene/cacodylic/miskeep',
		when = os.time() - 5,
		silo = 'default',
		bytes = 1550,
		response = 200,
		delay = 6,
		cpu = 0.000293
	}
}


local function float_equals( a, b )

	--
	-- In a passing test suite, these cases are never true.
	--
	-- luacov: disable
	if (a - b) > 0.0001 then
		return false
	end

	if (b - a) > 0.0001 then
		return false
	end
	-- luacov: enable

	return true

end


local function copy( a )

	local ret = {}

	for k, v in pairs(a) do
		ret[k] = v
	end

	return ret

end


require 'busted.runner'()
describe("Hit Counting/Statistics Module", function()

	before_each(function()
		config.stats_remember_time = 3600
	end)


	it("Logs Hits", function()

		stats.clear()
		local s1 = stats.compute()
		assert.is_equal(0, s1.hits)
		assert.is_equal(0, s1.addresses)
		assert.is_equal(0, s1.agents)
		assert.is_equal(0, s1.cpu)
		assert.is_equal(0, s1.bytes)
		assert.is_equal(0, s1.delay)

		stats.log( entries[1] )
		local s2 = stats.compute()
		assert.is_equal(1, s2.hits)
		assert.is_equal(1, s2.addresses)
		assert.is_equal(1, s2.agents)
		assert.is_true(float_equals(0.000305, s2.cpu))
		assert.is_equal(1809, s2.bytes)
		assert.is_equal(13, s2.delay)

		stats.log( entries[2] )
		local s3 = stats.compute()
		assert.is_equal(2, s3.hits)
		assert.is_equal(2, s3.addresses)
		assert.is_equal(2, s3.agents)
		assert.is_true(float_equals(0.000524, s3.cpu))
		assert.is_equal(3378, s3.bytes)
		assert.is_equal(33, s3.delay)

		stats.log( entries[3] )
		local s4 = stats.compute()
		assert.is_equal(3, s4.hits)
		assert.is_equal(3, s4.addresses)
		assert.is_equal(3, s4.agents)
		assert.is_true(float_equals(0.000896, s4.cpu))
		assert.is_equal(4893, s4.bytes)
		assert.is_equal(38, s4.delay)

		stats.log( entries[4] )
		local s5 = stats.compute()
		assert.is_equal(4, s5.hits)
		assert.is_equal(4, s5.addresses)
		assert.is_equal(4, s5.agents)
		assert.is_true(float_equals(0.001144, s5.cpu))
		assert.is_equal(6780, s5.bytes)
		assert.is_equal(49, s5.delay)

		stats.log( entries[5] )
		local s6 = stats.compute()
		assert.is_equal(5, s6.hits)
		assert.is_equal(5, s6.addresses)
		assert.is_equal(5, s6.agents)
		assert.is_true(float_equals(0.001545, s6.cpu))
		assert.is_equal(8585, s6.bytes)
		assert.is_equal(57, s6.delay)

		stats.log( entries[6] )
		local s7 = stats.compute()
		assert.is_equal(6, s7.hits)
		assert.is_equal(6, s7.addresses)
		assert.is_equal(6, s7.agents)
		assert.is_true(float_equals(0.001838, s7.cpu))
		assert.is_equal(10135, s7.bytes)
		assert.is_equal(63, s7.delay)

	end)


	it("Drops old hits from the rolling buffer", function()

		stats.clear()
		local s1 = stats:compute()
		assert.is_equal( 0, s1.hits )

		config.stats_remember_time = 1

		--
		-- Ten hits per second, with a one second hold time,
		-- means there should never be more than ten hits in the
		-- buffer.
		--
		for i = 1, 30 do	-- luacheck: ignore 213
			local hit = copy( entries[2] )
			hit.when = cqueues.monotime()
			stats.log( hit )
			cqueues.sleep(0.1)
			local sv = stats:compute()
			assert.is_true( 10 >= sv.hits )
		end

	end)


	it("Generates basic IP statistics", function()

		stats.clear()
		local s1 = stats.compute()
		assert.is_equal( 0, s1.hits )

		--
		-- Prove list empty
		--
		local list = stats.address_list()
		assert.is_table(list)

		local count = 0
		for k in pairs(list) do	-- luacheck: ignore 213
			-- luacov: disable
			count = count + 1
			-- luacov: enable
		end
		assert.is_equal(0, count)

		--
		-- Generate "traffic"
		--
		for i = 30, 1, -1 do
			local hit = copy( entries[2] )
			hit.when = hit.when - i
			stats.log( hit )
		end

		local s2 = stats.compute()
		assert.is_equal( 30, s2.hits )
		assert.is_equal( 1, s2.agents )
		assert.is_equal( 1, s2.addresses )

		for i = 30, 1, -1 do
			local hit = copy( entries[2] )
			hit.address = '1.2.3.4'
			hit.when = hit.when - i
			stats.log( hit )
		end

		local s3 = stats.compute()
		assert.is_equal( 60, s3.hits )
		assert.is_equal( 1, s3.agents )
		assert.is_equal( 2, s3.addresses )

		--
		-- Prove list not empty, data correct
		--
		local list2 = stats.address_list()
		assert.is_table(list2)

		local count2 = 0
		for k in pairs(list2) do	-- luacheck: ignore 213
			count2 = count2 + 1
		end
		assert.is_equal(2, count2)
		assert.is_equal(30, list2[ entries[2].address ])
		assert.is_equal(30, list2[ '1.2.3.4' ])

	end)


	it("Generates basic User-agent statistics", function()

		stats.clear()
		local s1 = stats.compute()
		assert.is_equal( 0, s1.hits )

		--
		-- Prove list empty
		--
		local list = stats.agent_list()
		assert.is_table(list)

		local count = 0
		for k in pairs(list) do	-- luacheck: ignore 213
			-- luacov: disable
			count = count + 1
			-- luacov: enable
		end
		assert.is_equal(0, count)

		--
		-- Generate "traffic"
		--
		for i = 30, 1, -1 do
			local hit = copy( entries[2] )
			hit.when = hit.when - i
			stats.log( hit )
		end

		local s2 = stats.compute()
		assert.is_equal( 30, s2.hits )
		assert.is_equal( 1, s2.agents )
		assert.is_equal( 1, s2.addresses )

		for i = 30, 1, -1 do
			local hit = copy( entries[2] )
			hit.agent = entries[3].agent
			hit.when = hit.when - i
			stats.log( hit )
		end

		local s3 = stats.compute()
		assert.is_equal( 60, s3.hits )
		assert.is_equal( 2, s3.agents )
		assert.is_equal( 1, s3.addresses )

		--
		-- Prove list not empty, data correct
		--
		local list2 = stats.agent_list()
		assert.is_table(list2)

		local count2 = 0
		for k in pairs(list2) do	-- luacheck: ignore 213
			count2 = count2 + 1
		end
		assert.is_equal(2, count2)
		assert.is_equal(30, list2[ entries[2].agent ])
		assert.is_equal(30, list2[ entries[3].agent ])

	end)

	it("Seperates by silo", function()
		pending("Not implemented")
	end)

end)
