minetest.register_chatcommand("rectify", {
	description = "Sets pitch and yaw to (0, 0)",
	func = function(name)
		local player = minetest.get_player_by_name(name)

		player:set_look_vertical(0)
		player:set_look_horizontal(0)

		return true
	end,
})
