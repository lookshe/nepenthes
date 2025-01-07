#!/usr/bin/env lua5.3

local config = require 'config'
local digest = require 'openssl.digest'
local json = require 'dkjson'
local basexx = require 'basexx'

local _M = {}

local agents = {}
local overall = {
	total = 0,
	last_hit = 0
}


local function increment_agent( ag )


	ag.last_seen = os.time()
	ag.hits = ag.hits + 1

end


function _M.log_agent( agent )

	if agent:match("Mastodon") then
		return
	end

	if agent:match("http%:%/%/www%.google%.com%/bot%.html") then
		agent = 'Googlebot (multiple agents condensed)'
	end

	if agent:match("%(compatible%;% GoogleOther%)") then
		agent = 'GoogleOther (multiple agents condensed)'
	end

	overall.total = overall.total + 1
	overall.last_hit = os.time()

	local dig = digest.new()
	local hash = basexx.to_hex( dig:final( agent ) ):lower()

	if agents[ hash ] then
		increment_agent( agents[ hash ] )
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

	local function is_good( stat )
		if stat.first_seen > ( os.time() - 172800 ) then
			return false
		end

		if stat.last_seen - stat.first_seen < 86400 then
			return false
		end

		if stat.hits < 100 then
			return false
		end

		return true
	end

	for agent, stat in pairs(agents) do
		if is_good(stat) then
			send[ agent ] = stat
		end
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
