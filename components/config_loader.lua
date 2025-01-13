#!/usr/bin/env lua5.4

local yaml = require 'tinyyaml'

local function iterate( prefix, conf, data )

	for k, v in pairs(data) do
		if conf[k] == nil then
			error("Unknown configuration name: " ..  tostring(k))

		elseif type(conf[k]) == 'table' then

			local tryf = function()
				return conf[k]( table.concat({prefix, k }, '.' ), v )
			end

			local res, newtab = pcall( tryf )

			if not res then
				iterate( table.concat({prefix, k }, '.' ), conf[k], v )
			else
				conf[k] = newtab
			end

		elseif type(v) ~= type(conf[k]) then
			error("Incorrect data type for " .. tostring(k) .. " - should be: " .. type(conf[k]))

		else
			conf[k] = v
		end
	end

	-- delete any default-nils
	for k, v in pairs(conf) do
		if type(v) == 'table' then
			local mt = getmetatable(v)
			if mt then
				if mt.isnil then
					conf[k] = nil
				end
			end
		end
	end

end


local function loadconfig( t, path )

	local f, err = io.open( path, "r" )
	if not f then
		print("No load:", err)
		return false, err
	end


	local x
	local res, err2 = pcall(function()
		local data = assert(f:read("*all"))
		x = assert(yaml.parse(data))
		f:close()

	end)

	if not res then
		print("Failed load:", err2)
		return false, err2
	end

	iterate( '', t, x )

	return true

end


local _M = {}


function _M.array( tab )

	return setmetatable(tab, { __call = function( x, prefix, data )	-- luacheck: ignore 212

		local ret = {}

		for i, v in ipairs(data) do
			ret[i] = v
		end

		return ret

	end })

end


function _M.lookup( tab )

	local newtab = {}

	for i, v in ipairs(tab) do	-- luacheck: ignore 213
		newtab[v] = true
	end

	return setmetatable(newtab, { __call = function( x, prefix, data )	-- luacheck: ignore 212

		local ret = {}

		for i, v in ipairs(data) do	-- luacheck: ignore 213
			ret[v] = true
		end

		return ret

	end })

end

function _M.default_nil( valtype )

	return setmetatable( {}, {

		isnil = true,

		__call = function( t, prefix, data )	-- luacheck: ignore 212
			if type(data) == valtype then
				return data
			else
				error("Incorrect data type for " .. prefix .. " - should be: " .. valtype .. " or undefined")
			end
		end

	})

end


function _M.prepare( tab )

	return setmetatable( tab, {

		__call = function( t, paths )

			if type(paths) == 'string' then
				return loadconfig(t, paths)
			elseif type(paths) == 'table' then
				for i, path in ipairs(paths) do	-- luacheck: ignore 213
					if loadconfig(t, path) then
						return
					end
				end
			else
				error("Unknown config type")
			end

		end
	})

end

return _M
