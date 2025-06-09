#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local markov = require 'components.markov'
local xorshiro = require 'components.xorshiro'

require 'busted.runner'()
describe("Markov Babbler", function()

	it("Trains and runs", function()

		local corpus = "and this and that."
		local mk = markov.new()
		assert.is_table(markov)

		mk:train( corpus )
		local status = mk:stats()

		assert.is_equal(6, status.seq_size)
		assert.is_equal(5, status.tokens)

		local rnd = xorshiro.new( 1, 2, 3, 4 )
		assert.is_equal("and this and", mk:babble( rnd, 2, 3))
		assert.is_equal("that.", mk:babble( rnd, 2, 3))

	end)

end)
