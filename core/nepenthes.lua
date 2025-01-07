#!/usr/bin/env lua5.4

local perihelion = require 'perihelion'
local lustache = require 'lustache'
local digest = require 'openssl.digest'
local config = require 'config'
local cqueues = require 'cqueues'

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

	return function( web )

		local template_code = load_template( 'toplevel' )
		local prt = {}

		web.vars.app_path = config.prefix
		prt[ 'content' ] = load_template( template )

		rawset(lustache, 'partial_cache', {})
		return web:ok( lustache:render(template_code, web.vars, prt) )
	end

end


local app = perihelion.new()

app:get "/stats" {
	function ( web )
		stats.sweep()

		web.headers['Content-Type'] = 'application/json'
		return web:ok( stats.scoreboard() )
	end
}

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

app:get "/(.*)" {
	function ( web )

		local dig = digest.new( 'sha256' )
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

		--
		-- Markov enabled?
		--
		if config.markov then
			ret.content = markov.babble( rnd )
		end

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
		stats.log_agent( web.HTTP_X_USER_AGENT )

		--
		-- Oh you think this was supposed to be fast?
		--
		cqueues.sleep( rnd:between(config.max_wait or 10, 1) )

		return ret

	end,

	render( 'list' )
}

stats.load()
return app
