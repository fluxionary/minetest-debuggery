minetest.register_chatcommand("whatisthis", {
	description = "get the full itemstring of wielded item",
	func = function(player_name)
		local player = minetest.get_player_by_name(player_name)
		minetest.chat_send_player(player_name, player:get_wielded_item():to_string())
		return
	end
})
