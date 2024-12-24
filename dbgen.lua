#!/usr/bin/env lua5.3


---
-- DBGenerator automatically generates the schema of a fresh database.
-- Properly used, it can also automatically upgrade an existing
-- schema to a newer version.
--
local _M = {}


---
-- Initalization SQL for the version table.
--
local vtable_schema = {
	SQLite3 = {
		[[
		create table if not exists version (
			id not null primary key,
			start integer not null
		);
		]],

		[[
		insert or ignore into version values ( 1, 2 );
		]]
	}
}





---
-- Sets up the provided schema.
--
-- A clean database will be populated with all necessary objects.
-- An existing database will be upgraded to a new one, provided
-- that the automatically created table `version` has not been
-- tampered with. Re-throws any database errors encountered.
--
-- @param type The database type - currently must be 'SQLite3'
-- @param db An already open LuaDBI database handle
-- @param schema A table of statements that represents the DDL, and any
--					upgrade/initalization DML necessary to generate
--					or upgrade the schema. The table is assumed to be
--					an array of strings, each one of which is exactly
--					one standalone statement. They are executed
--					sequentially until the schema is complete, assuming
--					no errors occur.
--
function _M.setup( db_type, db, schema )

	assert(vtable_schema[db_type], "Unknown database type")
	local vtable = vtable_schema[db_type]

	-- detect what schema version, if any, and run
	-- the needed statements
	local version = db:open_table {
		name = 'version',
		key = 'id'
	}

	local row

	local res = pcall(function()
		row = version[1]
	end)

	if not res then
		for i = 1, #vtable do
			db:exec( vtable[i] )
		end
	end

	-- nil row means fresh database, re-run everything
	if not row then
		row = {
			start = 1
		}
	end

	for i = row.start, #schema do
		db:exec( schema[i] )
		row.start = i + 1
	end

	-- saves the schema version
	version[1] = row

end


return _M
