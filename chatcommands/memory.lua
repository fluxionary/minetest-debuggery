local f = string.format
local S = debuggery.S

minetest.register_chatcommand("memory", {
	description = S("get server's lua memory usage"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(name, param)
		return true, S("Lua is using @1MiB", f("%.1f", collectgarbage("count") / 1024))
	end,
})

local registered = {}

minetest.register_chatcommand("memory_toggle", {
	description = "get server's lua memory usage periodically",
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(name, param)
		if registered[name] then
			registered[name] = nil
		else
			registered[name] = true
		end
	end,
})

local period = 15
local elapsed = 0

minetest.register_globalstep(function(dtime)
	elapsed = elapsed + dtime
	if elapsed < period then
		return
	end
	elapsed = 0
	local amt = collectgarbage("count") / 1024
	for name in pairs(registered) do
		minetest.chat_send_player(name, S("Lua is using @1MiB", f("%.1f", amt)))
	end
end)
