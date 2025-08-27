#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local config_loader = require 'daemonparts.config_loader'
local unix = require 'unix'

local config = require 'components.config'
local seed = require 'components.seed'

require 'busted.runner'()
describe("Instance Seed Store", function()

	before_each(function()
		config_loader.reset( config )
		os.execute('rm -f ./test-seed.txt')
	end)

	it("Creates a new seed from scratch if needed", function()

		assert.is_nil(config.seed_file)

		local s1 = seed.get()
		assert.is_string(s1)
		assert.is_equal(64, #s1)

		local s2 = seed.get()
		assert.is_string(s2)
		assert.is_equal(64, #s2)
		assert.is_not_equal(s1, s2)

		local s3 = seed.get()
		assert.is_string(s3)
		assert.is_equal(64, #s3)
		assert.is_not_equal(s1, s3)
		assert.is_not_equal(s2, s3)

	end)

	it("Persists a seed", function()

		assert.is_nil(config.seed_file)
		assert.is_false(unix.stat('./test-seed.txt'))

		config.seed_file = './test-seed.txt'


		local s1 = seed.get()
		assert.is_string(s1)
		assert.is_equal(64, #s1)

		local st, err = unix.stat( './test-seed.txt' )
		assert.is_nil(err)
		assert.is_true(unix.S_ISREG( st.mode ))


		local s2 = seed.get()
		assert.is_string(s2)
		assert.is_equal(64, #s2)
		assert.is_equal(s1, s2)

		local s3 = seed.get()
		assert.is_string(s3)
		assert.is_equal(64, #s3)
		assert.is_equal(s1, s3)
		assert.is_equal(s2, s3)

	end)

	it("Survives a mangled seed file", function()

		assert.is_nil(config.seed_file)
		assert.is_false(unix.stat('./test-seed.txt'))

		config.seed_file = './test-seed.txt'
		os.execute('touch ./test-seed.txt')

		local st, err = unix.stat( './test-seed.txt' )
		assert.is_nil(err)
		assert.is_true(unix.S_ISREG( st.mode ))


		local s1 = seed.get()
		assert.is_string(s1)
		assert.is_equal(64, #s1)

		local s2 = seed.get()
		assert.is_string(s2)
		assert.is_equal(64, #s2)
		assert.is_equal(s1, s2)

		local s3 = seed.get()
		assert.is_string(s3)
		assert.is_equal(64, #s3)
		assert.is_equal(s1, s3)
		assert.is_equal(s2, s3)
	end)

end)
