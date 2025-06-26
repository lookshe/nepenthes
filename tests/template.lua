#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local template = require 'components.template'

require 'busted.runner'()
describe("Templating Module", function()

	it("Loads, renders a template", function()
		local x = template.render( 'list' )
		local res = x( { vars = {} } )

		assert.is_table(res)
		assert.is_string( res.rendered_output )
		assert.is_true( #(res.rendered_output) >= 10 )
		assert.is_match( '%<html%>', res.rendered_output )
	end)

	it("Bails on nonexistant file", function()
		assert.is_error(function()
			template.render('does-not-exist-iu34nr23uirn23jrn3j2r')
		end)
	end)

end)
