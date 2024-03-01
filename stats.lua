#!/usr/bin/env lua5.3

local config = require 'daemonparts.config'
local digest = require 'openssl.digest'
local json = require 'dkjson'

local _M = {}

local agents = {}
local overall = {
	total = 0,
	last_hit = 0
}


local function increment( ag )

	ag.last_seen = os.time()
	ag.hits = ag.hits + 1

end


--
-- Pulled directly from Luaossl manual
--
local function tohex(b)
	local x = ""
	for i = 1, #b do
		x = x ..  string.format("%.2x", string.byte(b, i))
	end
	return x
end


function _M.log_agent( agent )

	overall.total = overall.total + 1
	overall.last_hit = os.time()

	local dig = digest.new()
	local hash = tohex( dig:final( agent ) )

	if agents[ hash ] then
		increment( agents[ hash ] )
	else
		agents[ hash ] = {
			agstring = agent,
			last_seen = os.time(),
			first_seen = os.time(),
			hits = 1
		}
	end

end


function _M.sweep()

	local to_remove = {}

	for agent, stats in pairs(agents) do
		if stats.last_seen + config.forget_time < os.time() then
			if stats.hits < config.forget_hits then
				to_remove[ agent ] = true
			end
		end
	end

	for agent in pairs(to_remove) do
		agents[ agent ] = nil
	end

	--
	-- Because lazy, save here too. That way it'll be periodic,
	-- but not too often.
	--
	if config.persist_stats then

		local f = assert(io.open( config.persist_stats, 'w' ))
		f:write( _M.scoreboard() )
		f:close()

	end

end


function _M.scoreboard()

	local send = {}

	for agent, stat in pairs(agents) do
	
		if stat.first_seen > ( os.time() - 172800 ) then
			goto skip
		end
		
		if stat.last_seen - stat.first_seen < 86400 then
			goto skip
		end
		
		if stat.hits < 100 then
			goto skip
		end
		
		send[ agent ] = stat
		
	
		::skip::	
	end

	return json.encode {
		agents = send,
		overall = overall
	}
end


function _M.load()

	if config.persist_stats then

		local res, err = pcall(function()
			local f = assert(io.open( config.persist_stats, 'r' ))
			local ret = f:read("*all")
			f:close()

			local data = assert(json.decode( ret, 1, nil))

			agents = data.agents
			overall = data.overall
		end)

		if not res then
			print("Stats not loaded:", err)
		end

	end

end

return _M
