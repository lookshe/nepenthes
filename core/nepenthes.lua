#!/usr/bin/env lua5.4

local perihelion = require 'perihelion'
local lustache = require 'lustache'
local digest = require 'openssl.digest'
local output = require 'daemonparts.output'
local config = require 'components.config'
local cqueues = require 'cqueues'
local json = require 'dkjson'

local seed = require 'components.seed'
local stats = require 'components.stats'
local xorshiro = require 'components.xorshiro'
local markov


if config.markov then
	markov = require 'components.markov'
end



--
-- Load Dictionary
--
local dict = {}
local f = io.open( config.words, "r" )
for line in f:lines() do
	if not line:match("%'") then
		dict[ #dict + 1 ] = line
	end
end


---
-- Pull a template code from disk.
--
local function load_template( path )

	local template_path = string.format(
		"%s/%s.lustache",
			config.templates,
			path
	)

	local template_file = assert(io.open(template_path, "r"))
	local ret = template_file:read("*all")
	template_file:close()

	return ret

end


---
-- Render the page through a template engine.
--
local function render( template )

	local iter = function( s, rate )
		--
		-- We have '#s' bytes to dispense through 'rate' seconds.
		-- How long do we delay and how much per? Let them have a
		-- taste of something every second, to keep them on the line.
		--
		local chunk_size = #s
		local delay = rate

		repeat
			chunk_size = chunk_size // 2
			delay = delay / 2
		until delay < 1

		return function()
			if #s <= 0 then
				return nil
			end

			local ret = s:sub(1, chunk_size)
			s = s:sub(chunk_size + 1, #s)
			cqueues.sleep(delay)

			return ret
		end
	end

	return function( web )

		local template_code = load_template( 'toplevel' )
		local prt = {}

		web.vars.app_path = config.prefix
		prt[ 'content' ] = load_template( template )

		rawset(lustache, 'partial_cache', {})
		--return web:ok(  )
		local ret = lustache:render(template_code, web.vars, prt)
		if web.vars.sandbag_rate then
			return '200 OK', web.headers, iter( ret, web.vars.sandbag_rate )
		end

		return web:ok( ret )
	end

end


local app = perihelion.new()

app:get "/stats" {
	function ( web )
		stats.sweep()

		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.scoreboard_all() )
		)
	end
}

local function agents( web, above )
	stats.sweep()
	web.headers['Content-type'] = 'application/json'
	return web:ok(
		json.encode( stats.agents( tonumber(above) ))
	)
end

app:get "/stats/agents" { agents }
app:get "/stats/agents/" { agents }
app:get "/stats/agents/(.*)" { agents }
app:get "/stats/agents/(.*)/" { agents }



local function ips( web, above )
	stats.sweep()
	web.headers['Content-type'] = 'application/json'
	return web:ok(
		json.encode( stats.ips( tonumber(above) ))
	)
end

app:get "/stats/ips" { ips }
app:get "/stats/ips/" { ips }
app:get "/stats/ips/(.*)" { ips }
app:get "/stats/ips/(.*)/" { ips }


app:post "/train" {
	function ( web )
		if not config.markov then
			error("Markov not enabled")
		end

		if web.CONTENT_TYPE ~= 'text/plain' then
			error("Unknown content type for training")
		end

		local count = markov.train( web.POST_RAW )

		web.headers['Content-Type'] = 'text/plain'
		return web:ok( "trained " .. count .. " tokens" )
	end
}

local instance_seed = seed.get()

local function checkpoint( times, name )
	times[ #times + 1 ] = {
		name = name,
		at = cqueues.monotime()
	}
end

local function log_checkpoints( times )

	local prev = 0
	local parts = {}

	for i, cp in ipairs( times ) do	-- luacheck: ignore 213
		if cp.name ~= 'start' then
			parts[ #parts + 1 ] = string.format("%s: %f", cp.name, cp.at - prev)
		end

		prev = cp.at
	end

	output.info("req len: " .. table.concat( parts, ', ' ))

end

app:get "/(.*)" {
	function ( web )

		local timestats = {}
		checkpoint( timestats, 'start' )

		local dig = digest.new( 'sha1' )
		dig:update( instance_seed )
		local hash = dig:final( web.PATH_INFO )

		local rnd = xorshiro.new( string.unpack( "jjjj", hash ) )

		local function getword()
			return dict[ rnd:between( #dict, 0 ) ]
		end

		local function buildtab( size )
			local ret = {}

			for i = 1, size do
				ret[ i ] = getword()
			end

			return ret
		end



		local len = rnd:between( 10, 5 )
		local links = {}
		for i = 1, len do
			links[ i ] = {
				description = getword(),
				link = table.concat(buildtab( rnd:between( 5, 1 ) ), "/")
			}
		end

		local ret = {
			links = links,
			header = getword(),
			prefix = config.prefix
		}

		checkpoint( timestats, 'words' )

		--
		-- Markov enabled?
		--
		if config.markov then
			ret.content = markov.babble( rnd )
		end

		checkpoint( timestats, 'markov' )

		--
		-- Allow attaching to multiple places via nginx configuration
		-- alone.
		--
		if web.HTTP_X_PREFIX then
			ret.prefix = web.HTTP_X_PREFIX
		end


		--
		-- Keep stats about out prey
		--
		stats.log_hit( web.HTTP_X_USER_AGENT, web.REMOTE_ADDR )


		--
		-- Oh you think this was supposed to be fast?
		--
		ret.sandbag_rate = rnd:between(config.max_wait or 10, config.min_wait or 1)
		checkpoint( timestats, 'total' )
		log_checkpoints( timestats )

		return ret

	end,

	render( 'list' )
}

stats.load()

if config.persist_stats then
	-- save stats to disk on graceful shutdown.
	function app.shutdown_hook()
		stats.sweep()
	end
end

return app
