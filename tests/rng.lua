#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local seed = require 'components.seed'

--
-- Must be static across all test runs; monkey patch it
--
seed.get = function()
	return 'ec708cffc8c154521ced80639449576ff8bd356060eeb20aecfc76e45ec80bbc'
end


local rng = require 'components.rng'

require 'busted.runner'()
describe("Deterministic Psuedo-RNG Generator", function()

	it("Makes a stream per URI", function()

		--local rng = rng.new( '/maze/test/' )
		local tests = {
			['/maze/test'] = {
				65, 46, 2, 81, 64, 33, 25
			},
			['/location/number/two'] = {
				23, 62, 87, 10, 27, 88, 32
			},
			['/some/place/else'] = {
				59, 94, 59, 18, 77, 45, 35
			}
		}


		for test, expected in pairs( tests ) do
			local test_rng = rng.new( test )

			for i, v in ipairs( expected ) do	-- luacheck: ignore 213
				local g = test_rng:between( 100, 1 )
				assert.is_equal(v, g)
			end
		end

	end)


	it("Makes a reasonably uniform distribution", function()

		local buckets = {}
		local test_rng = rng.new( '/maze' )

		for i = 1, 1000 do	-- luacheck: ignore 213
			local x = test_rng:between( 100, 1 )
			buckets[ x ] = (buckets[ x ] or 0) + 1
		end

		assert.is_equal( 100, #buckets )
		local mean = 0

		for i, v in ipairs(buckets) do	-- luacheck: ignore 213
			mean = mean + v
		end

		assert.is_equal( 10, math.floor(mean / 100) )

	end)

end)
