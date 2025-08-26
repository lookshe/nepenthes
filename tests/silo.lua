#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local config_loader = require 'daemonparts.config_loader'

local config = require 'components.config'
local silo = require 'components.silo'


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
		assert.is_equal('default', request4.silo)
		assert.is_false(request4:is_bogon())


		local request5 = silo.new_request(
			'some-other-silo',
			'/otherplace/festoon'
		)

		assert.is_table(request5)
		assert.is_equal('some-other-silo', request5.silo)
		assert.is_false(request5:is_bogon())

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

end)
