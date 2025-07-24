#!/usr/bin/env lua5.4

local cqueues = require 'cqueues'
local json = require 'dkjson'

local perihelion = require 'perihelion'
local output = require 'daemonparts.output'
local corewait = require 'daemonparts.corewait'

local config = require 'components.config'
local stats = require 'components.stats'
local stutter = require 'components.stutter'
local markov = require 'components.markov'
local request = require 'components.request'



--
-- Load Dictionary
--
--local wl = wordlist.new( config.words )

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

--app:get "/stats/words" {
	--function( web )
		--web.headers['Content-type'] = 'application/json'
		--return web:ok(
			--json.encode( { count = wl.count() } )
		--)
	--end
--}

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

	if send_delay then
		parts[ #parts + 1 ] = string.format("send_delay: %f", send_delay)
	end

	output.info("req len: " .. table.concat( parts, ', ' ))

end


---
-- Some crawlers HEAD every url before GET. Since it will always result
-- in a document (request has already cleared the bogon check during
-- setup), don't do anything.
--
app:head "/(.*)" {
	function( web )

		local req = request.new( web.HTTP_X_PREFIX, web.PATH_INFO )
		if req:is_bogon() then
			output.notice("Bogon URL:", web.REMOTE_ADDR, "asked for", web.PATH_INFO)
			corewait.poll( 5 )
			return web:notfound("Nothing exists at this URL")
		end

		web.headers['content-type'] = 'text/html; charset=UTF-8'
		return web:ok("")

	end
}

---
-- Actual tarpitting happens here.
--
app:get "/(.*)" {
	function( web )

		local ts = {}
		checkpoint( ts, 'start' )

		local req = request.new( web.HTTP_X_PREFIX, web.PATH_INFO )
		if req:is_bogon() then
			output.notice("Bogon URL:", web.REMOTE_ADDR, "asked for", web.PATH_INFO)
			corewait.poll( 5 )
			return web:notfound("Nothing exists at this URL")
		end

		checkpoint( ts, 'preprocess' )
		req:load_markov( mk )
		checkpoint( ts, 'markov' )
		local page = req:render()
		local wait = req:send_delay()
		checkpoint( ts, 'rendering' )
		log_checkpoints( ts, wait )

		local time_spent = ts[ #ts ].at - ts[1].at

		--
		-- Somewhat "magic": Utilize to-be-closed variable to log that
		-- the request has completed when this function terminates,
		-- regardless of how this function terminated.
		--
		local logged = stats.build_entry {
			address = web.REMOTE_ADDR,
			uri = web.PATH_INFO,
			agent = web.HTTP_X_USER_AGENT,
			silo = web.HTTP_X_PREFIX or 'default',
			bytes = #page,
			bytes_sent = 0,
			when = cqueues.monotime(),
			response = 200,
			delay = wait,
			cpu = time_spent
		}

		stats.log( logged )

		web.headers['content-type'] = 'text/html; charset=UTF-8'
		return '200 OK', web.headers, stutter.delay_iterator (
				page, logged,
				stutter.generate_pattern( wait, #page )
			)
	end
}

return app
