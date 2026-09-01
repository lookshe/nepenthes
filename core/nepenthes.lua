#!/usr/bin/env lua5.4

local json = require 'dkjson'

local perihelion = require 'perihelion'

local stats = require 'components.stats'
local silo = require 'components.silo'
local frontend = require 'components.frontend'


silo.setup()

local app = perihelion.new()

app:get "/stats/silo/(%S+)/addresses" {
	function ( web, silo_filter )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.address_list( silo_filter ) )
		)
	end
}

app:get "/stats/silo/(%S+)/agents" {
	function ( web, silo_filter )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.agent_list( silo_filter ) )
		)
	end
}

app:get "/stats/silo/(%S+)" {
	function( web, silo_filter )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.compute( silo_filter ) )
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

app:get "/stats/addresses" {
	function ( web )
		web.headers['Content-type'] = 'application/json'
		return web:ok(
			json.encode( stats.address_list() )
		)
	end
}

app:get "/stats/buffer/from/(%d+%.%d+)" {
	function ( web, id )
		web.headers['Content-type'] = 'application/json'

		local stop_if_incomplete = false
		if web.HTTP_X_STOP_IF_INCOMPLETE then
			stop_if_incomplete = true
		end

		return web:ok(
			json.encode( stats.buffer( id, stop_if_incomplete ) )
		)
	end
}

app:get "/stats/buffer" {
	function ( web )
		web.headers['Content-type'] = 'application/json'

		local stop_if_incomplete = false
		if web.HTTP_X_STOP_IF_INCOMPLETE then
			stop_if_incomplete = true
		end

		return web:ok(
			json.encode( stats.buffer( nil, stop_if_incomplete ) )
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


app:head "/(.*)" {
	frontend.preprocess,
	frontend.HEAD
}

app:get "/(.*)" {
	frontend.preprocess,
	frontend.GET
}

return app
