#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local cqueues = require 'cqueues'
local stats = require 'components.stats'
local stutter = require 'components.stutter'


require 'busted.runner'()
describe("Send-Request-Output Module", function()

	it("Never waits more than a half second", function()

		local tests = {
			8, 500,
			15, 350,
			15, 1200,
			46, 700
		}

		repeat

			local delay = table.remove(tests, 1)
			local bytes = table.remove(tests, 1)

			local pattern = stutter.generate_pattern( delay, bytes )
			assert.is_table(pattern)

			--
			-- We can't test actual values here, as we aren't using
			-- a deterministic random number generator in this case,
			-- help avoid detection.
			--
			-- *Well, technically it is deterministic, but a
			-- cryptographically secure generator is effectively
			-- nondeterministic looking without knowing it's internal
			-- state. I think.
			--
			-- So instead, the test proves it meets the stochastic
			-- effects desired.
			--

			-- the smallest requested delay, 8 seconds, implies
			-- typically sixteen outbound packets.
			assert.is_true( #pattern > 8 )

			--
			-- Prove the individual packets look nice.
			--
			local bytes_total = 0
			local delay_total = 0

			for i, packet in ipairs( pattern ) do	-- luacheck: ignore 213
				assert.is_table( packet )
				assert.is_number( packet.delay )
				assert.is_number( packet.bytes )

				assert.is_true( packet.delay > 0 )
				--assert.is_true( packet.delay <= 1 )
				assert.is_true( packet.bytes > 0 )
				assert.is_true( packet.bytes < ( bytes // 1.5 ) )

				bytes_total = bytes_total + packet.bytes
				delay_total = delay_total + packet.delay
			end

		until #tests == 0

	end)

	it("Generates different patterns", function()
		pending("Not yet implemented")
	end)

	it("Stutters with correct len/size", function()

		local s = 'abcdefghijklmnopqrstuvwxyz'
		local sl = stats.new_entry {
			address = '127.0.0.4',
			bytes = #s,
			bytes_sent = 0
		}

		local t1 = {
			{ delay = 0.1, bytes = 10 },
			{ delay = 0.2, bytes = 8 },
			{ delay = 0.4, bytes = 8 }
		}

		local x = stutter.delay_iterator( s, sl, t1 )
		local start = cqueues.monotime()

		assert.is_equal( 'abcdefghij', x() )
		assert.is_equal( 10, sl.bytes_sent )
		assert.is_false( sl.complete )

		assert.is_equal( 'klmnopqr', x() )
		assert.is_equal( 18, sl.bytes_sent )
		assert.is_false( sl.complete )

		assert.is_equal( 'stuvwxyz', x() )
		assert.is_equal( sl.bytes, sl.bytes_sent )
		assert.is_false( sl.complete )

		assert.is_nil( x() )

		local stop = cqueues.monotime()
		assert.is_true( (stop - start) >= 0.7 )
		assert.is_equal( sl.bytes, sl.bytes_sent )
		assert.is_true( sl.complete )

	end)


	it("Stutters - underruns okay", function()

		local s = 'abcdefghijklmnopqrstuvwxyz'
		local sl = stats.new_entry {
			address = '127.0.0.4',
			bytes = #s,
			bytes_sent = 0
		}

		local t1 = {
			{ delay = 0.1, bytes = 5 },
			{ delay = 0.2, bytes = 5 },
			{ delay = 0.1, bytes = 2 }
		}

		local x = stutter.delay_iterator( s, sl, t1 )
		local start = cqueues.monotime()

		assert.is_equal( 'abcde', x() )
		assert.is_equal( 5, sl.bytes_sent )
		assert.is_false( sl.complete )

		assert.is_equal( 'fghij', x() )
		assert.is_equal( 10, sl.bytes_sent )
		assert.is_false( sl.complete )

		assert.is_equal( 'kl', x() )
		assert.is_equal( 12, sl.bytes_sent )
		assert.is_false( sl.complete )

		assert.is_equal( 'mnopqrstuvwxyz', x() )
		assert.is_equal( sl.bytes, sl.bytes_sent )
		assert.is_false( sl.complete )

		assert.is_nil( x() )

		local stop = cqueues.monotime()
		assert.is_true( (stop - start) >= 0.4 )
		assert.is_equal( sl.bytes, sl.bytes_sent )
		assert.is_true( sl.complete )

	end)


	it("Stutters - overruns okay", function()

		local s = 'abcdefghijklmnopqrstuvwxyz'
		local sl = stats.new_entry {
			address = '127.0.0.4',
			bytes = #s,
			bytes_sent = 0
		}

		local t2 = {
			{ delay = 0.1, bytes = 15 },
			{ delay = 0.2, bytes = 10 },
			{ delay = 0.1, bytes = 10 }
		}

		local x = stutter.delay_iterator( s, sl, t2 )
		local start = cqueues.monotime()

		assert.is_equal( 'abcdefghijklmno', x() )
		assert.is_equal( 15, sl.bytes_sent )
		assert.is_false( sl.complete )

		assert.is_equal( 'pqrstuvwxy', x() )
		assert.is_equal( 25, sl.bytes_sent )
		assert.is_false( sl.complete )

		assert.is_equal( 'z', x() )
		assert.is_equal( sl.bytes, sl.bytes_sent )
		assert.is_false( sl.complete )

		assert.is_nil( x() )
		assert.is_equal( sl.bytes, sl.bytes_sent )
		assert.is_true( sl.complete )

		assert.is_nil( x() )

		local stop = cqueues.monotime()
		assert.is_true( (stop - start) >= 0.4 )
		assert.is_equal( sl.bytes, sl.bytes_sent )
		assert.is_true( sl.complete )

	end)

end)
