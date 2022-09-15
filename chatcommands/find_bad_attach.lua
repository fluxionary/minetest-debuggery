--[[
on IRC:

<mazes_83> I got floods of: LuaEntitySAO::step() id=nnnn is attached to nonexistent parent. This is a bug.

i wrote the following, but unfortunately the parent is cleared immediately after that log, in the c++ code.
but keeping this cuz it might be usefor for something similar.

minetest.register_chatcommand("find_bad_attach", {
	description = "finds luaentities attached to non-existent things",
	privs = {[debuggery.settings.admin_priv] = true},
	func = function(name)
		local count = 0
		for _, entity in pairs(minetest.luaentities) do
			local object = entity.object
			local parent = object:get_attach()
			if parent then
				local ent = parent:get_luaentity()

				if not ent then
					minetest.chat_send_player(name, ("%s @ %s is attached to nonexistent parent"):format(
						entity.name, minetest.pos_to_string(object:get_pos())
					))
				end
				count = count + 1
			end
		end
		return true, ("found %s objects attached to non-existent parents"):format(count)
	end,
})
]]
