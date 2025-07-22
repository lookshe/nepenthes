#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

--
-- Monkey patch this to make it identical from test run to test run.
--
local seed = require 'components.seed'
seed.get = function()
	return 'ec708cffc8c154521ced80639449576ff8bd356060eeb20aecfc76e45ec80bbc'
end

local markov = require 'components.markov'
local rng_factory = require 'components.rng'

require 'busted.runner'()
describe("Markov Babbler", function()

	it("Trains and runs on a string", function()

		local corpus = "for that and this and that."
		local mk = markov.new()
		assert.is_table(markov)

		mk:train( corpus )
		local status = mk:stats()

		assert.is_equal(6, status.seq_size)
		assert.is_equal(5, status.tokens)

		local rnd = rng_factory.new( '/maze/place/x' )
		assert.is_equal('and this and', mk:babble( rnd, 2, 6))
		assert.is_equal('that. that and this and', mk:babble( rnd, 3, 5))

	end)


	it("Trains and runs on a text file", function()

		local mk = markov.new()
		assert.is_table(markov)

		mk:train_file( './tests/share/wiki-markov.txt' )
		local status = mk:stats()

		assert.is_equal(339, status.seq_size)
		assert.is_equal(174, status.tokens)

		local rnd = rng_factory.new( '/maze/place' )
		local expect1 = '(sometimes characterized as "memorylessness"). In simpler terms, it is a type of Markov process that'
		local babble1 = mk:babble( rnd, 10, 15 )

		assert.is_equal( expect1, babble1 )

		local len1 = 0
		for part in babble1:gmatch('(%S+)') do	-- luacheck: ignore 213
			len1 = len1 + 1
		end
		assert.is_true(len1 <= 15)
		assert.is_true(len1 >= 10)

		--
		-- This particular run is known to hit the end-of-chain
		-- condition.
		--
		local expect2 = 'the state space). present state of the Russian mathematician Andrey Markov. Markov chains have'
		local babble2 = mk:babble( rnd, 10, 15 )

		assert.is_equal( expect2, babble2 )

		local len2 = 0
		for part in babble2:gmatch('(%S+)') do	-- luacheck: ignore 213
			len2 = len2 + 1
		end
		assert.is_true(len2 <= 15)
		assert.is_true(len2 >= 10)
	end)


	it("Very Large Run", function()

		local mk = markov.new()
		assert.is_table(markov)

		mk:train_file( './tests/share/wiki-markov.txt' )
		local rnd = rng_factory.new( '/whatever' )

		local babble1 = mk:babble( rnd, 1500 )

		local len1 = 0
		for part in babble1:gmatch('(%S+)') do	-- luacheck: ignore 213
			len1 = len1 + 1
		end
		assert.is_equal(1500, len1)

	end)

end)
