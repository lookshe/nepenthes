#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local markov = require 'components.markov'
local xorshiro = require 'components.xorshiro'
--local pl = require 'pl.pretty'

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

		local rnd = xorshiro.new( 1, 2, 3, 4 )
		assert.is_equal("this and that.", mk:babble( rnd, 2, 6))
		assert.is_equal("and this and", mk:babble( rnd, 2, 3))

	end)

	it("Trains and runs on a text file", function()

		local mk = markov.new()
		assert.is_table(markov)

		mk:train_file( './tests/share/wiki-markov.txt' )
		local status = mk:stats()

		assert.is_equal(339, status.seq_size)
		assert.is_equal(174, status.tokens)

		local rnd = xorshiro.new( 5, 6, 7, 8 )
		assert.is_equal(
			'complex probability distributions, and have found application in areas including Bayesian statistics, biology,',
			mk:babble( rnd, 10, 15)
		)

		assert.is_equal(
			'the nature of time), but it is a type of Markov process is called',
			mk:babble( rnd, 10, 15)
		)
	end)

end)
