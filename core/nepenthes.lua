#!/usr/bin/env lua5.4

local cqueues = require 'cqueues'
local json = require 'dkjson'

local perihelion = require 'perihelion'
local output = require 'daemonparts.output'

local config = require 'components.config'
local stats = require 'components.stats'
local stutter = require 'components.stutter'
local seed = require 'components.seed'
local rng_factory = require 'components.rng'
local markov = require 'components.markov'
local wordlist = require 'components.wordlist'
local template = require 'components.template'
local urlgen = require 'components.urlgen'



--
-- Load Dictionary
--
local wl = wordlist.new( config.words )

--
-- Seed is important
--
local instance_seed = seed.get()

--
-- Train Markov corpus
--
local mk = markov.new()
mk:train_file( config.markov_corpus )




local app = perihelion.new()

app:get "/stats/markov" {
	function( web )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( mk:stats() )
		)
	end
}

app:get "/stats/words" {
	function( web )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( { count = wl.count() } )
		)
	end
}

app:get "/stats" {
	function ( web )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.compute() )
		)
	end
}

app:get "/stats/addresses" {
	function ( web )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.address_list() )
		)
	end
}

app:get "/stats/agents" {
	function ( web )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.agent_list() )
		)
	end
}

--
-- Some crawlers HEAD every url before GET. Since it will always
-- result in a document, don't do anything.
--
app:head "/(.*)" {
	function( web )
		local prefix = config.prefix

		if web.HTTP_X_PREFIX then
			prefix = web.HTTP_X_PREFIX
		end

		local ug = urlgen.new( wl, prefix )
		if ug:check( web.PATH_INFO ) then
			output.notice("Bogon URL:", web.REMOTE_ADDR, "asked for", web.PATH_INFO)
			return web:notfound()
		end

		web.headers['content-type'] = 'text/html; charset=UTF-8'
		return web:ok("")
	end
}




local function checkpoint( times, name )
	times[ #times + 1 ] = {
		name = name,
		at = cqueues.monotime()
	}
end

local function log_checkpoints( times, send_delay )

	local parts = {}

	for i, cp in ipairs( times ) do	-- luacheck: ignore 213
		if cp.name ~= 'start' then
			parts[ #parts + 1 ] = string.format("%s: %f", cp.name, cp.at - times[1].at)
		end
	end

	parts[ #parts + 1 ] = string.format("send_delay: %f", send_delay)
	output.info("req len: " .. table.concat( parts, ', ' ))

end


app:get "/(.*)" {
	function ( web )

		local timestats = {}
		checkpoint( timestats, 'start' )

		local rnd = rng_factory.new( instance_seed, web.PATH_INFO )

		local ret = {
			header = wl.choose( rnd ),
			prefix = config.prefix
		}

		--
		-- Allow attaching to multiple places via nginx configuration
		-- alone.
		--
		if web.HTTP_X_PREFIX then
			ret.prefix = web.HTTP_X_PREFIX
		end


		local ug = urlgen.new( wl, ret.prefix )


		if ug:check( web.PATH_INFO ) then
			output.notice("Bogon URL:", web.REMOTE_ADDR, "asked for", web.PATH_INFO)
			cqueues.sleep( rnd:between( 5, 1 ) )
			return web:notfound("Nothing exists at this URL")
		end


		local len = rnd:between( 10, 5 )
		local links = {}
		for i = 1, len do
			links[ i ] = {
				description = wl.choose( rnd ),
				link = ug:create( rnd )
			}
		end

		ret.links = links
		checkpoint( timestats, 'words' )

		ret.content = mk:babble( rnd, config.markov_min, config.markov_max )
		ret.title = mk:babble( rnd, 5, 15 )

		checkpoint( timestats, 'markov' )

		--
		-- Oh you think this was supposed to be fast?
		--
		ret.sandbag_rate = rnd:between(config.max_wait or 10, config.min_wait or 1)
		checkpoint( timestats, 'total' )
		log_checkpoints( timestats, ret.sandbag_rate )
		ret.time_spent = timestats[ #timestats ].at - timestats[1].at

		return ret

	end,

	template.render( 'default' ),

	function( web )

		local page = web.vars.rendered_output

		stats.log {
			address = web.REMOTE_ADDR,
			uri = web.PATH_INFO,
			agent = web.HTTP_X_USER_AGENT,
			silo = 'default',
			bytes = #page,
			when = cqueues.monotime(),
			response = 200,
			delay = web.vars.sandbag_rate,
			cpu = web.vars.time_spent
		}

		if web.vars.sandbag_rate then
			return '200 OK', web.headers, stutter.delay_iterator(
				page,
				stutter.generate_pattern( web.vars.sandbag_rate, #page )
			)
		end

		return web:ok( page )

	end
}

return app
