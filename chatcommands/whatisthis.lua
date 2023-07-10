local S = debuggery.S

minetest.register_chatcommand("whatisthis", {
	description = S("get the full itemstring of wielded item"),
	func = function(player_name)
		local player = minetest.get_player_by_name(player_name)
		if not player then
			return false, S("you are not a real player")
		end
		return true, player:get_wielded_item():to_string()
	end,
})
