#!/usr/bin/env lua5.3

local fifo = require 'fifo'
local cqueues = require 'cqueues' -- for monotime()

local config = require 'components.config'

local _M = {}


local buf = fifo()
local start = os.time()

function _M.clear()
	buf = fifo()
end

function _M.log( val )

	--
	-- Schema Check
	--
	assert(type(val) == 'table')
	assert(type(val.address) == 'string')
	assert(type(val.agent) == 'string')
	assert(type(val.uri) == 'string')
	assert(type(val.silo) == 'string')

	assert(type(val.when) == 'number')
	assert(type(val.bytes) == 'number')
	assert(type(val.response) == 'number')
	assert(type(val.delay) == 'number')
	assert(type(val.cpu) == 'number')

	buf:push( val )

	local expired = cqueues.monotime() - config.stats_remember_time

	while buf:peek().when <= expired do
		buf:pop()
	end

end


function _M.compute()

	local ret = {
		hits = #buf,
		addresses = 0,
		agents = 0,
		cpu = 0,
		cpu_total = os.clock(),
		bytes_sent = 0,
		memory_usage = collectgarbage( "count" ) * 1024,
		delay = 0,
		uptime = os.time() - start
	}

	-- this is inaccurate at first (due to training) but will decay
	-- to close enough with time.
	ret.cpu_percent = ( ret.cpu_total / ret.uptime ) * 100

	local seen_addresses = {}
	local seen_agents = {}

	for i = 1, #buf do
		local v = buf:peek(i)

		if not seen_addresses[ v.address ] then
			seen_addresses[ v.address ] = true
			ret.addresses = ret.addresses + 1
		end

		if not seen_agents[ v.agent ] then
			seen_agents[ v.agent ] = true
			ret.agents = ret.agents + 1
		end

		ret.cpu = ret.cpu + v.cpu
		ret.bytes_sent = ret.bytes_sent + v.bytes
		ret.delay = ret.delay + v.delay
	end

	return ret

end


function _M.address_list()

	local ret = {}

	for i = 1, #buf do
		local v = buf:peek(i)

		if not ret[ v.address ] then
			ret[ v.address ] = 1
		else
			ret[ v.address ] = ret[ v.address ] + 1
		end
	end

	return ret

end


function _M.agent_list()

	local ret = {}

	for i = 1, #buf do
		local v = buf:peek(i)

		if not ret[ v.agent ] then
			ret[ v.agent ] = 1
		else
			ret[ v.agent ] = ret[ v.agent ] + 1
		end
	end

	return ret

end


return _M
