#!/usr/bin/env lua5.3

local config = require 'components.config'
local digest = require 'openssl.digest'
local json = require 'dkjson'
local basexx = require 'basexx'


---
-- While doing a heavy overhaul on this code, I noticed that Ludic
-- (Nikhil Suresh) had just posted on LinkedIn "My resolution for 2025
-- is to get everyone that resorts to JSON databases prematurely fired."
--
-- I humbly accept my fate, sir.
--
-- I do have my reasons here. The original was just 'persist stats,
-- somehow' with minimal dependencies that I could sling out fast,
-- the SQLite came later as a way to access a massive Markov corpus
-- without consuming all of the system's RAM. I haven't ported this
-- to SQLite because, it's essentially a hit counter, and I've had
-- previous expirements with SQLite as a hit counter - or saving
-- frequently updated web session information - end horribly. It simply
-- doesn't scale at that transaction rate.
--
-- "But it's a tarpit", you may whine, "It's not supposed to scale!"
-- I mean... sure. The whole point is to have an egregious user
-- experience for any hapless sucker that gets stuck in here. It's named
-- after a carnivorous plant that traps insects inside of hollows leafs
-- in a way that the insect can never find the exit before being digested.
-- But, the host running the tarpit shouldn't burn all it's resources on
-- it if possible. If the goal is to protect yourself from scraping, the
-- host needs to burn minimal CPU cycles compared to the scraper. SQLite
-- simply didn't hold up.
--
-- And I want this self-contained enough that usable stats (to build
-- blocklists, for instance, and just idle admin curiousity) without
-- setting up a full blown DBMS like Postgres.
--
-- I suppose I should build a hook to log wherever if you want to build
-- a real database to analyze.
--
local agents = {}
local ips = {}
local overall = {
	total = 0,
	last_hit = 0
}


local agent_hash_cache = {}


local _M = {}


local function increment( stattable, tag, agent )

	local ag = stattable[tag]

	if ag then
		ag.last_seen = os.time()
		ag.hits = ag.hits + 1
	else
		stattable[tag] = {

			-- if tables cannot contain nil, so setting agstring to
			-- nil won't make it's way into JSON if the IP table is
			-- being manipulated.
			agstring = agent,

			last_seen = os.time(),
			first_seen = os.time(),
			hits = 1
		}
	end

end


---
-- Logging hits: does what you think.
--
function _M.log_hit( agent, ip )

	---
	-- Filters. More of this is needed, more flexibility is needed,
	-- more dealing with multiple versions is needed, basically I think
	-- I need to build a proper user-agent parser that figures this out
	-- and go from there.
	--
	if agent:match("Mastodon") then
		return
	end

	if agent:match("http%:%/%/www%.google%.com%/bot%.html") then
		agent = 'Googlebot (multiple agents condensed)'
	end

	if agent:match("%(compatible%;% GoogleOther%)") then
		agent = 'GoogleOther (multiple agents condensed)'
	end


	---
	-- User-agents make terrible table keys, so, hash them. Otherwise
	-- pulling data out with (as an example) jq is near impossible.
	--
	-- As hashing is computationally expensive at scale, keep a
	-- cache.
	--
	local hash = agent_hash_cache[ agent ]
	if not hash then
		local dig = digest.new('sha1')
		hash = basexx.to_hex( dig:final( agent ) ):lower()
		agent_hash_cache[ agent ] = hash
	end


	---
	-- Overall stats, good for a quick overview.
	--
	overall.total = overall.total + 1
	overall.last_hit = os.time()


	---
	-- Log 'em
	--
	increment( agents, hash, agent )
	increment( ips, ip )

end


---
-- Delete anything deemed forgettable.
--
function _M.sweep()

	local agents_to_remove = {}

	for agent, stats in pairs(agents) do
		if stats.last_seen + config.forget_time < os.time() then
			if stats.hits < config.forget_hits then
				agents_to_remove[ agent ] = true
			end
		end
	end

	for agent in pairs(agents_to_remove) do
		agents[ agent ] = nil
	end


	local ips_to_remove = {}

	for ip, stats in pairs(ips) do
		if stats.last_seen + config.forget_time < os.time() then
			if stats.hits < config.forget_hits then
				ips_to_remove[ ip ] = true
			end
		end
	end

	for ip in pairs(ips_to_remove) do
		ips[ ip ] = nil
	end

	--
	-- Because lazy, save here too. That way it'll be periodic,
	-- but not too often.
	--
	if config.persist_stats then

		local f = assert(io.open( config.persist_stats, 'w' ))
		f:write( json.encode( _M.scoreboard_all(0)) )
		f:close()

	end

end



local function filter( statstable, above )

	local function is_good( stat )
		if stat.last_seen + config.forget_time < os.time() then
			return false
		end

		if stat.hits < above then
			return false
		end

		return true
	end

	local send = {}

	for name, stat in pairs(statstable) do
		if is_good(stat) then
			send[ name ] = stat
		end
	end

	return send

end


---
-- Provide all user-agents seen above a certain hit count.
--
function _M.agents( above )
	return filter( agents, above or 10 )
end


---
-- Provide all ip address seen above a certain hit count.
--
function _M.ips( above )
	return filter( ips, above or 10 )
end


---
-- Provide all known statistics
--
function _M.scoreboard_all( above )
	return {
		agents = _M.agents( above ),
		ips = _M.ips( above ),
		overall = overall
	}
end


---
-- Pull existing stats from disk, if present.
--
function _M.load()

	if config.persist_stats then

		local res, err = pcall(function()
			local f = assert(io.open( config.persist_stats, 'r' ))
			local ret = f:read("*all")
			f:close()

			local data = assert(json.decode( ret, 1, nil))
			if data then
				if data.agents then
					agents = data.agents or {}
				end

				if data.ips then
					ips = data.ips or {}
				end

				if data.overall then
					overall = data.overall or {}
				end
			end
		end)

		if not res then
			print("Stats not loaded:", err)
		end

	end

end

return _M
