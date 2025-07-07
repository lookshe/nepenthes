#!/usr/bin/env lua5.4

local lustache = require 'lustache'
local config = require 'components.config'

local _M = {}

---
-- Pull a template code from disk.
--
local function load_template( path )

	local template_path = string.format(
		"%s/%s.lustache",
			config.templates,
			path
	)

	local template_file <close> = assert(io.open(template_path, "r"))
	local ret = template_file:read("*all")

	return ret

end


-- Render the page through a template engine.
--
function _M.render( template )

	local template_code = load_template( template )
	return function( web )
		web.vars.app_path = config.prefix
		web.vars.rendered_output = lustache:render(template_code, web.vars, {})
		return web.vars
	end

end

return _M
