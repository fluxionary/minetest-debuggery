local f = string.format

minetest.register_chatcommand("get_item_meta", {
	params = "<key>",
	description = "get the metadata value for the item in hand",
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(name, key)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "you are not a player"
		end
		local wielded_item = player:get_wielded_item()
		local meta = wielded_item:get_meta()
		return true, f("%s=%s", key, meta:get_string(key))
	end,
})

minetest.register_chatcommand("set_item_meta", {
	params = "<key> [<value>]",
	description = "set the metadata value for the item in hand",
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(name, param)
		local key, value = param:match("^(%S+)%s*(.*)$")
		if not (key and value) then
			return false, "please supply a key and a value (no value to remove)"
		end
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "you are not a player"
		end
		local wielded_item = player:get_wielded_item()
		local meta = wielded_item:get_meta()
		meta:set_string(key, value)
		player:set_wielded_item(wielded_item)
		return true, f("%s=%s", key, value)
	end,
})
