local S = debuggery.S

minetest.register_chatcommand("whatisthis", {
	description = S("get the full itemstring of your wielded item"),
	func = function(player_name)
		local player = minetest.get_player_by_name(player_name)
		if not player then
			return false, S("you must be logged in to use this command.")
		end
		return true, player:get_wielded_item():to_string()
	end,
})
