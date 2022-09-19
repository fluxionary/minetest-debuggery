minetest.register_chatcommand("memory", {
	description = "Get server\"s Lua memory usage",
	privs = {[debuggery.settings.admin_priv] = true},
	func = function(name, param)
		minetest.chat_send_player(name, ("Lua is using %uMB out of 1024"):format(collectgarbage("count") / 1024))
	end
})

local registered = {}

minetest.register_chatcommand("memory_toggle", {
	description = "Get server\"s Lua memory usage periodically",
	privs = {[debuggery.settings.admin_priv] = true},
	func = function(name, param)
		if registered[name] then
			registered[name] = nil
		else
			registered[name] = true
		end
	end
})

local period = 1
local elapsed = 0

minetest.register_globalstep(function(dtime)
	elapsed = elapsed + dtime
	if elapsed < period then
		return
	end
	elapsed = 0
	local amt = collectgarbage("count") / 1024
	for name in pairs(registered) do
		minetest.chat_send_player(name, ("Lua is using %uMB out of 1024"):format(amt))
	end
end)
