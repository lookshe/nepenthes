#!/usr/bin/env lua5.4

local config = require 'components.config'
--local seed = require 'components.seed'
local wordlist = require 'components.wordlist'
local rng_factory = require 'components.rng'
local urlgen = require 'components.urlgen'
local template = require 'components.template'
--local markov = require 'components.markov'



local wl = wordlist.new( config.words )
--local instance_seed = seed.get()

--local mk = markov.new()
--mk:train_file( config.markov_corpus )


local _methods = {}

function _methods.is_bogon( this )

	return this._is_bogon

end

--function _methods.seed( this, seed )

	--if seed then
		--this._seed = seed
	--end

	--return this._seed

--end

function _methods.urllist( this )

	assert( not this._is_bogon, 'Unable to load URLs: bogon request' )

	local ret = {}
	local count = #(this.template.data.links)

	if this.template.data.link_array then
		count = count + this.rnd:between(
			this.template.data.link_array.max_count,
			this.template.data.link_array.min_count
		)
	end

	for i = 1, count do
		ret[ i ] = {
			description = wl.choose( this.rnd ),
			link = this.ug:create( this.rnd )
		}
	end

	return ret

end

function _methods.load_markov( this, markov )

	assert( not this._is_bogon, 'Unable to load markov: bogon request' )

	-- Markov time
	for i, v in ipairs( this.template.data.markov ) do	-- luacheck: ignore 213
		this.vars[v.name] = markov:babble( this.rnd, v.min, v.max )
	end

end


function _methods.render( this )

	assert( not this._is_bogon, 'Unable to render: bogon request' )

	local links = this:urllist()
	--local vars = {}

	-- Named links
	for i, v in ipairs( this.template.data.links ) do	-- luacheck: ignore 213
		this.vars[ v.name ] = table.remove( links )
	end

	-- Optional link array
	this.vars['links'] = links

	return this.template:render( this.vars )

end



local _M = {}

function _M.new( prefix, url )

	local ret = {
		ug = urlgen.new( wl, prefix ),
		template = template.load( 'default' ),
		url = url,
		vars = {}
	}

	ret._is_bogon = ret.ug:check( url )

	if not ret.is_bogon then
		ret.rnd = rng_factory.new( url )
	end

	return setmetatable( ret, { __index = _methods } )

end

return _M
