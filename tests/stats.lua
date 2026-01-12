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
		silo = 'default',
		bytes_generated = 1809,
		response = 200,
		planned_delay = 13,
		cpu = 0.000305,
	},
	{
		address = '146.174.188.199',
		agent = "Mozilla/5.0 (X11; U; Linux i686; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Ubuntu/10.10 Chromium/10.0.648.133 Chrome/10.0.648.133 Safari/534.16",
		uri = '/maze/refectory/punnology/resorb/zoosphere',
		silo = 'default',
		bytes_generated = 1569,
		response = 200,
		planned_delay = 20,
		cpu = 0.000219,
	},
	{
		address = '44.205.74.196',
		agent = "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amazonbot/0.1; +https://developer.amazon.com/support/amazonbot) Chrome/119.0.6045.214 Safari/537.36",
		uri = '/maze/yacht/herringbone',
		silo = 'default',
		bytes_generated = 1515,
		response = 200,
		planned_delay = 5,
		cpu = 0.000372,
	},
	{
		address = '114.119.132.202',
		agent = "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)",
		uri = '/maze/unchafed/stolewise',
		silo = 'first',
		bytes_generated = 1887,
		response = 200,
		planned_delay = 11,
		cpu = 0.000248,
	},
	{
		address = '5.255.231.147',
		agent = "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)",
		uri = '/maze/boobook/bandhu',
		silo = 'second',
		bytes_generated = 1805,
		response = 200,
		planned_delay = 8,
		cpu = 0.000401,
	},
	{
		address = '146.174.187.165',
		agent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:2.0.1) Gecko/20110606 Firefox/4.0.1",
		uri = '/maze/estamene/cacodylic/miskeep',
		silo = 'first',
		bytes_generated = 1550,
		response = 200,
		planned_delay = 6,
		cpu = 0.000293,
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
		assert.is_equal(0, s1.bytes_sent)
		assert.is_equal(0, s1.delay)

		-- some stats not keyed to requests
		assert.is_number(s1.memory_usage)
		assert.is_number(s1.cpu_total)

		local e1 = stats.new_entry( entries[1] )
		e1:record( 1809, 13 )
		e1:mark_complete()

		local s2 = stats.compute()
		assert.is_equal(1, s2.hits)
		assert.is_equal(1, s2.addresses)
		assert.is_equal(1, s2.agents)
		assert.is_true(float_equals(0.000305, s2.cpu))
		assert.is_equal(1809, s2.bytes_sent)
		assert.is_equal(13, s2.delay)

		assert.is_number(s2.memory_usage)
		assert.is_number(s2.cpu_total)

		local e2 = stats.new_entry( entries[2] )
		e2:record( 1569, 20 )
		e2:mark_complete()

		local s3 = stats.compute()
		assert.is_equal(2, s3.hits)
		assert.is_equal(2, s3.addresses)
		assert.is_equal(2, s3.agents)
		assert.is_true(float_equals(0.000524, s3.cpu))
		assert.is_equal(3378, s3.bytes_sent)
		assert.is_equal(33, s3.delay)

		assert.is_number(s3.memory_usage)
		assert.is_number(s3.cpu_total)

		local e3 = stats.new_entry( entries[3] )
		e3:record( 1515, 5 )
		e3:mark_complete()

		local s4 = stats.compute()
		assert.is_equal(3, s4.hits)
		assert.is_equal(3, s4.addresses)
		assert.is_equal(3, s4.agents)
		assert.is_true(float_equals(0.000896, s4.cpu))
		assert.is_equal(4893, s4.bytes_sent)
		assert.is_equal(38, s4.delay)

		assert.is_number(s4.memory_usage)
		assert.is_number(s4.cpu_total)

		local e4 = stats.new_entry( entries[4] )
		e4:record( 1887, 11 )
		e4:mark_complete()

		local s5 = stats.compute()
		assert.is_equal(4, s5.hits)
		assert.is_equal(4, s5.addresses)
		assert.is_equal(4, s5.agents)
		assert.is_true(float_equals(0.001144, s5.cpu))
		assert.is_equal(6780, s5.bytes_sent)
		assert.is_equal(49, s5.delay)

		assert.is_number(s5.memory_usage)
		assert.is_number(s5.cpu_total)

		local e5 = stats.new_entry( entries[5] )
		e5:record( 1805, 8 )
		e5:mark_complete()

		local s6 = stats.compute()
		assert.is_equal(5, s6.hits)
		assert.is_equal(5, s6.addresses)
		assert.is_equal(5, s6.agents)
		assert.is_true(float_equals(0.001545, s6.cpu))
		assert.is_equal(8585, s6.bytes_sent)
		assert.is_equal(57, s6.delay)

		assert.is_number(s6.memory_usage)
		assert.is_number(s6.cpu_total)

		local e6 = stats.new_entry( entries[6] )
		e6:record( 1550, 6 )
		e6:mark_complete()

		local s7 = stats.compute()
		assert.is_equal(6, s7.hits)
		assert.is_equal(6, s7.addresses)
		assert.is_equal(6, s7.agents)
		assert.is_true(float_equals(0.001838, s7.cpu))
		assert.is_equal(10135, s7.bytes_sent)
		assert.is_equal(63, s7.delay)

		assert.is_number(s7.memory_usage)
		assert.is_number(s7.cpu_total)

	end)


	it("Correctly accounts unfinished entries", function()

		stats.clear()
		local s1 = stats.compute()
		assert.is_equal(0, s1.hits)
		assert.is_equal(0, s1.addresses)
		assert.is_equal(0, s1.agents)
		assert.is_equal(0, s1.cpu)
		assert.is_equal(0, s1.bytes_generated)
		assert.is_equal(0, s1.bytes_sent)
		assert.is_equal(0, s1.delay)
		assert.is_equal(0, s1.active)

		-- some stats not keyed to requests
		assert.is_number(s1.memory_usage)
		assert.is_number(s1.cpu_total)

		local h1 = stats.new_entry( entries[1] )
		local s2 = stats.compute()
		assert.is_equal(1, s2.hits)
		assert.is_equal(1, s2.addresses)
		assert.is_equal(1, s2.agents)
		assert.is_true(float_equals(0.000305, s2.cpu))
		assert.is_equal(1809, s2.bytes_generated)
		assert.is_equal(0, s2.bytes_sent)
		assert.is_equal(0, s2.delay)
		assert.is_equal(1, s2.active)

		assert.is_number(s2.memory_usage)
		assert.is_number(s2.cpu_total)

		h1:record( 1809, 13 )
		h1:mark_complete()

		local s3 = stats.compute()
		assert.is_equal(1, s3.hits)
		assert.is_equal(1, s3.addresses)
		assert.is_equal(1, s3.agents)
		assert.is_true(float_equals(0.000305, s3.cpu))
		assert.is_equal(1809, s3.bytes_generated)
		assert.is_equal(1809, s3.bytes_sent)
		assert.is_equal(13, s3.delay)
		assert.is_equal(0, s3.active)

	end)


	it("Doesn't crash when it's only unfinished entries", function()

		stats.clear()
		for i, v in ipairs( entries ) do	-- luacheck: ignore 213
			local h1 = stats.new_entry( v )
			h1:record( math.floor(v.bytes_generated / 2), 1 )
		end

		local sc = stats.compute()
		assert.is_equal(6, sc.hits)
		assert.is_equal(6, sc.addresses)
		assert.is_equal(6, sc.agents)
		assert.is_true(float_equals(0.001838, sc.cpu))
		assert.is_equal(5065, sc.bytes_sent)
		assert.is_equal(6, sc.delay)
		assert.is_equal(6, sc.active)

		assert.is_number(sc.memory_usage)
		assert.is_number(sc.cpu_total)

	end)


	it("Drops old hits from the rolling buffer", function()

		stats.clear()
		local s1 = stats.compute()
		assert.is_equal( 0, s1.hits )

		config.stats_remember_time = 1

		--
		-- Ten hits per second, with a one second hold time,
		-- means there should never be more than ten hits in the
		-- buffer.
		--
		for i = 1, 30 do	-- luacheck: ignore 213
			local hit = copy( entries[2] )
			hit.when = os.time()
			stats.new_entry( hit ):mark_complete()
			cqueues.sleep(0.1)
			local sv = stats.compute()
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
		for _ = 30, 1, -1 do
			stats.new_entry( entries[2] ):mark_complete()
		end

		local s2 = stats.compute()
		assert.is_equal( 30, s2.hits )
		assert.is_equal( 1, s2.agents )
		assert.is_equal( 1, s2.addresses )

		for _ = 30, 1, -1 do
			local s = stats.new_entry( entries[2] )
			s.address = '1.2.3.4'
			s:mark_complete()
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
		for _ = 30, 1, -1 do
			stats.new_entry( entries[2] ):mark_complete()
		end

		local s2 = stats.compute()
		assert.is_equal( 30, s2.hits )
		assert.is_equal( 1, s2.agents )
		assert.is_equal( 1, s2.addresses )

		for _ = 30, 1, -1 do
			local s = stats.new_entry( entries[2] )
			s.agent = entries[3].agent
			s:mark_complete()
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


	it("Tracks Active Connections", function()

		stats.clear()

		local s1 = stats.compute()
		assert.is_equal( 0, s1.active )

		local h1 = stats.new_entry( entries[1] )

		local s2 = stats.compute()
		assert.is_equal( 1, s2.active )

		h1:mark_complete()

		local s3 = stats.compute()
		assert.is_equal( 0, s3.active )

	end)


	it("Seperates by silo", function()

		stats.clear()
		for i, hit in ipairs( entries ) do	-- luacheck: ignore 213
			local h1 = stats.new_entry( hit )
			h1:record( hit.bytes_generated, hit.planned_delay )
			h1:mark_complete()
		end

		local s1 = stats.compute()
		assert.is_equal(6, s1.hits)
		assert.is_equal(6, s1.addresses)
		assert.is_equal(6, s1.agents)
		assert.is_true(float_equals(0.001838, s1.cpu))
		assert.is_equal(10135, s1.bytes_sent)
		assert.is_equal(63, s1.delay)

		assert.is_number(s1.memory_usage)
		assert.is_number(s1.cpu_total)

		local list1 = stats.address_list()
		assert.is_table(list1)
		assert.is_equal( 1, list1['146.174.187.165'] )
		assert.is_equal( 1, list1['5.255.231.147'] )
		assert.is_equal( 1, list1['202.76.160.166'] )
		assert.is_equal( 1, list1['44.205.74.196'] )
		assert.is_equal( 1, list1['114.119.132.202'] )
		assert.is_equal( 1, list1['146.174.188.199'] )

		local agents1 = stats.agent_list()
		local count1 = 0
		for k, v in pairs(agents1) do	-- luacheck: ignore 213
			assert.is_equal(1, v)
			count1 = count1 + 1
		end
		assert.is_equal(6, count1)

		local s2 = stats.compute( 'none' )
		assert.is_equal(0, s2.hits)
		assert.is_equal(0, s2.addresses)
		assert.is_equal(0, s2.agents)
		assert.is_equal(0, s2.cpu)
		assert.is_equal(0, s2.bytes_sent)
		assert.is_equal(0, s2.delay)

		local list2 = stats.address_list( 'none' )
		assert.is_table(list2)
		assert.is_nil( list2['146.174.187.165'] )
		assert.is_nil( list2['5.255.231.147'] )
		assert.is_nil( list2['202.76.160.166'] )
		assert.is_nil( list2['44.205.74.196'] )
		assert.is_nil( list2['114.119.132.202'] )
		assert.is_nil( list2['146.174.188.199'] )

		local agents2 = stats.agent_list( 'none' )
		local count2 = 0
		for k, v in pairs(agents2) do	-- luacheck: ignore 213
		-- does not execute if test passes.
		-- luacov: disable
			assert.is_equal(1, v)
			count2 = count2 + 1
		-- luacov: enable
		end
		assert.is_equal(0, count2)

		local s3 = stats.compute( 'first' )
		assert.is_equal(2, s3.hits)
		assert.is_equal(2, s3.addresses)
		assert.is_equal(2, s3.agents)
		assert.is_true(float_equals(0.000541, s3.cpu))
		assert.is_equal(3437, s3.bytes_sent)
		assert.is_equal(17, s3.delay)

		local list3 = stats.address_list( 'first' )
		assert.is_table(list3)
		assert.is_equal( 1, list3['146.174.187.165'] )
		assert.is_nil( list3['5.255.231.147'] )
		assert.is_nil( list3['202.76.160.166'] )
		assert.is_nil( list3['44.205.74.196'] )
		assert.is_equal( 1, list3['114.119.132.202'] )
		assert.is_nil( list3['146.174.188.199'] )

		local agents3 = stats.agent_list( 'first' )
		local count3 = 0
		for k, v in pairs(agents3) do	-- luacheck: ignore 213
			assert.is_equal(1, v)
			count3 = count3 + 1
		end
		assert.is_equal(2, count3)

	end)


	it("Dumps the buffer", function()

		stats.clear()
		for i, hit in ipairs( entries ) do	-- luacheck: ignore 213
			stats.new_entry( hit ):mark_complete()
		end

		local ret = stats.buffer()

		assert.is_table(ret)
		assert.is_equal( 6, #ret )
		assert.is_equal( '202.76.160.166', ret[1].address )
		assert.is_equal( '146.174.188.199', ret[2].address )
		assert.is_not_equal( ret[1].id, ret[2].id )
		assert.is_equal( '44.205.74.196', ret[3].address )
		assert.is_not_equal( ret[1].id, ret[3].id )
		assert.is_not_equal( ret[2].id, ret[3].id )
		assert.is_equal( '114.119.132.202', ret[4].address )
		assert.is_not_equal( ret[1].id, ret[4].id )
		assert.is_not_equal( ret[2].id, ret[4].id )
		assert.is_not_equal( ret[3].id, ret[4].id )
		assert.is_equal( '5.255.231.147', ret[5].address )
		assert.is_not_equal( ret[1].id, ret[5].id )
		assert.is_not_equal( ret[2].id, ret[5].id )
		assert.is_not_equal( ret[3].id, ret[5].id )
		assert.is_not_equal( ret[4].id, ret[5].id )
		assert.is_equal( '146.174.187.165', ret[6].address )
		assert.is_not_equal( ret[1].id, ret[6].id )
		assert.is_not_equal( ret[2].id, ret[6].id )
		assert.is_not_equal( ret[3].id, ret[6].id )
		assert.is_not_equal( ret[4].id, ret[6].id )
		assert.is_not_equal( ret[5].id, ret[6].id )

	end)


	it("Fixes implausibly inaccurate 'actives' - aggregation", function()

		stats.clear()
		local n
		for i, hit in ipairs( entries ) do	-- luacheck: ignore 213
			local new_hit = stats.new_entry( hit )
			if i ~= 3 then
				new_hit:mark_complete()
			else
				n = new_hit
			end
		end

		local s1 = stats.compute()
		assert.is_equal(6, s1.hits)
		assert.is_equal(1, s1.active)


		-- delay should be five; which means if the record was logged
		-- 120 seconds ago, at 115 seconds ago it's obviously stale and
		-- an error prevented marking it completed.
		n.when = n.when - 120

		local s2 = stats.compute()
		assert.is_equal(6, s2.hits)
		assert.is_equal(0, s2.active)

	end)


	it("Fixes implausibly inaccurate 'actives' - buffer dump", function()

		stats.clear()
		local n
		for i, hit in ipairs( entries ) do	-- luacheck: ignore 213
			local new_hit = stats.new_entry( hit )
			if i ~= 3 then
				new_hit:mark_complete()
			else
				n = new_hit
			end
		end

		local ret = stats.buffer()
		assert.is_table(ret)
		assert.is_equal( 6, #ret )
		assert.is_equal( '202.76.160.166', ret[1].address )
		assert.is_true( ret[1].complete )
		assert.is_equal( '146.174.188.199', ret[2].address )
		assert.is_true( ret[2].complete )
		assert.is_equal( '44.205.74.196', ret[3].address )
		assert.is_false( ret[3].complete )
		assert.is_equal( '114.119.132.202', ret[4].address )
		assert.is_true( ret[4].complete )
		assert.is_equal( '5.255.231.147', ret[5].address )
		assert.is_true( ret[5].complete )
		assert.is_equal( '146.174.187.165', ret[6].address )
		assert.is_true( ret[6].complete )


		-- delay should be five; which means if the record was logged
		-- 120 seconds ago, at 115 seconds ago it's obviously stale and
		-- an error prevented marking it completed.
		n.when = n.when - 120

		local ret2 = stats.buffer()
		assert.is_table(ret2)
		assert.is_equal( 6, #ret2 )
		assert.is_equal( '202.76.160.166', ret2[1].address )
		assert.is_true( ret2[1].complete )
		assert.is_equal( '146.174.188.199', ret2[2].address )
		assert.is_true( ret2[2].complete )
		assert.is_equal( '44.205.74.196', ret2[3].address )
		assert.is_true( ret2[3].complete )
		assert.is_equal( '114.119.132.202', ret2[4].address )
		assert.is_true( ret2[4].complete )
		assert.is_equal( '5.255.231.147', ret2[5].address )
		assert.is_true( ret2[5].complete )
		assert.is_equal( '146.174.187.165', ret2[6].address )
		assert.is_true( ret2[6].complete )

	end)


	it("Dumps the buffer - from a point in time", function()

		stats.clear()
		for i, hit in ipairs( entries ) do	-- luacheck: ignore 213
			stats.new_entry( hit ):mark_complete()
		end

		local check = stats.buffer()
		local from = check[3].id

		local ret = stats.buffer( from )

		assert.is_table(ret)
		assert.is_equal( 3, #ret )
		assert.is_equal( '114.119.132.202', ret[1].address )
		assert.is_equal( '5.255.231.147', ret[2].address )
		assert.is_not_equal( ret[1].id, ret[2].id )
		assert.is_equal( '146.174.187.165', ret[3].address )
		assert.is_not_equal( ret[1].id, ret[3].id )
		assert.is_not_equal( ret[2].id, ret[3].id )

	end)


	it("Dumps the entire buffer if the start point is in the past", function()

		local first

		stats.clear()
		for i, hit in ipairs( entries ) do	-- luacheck: ignore 213
			local st = stats.new_entry(hit)

			if not first then
				first = st.when
			end

			st:mark_complete()
		end

		local from = tostring(first - 200) .. '.1'
		local check = stats.buffer( from )

		assert.is_table(check)
		assert.is_equal( 6, #check )
		assert.is_equal( '202.76.160.166', check[1].address )
		assert.is_equal( '146.174.188.199', check[2].address )
		assert.is_equal( '44.205.74.196', check[3].address )
		assert.is_equal( '114.119.132.202', check[4].address )
		assert.is_equal( '5.255.231.147', check[5].address )
		assert.is_equal( '146.174.187.165', check[6].address )

	end)


	it("Save Total since-start statistics", function()

		stats.clear()
		local s1 = stats.compute()
		assert.is_equal( 0, s1.hits )

		config.stats_remember_time = 1

		--
		-- This is very similar to proving stats buffer drops old
		-- information - except we are looking at the totals differing
		-- from the realtime.
		--
		local expected_sent = 0
		local expected_generated = 0

		for i = 1, 30 do	-- luacheck: ignore 213
			local hit = copy( entries[2] )
			hit.when = os.time()
			local h1 = stats.new_entry( hit )
			h1:record( 1569, 20 )
			h1:mark_complete()


			expected_sent = expected_sent + h1.bytes_sent
			expected_generated = expected_generated + h1.bytes_generated

			cqueues.sleep(0.1)
			local sv = stats.compute()

			assert.is_true( 10 >= sv.hits )
			assert.is_equal( i, sv.hits_total )
			assert.is_equal( expected_sent, sv.bytes_sent_total )
			assert.is_equal( expected_generated, sv.bytes_generated_total )

			if i > 10 then
				assert.is_true( expected_sent > sv.bytes_sent )
				assert.is_true( expected_generated > sv.bytes_generated )
			end

		end

	end)


	it("Never sends incomplete entries if requested", function()

		stats.clear()
		for i, hit in ipairs( entries ) do	-- luacheck: ignore 213
			local new_hit = stats.new_entry( hit )
			if i ~= 3 then
				new_hit:mark_complete()
			end
		end

		local ret = stats.buffer( '100.1', true )
		assert.is_table(ret)
		assert.is_equal( 2, #ret )
		assert.is_equal( '202.76.160.166', ret[1].address )
		assert.is_true( ret[1].complete )
		assert.is_equal( '146.174.188.199', ret[2].address )
		assert.is_true( ret[2].complete )

	end)

end)
