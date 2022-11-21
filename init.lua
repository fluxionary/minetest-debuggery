local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

assert(
	type(futil.version) == "number" and futil.version >= os.time({year = 2022, month = 10, day = 24}),
	"please update futil"
)

debuggery = {
	author = "flux",
	license = "AGPL_v3",
	version = os.time({year = 2022, month = 10, day = 26}),
	fork = "flux",

	modname = modname,
	modpath = modpath,
	mod_storage = minetest.get_modstorage(),
	S = S,

	has = {
		areas = minetest.get_modpath("areas"),
		worldedit = minetest.get_modpath("worldedit"),
	},

	log = function(level, messagefmt, ...)
		return minetest.log(level, ("[%s] %s"):format(modname, messagefmt:format(...)))
	end,

	dofile = function(...)
		return dofile(table.concat({modpath, ...}, DIR_DELIM) .. ".lua")
	end,
}

debuggery.dofile("settings")
debuggery.dofile("privs")
debuggery.dofile("util")
debuggery.dofile("chatcommands", "init")

debuggery.mod_storage = nil
