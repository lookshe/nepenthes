#!/usr/bin/env lua5.3

local perihelion = require 'perihelion'
local lustache = require 'lustache'
local digest = require 'openssl.digest'
local config = require 'daemonparts.config'
local mers = require 'random'
local cqueues = require 'cqueues'

local stats = require 'stats'


--
-- Load Dictionary
--
local dict = {}
local f = io.open("/usr/share/dict/words", "r")
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

		web.CONTENT_TYPE = 'application/json'
		return web:ok( stats.scoreboard() )
	end
}

app:get "/(.*)" {
	function ( web )

		local dig = digest.new()
		local hash = dig:final( web.PATH_INFO )
		local rnd = mers.new()

		rnd:seed(string.unpack( "j", hash ))

		local function bounded_val( upper, lower )
			return( math.floor(rnd:value() * (upper - lower)) + lower)
		end

		local function getword()
			return dict[ bounded_val( #dict, 0 ) ]
		end

		local function buildtab( size )
			local ret = {}

			for i = 1, size do
				ret[ #ret + 1 ] = getword()
			end

			return ret
		end


		local len = bounded_val( 10, 5 )
		local links = {}
		for i = 1, len do
			links[ #links + 1 ] = {
				description = getword(),
				link = table.concat(buildtab( bounded_val( 5, 1 ) ), "/")
			}
		end

		local ret = {
			links = links,
			header = getword(),
			prefix = config.prefix
		}

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
		cqueues.sleep( bounded_val(config.max_wait or 10, 1) )

		return ret

	end,

	render( 'list' )
}

stats.load()
return app
