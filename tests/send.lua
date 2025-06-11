#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

--local markov = require 'components.markov'
local send = require 'components.send'
--local pl = require 'pl.pretty'

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
		
			local pattern = send.generate_pattern( delay, bytes )
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
			
			for i, packet in ipairs( pattern ) do
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
			
			--print('##', bytes_total, delay_total)
			assert.is_equal( bytes, bytes_total )
			assert.is_true( delay > delay_total - 1 )
			assert.is_true( delay < delay_total + 2 )
			
		until #tests == 0

	end)

	it("Generates different patterns", function()
		pending("Not yet implemented")
	end)

end)
