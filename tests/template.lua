#!/usr/bin/env lua5.4

require 'luarocks.loader'
pcall(require, 'luacov')

local config = require 'components.config'
local template = require 'components.template'

config.templates = {
	'./tests/share/templates'
}

require 'busted.runner'()
describe("Templating Module", function()

	it("Loads a template, no yaml", function()

		local x = template.load( 'noyaml' )

		assert.is_table(x)
		assert.is_true(x.is_valid)
		assert.is_string(x.code)
		assert.is_match( '%<html%>', x.code )
		assert.is_match( '%{%{ content %}%}', x.code )

		assert.is_table(x.data)
		local count = 0
		for k in pairs(x.data) do	-- luacheck: ignore 213
			count = count + 1
		end
		assert.is_equal(2, count)

		--
		-- Defaults
		--
		assert.is_table(x.data.links)
		assert.is_table(x.data.links[1])
		assert.is_equal('footer_link', x.data.links[1].name)

		assert.is_equal(1, x.data.links[1].depth_min)
		assert.is_equal(5, x.data.links[1].depth_max)
		assert.is_equal(1, x.data.links[1].description_min)
		assert.is_equal(5, x.data.links[1].description_max)

	end)


	it("Loads a template, with yaml", function()

		local x = template.load( 'withyaml' )

		assert.is_table(x)
		assert.is_true(x.is_valid)
		assert.is_string(x.code)
		assert.is_match( '%<html%>', x.code )
		assert.is_match( '%{%{ content %}%}', x.code )

		assert.is_table(x.data)
		local count = 0
		for k in pairs(x.data) do	-- luacheck: ignore 213
			count = count + 1
		end


		--
		-- Set by template
		--
		assert.is_equal(2, count)
		assert.is_table(x.data.markov)

		assert.is_equal(1, #(x.data.markov))
		assert.is_table(x.data.markov[1])
		assert.is_equal('content', x.data.markov[1].name)
		assert.is_equal(15, x.data.markov[1]['min'])
		assert.is_equal(200, x.data.markov[1]['max'])

		--
		-- Defaults
		--
		assert.is_table(x.data.links)
		assert.is_table(x.data.links[1])
		assert.is_equal('footer_link', x.data.links[1].name)

		assert.is_equal(1, x.data.links[1].depth_min)
		assert.is_equal(5, x.data.links[1].depth_max)
		assert.is_equal(1, x.data.links[1].description_min)
		assert.is_equal(5, x.data.links[1].description_max)

	end)


	it("Gracefully handles a yaml-only template", function()

		local x = template.load( 'yamlonly' )

		assert.is_table(x)
		assert.is_false(x.is_valid)
		assert.is_string(x.code)
		assert.is_equal( '', x.code )

		assert.is_table(x.data)
		local count = 0
		for k in pairs(x.data) do	-- luacheck: ignore 213
			count = count + 1
		end

		assert.is_equal(2, count)
		assert.is_table(x.data.markov)
		assert.is_equal(1, #(x.data.markov))
		assert.is_table(x.data.links)
		assert.is_equal(1, #(x.data.links))

	end)


	it("Bails on nonexistant file", function()
		assert.is_error(function()
			template.load('does-not-exist-iu34nr23uirn23jrn3j2r')
		end)
	end)


	it("Can render", function()

		local x = template.load( 'noyaml' )
		local output = x:render {
			content = 'Test Test Test'
		}

		assert.is_string(output)
		assert.is_match('Test Test Test', output)
		assert.is_not_match('%{%{ content %}%}', output)

	end)


	it("Can find templates with multiple locations specified", function()

		config.templates = {
			'./tests/share/templates',
			'./tests/share/templates-second'
		}

		--
		-- Normal Location
		--
		local x = template.load( 'noyaml' )

		assert.is_table(x)
		assert.is_true(x.is_valid)
		assert.is_string(x.code)
		assert.is_match( '%<html%>', x.code )
		assert.is_match( '%{%{ content %}%}', x.code )

		assert.is_table(x.data)
		local count = 0
		for k in pairs(x.data) do	-- luacheck: ignore 213
			count = count + 1
		end
		assert.is_equal(2, count)

		assert.is_table(x.data.links)
		assert.is_table(x.data.links[1])
		assert.is_equal('footer_link', x.data.links[1].name)

		assert.is_equal(1, x.data.links[1].depth_min)
		assert.is_equal(5, x.data.links[1].depth_max)
		assert.is_equal(1, x.data.links[1].description_min)
		assert.is_equal(5, x.data.links[1].description_max)

		--
		-- Side Location
		--
		local y = template.load( 'another' )

		assert.is_table(y)
		assert.is_true(y.is_valid)
		assert.is_string(y.code)
		assert.is_match( '%<html%>', y.code )
		assert.is_match( '%{%{ content %}%}', y.code )

		assert.is_table(y.data)
		local count2 = 0
		for k in pairs(y.data) do	-- luacheck: ignore 213
			count2 = count2 + 1
		end
		assert.is_equal(2, count2)

		assert.is_table(y.data.links)
		assert.is_table(y.data.links[1])
		assert.is_equal('main', y.data.links[1].name)

		assert.is_equal(10, y.data.links[1].depth_min)
		assert.is_equal(15, y.data.links[1].depth_max)
		assert.is_equal(10, y.data.links[1].description_min)
		assert.is_equal(55, y.data.links[1].description_max)

	end)

end)
