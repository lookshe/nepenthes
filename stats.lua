#!/usr/bin/env lua5.3

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



function _M.log_agent( agent )

	overall.total = overall.total + 1
	overall.last_hit = os.time()

	if agents[ agent ] then
		increment( agents[ agent ] )
	else
		agents[ agent ] = {
			last_seen = os.time(),
			first_seen = os.time(),
			hits = 1
		}
	end

end


function _M.sweep()

	local to_remove = {}

	for agent, stats in pairs(agents) do
		if stats.last_seen + 86400 < os.time() then
			if stats.hits < 10 then
				to_remove[ agent ] = true
			end
		end
	end

	for agent in pairs(to_remove) do
		agents[ agent ] = nil
	end

end


function _M.scoreboard()
	return json.encode {
		agents = agents,
		overall = overall
	}
end

return _M
