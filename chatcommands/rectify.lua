local pi = math.pi

local S = debuggery.S

minetest.register_chatcommand("rectify", {
	description = S("sets pitch and yaw to (0, 0)"),
	func = function(name, param)
		local player = minetest.get_player_by_name(name)

		param = param:trim():lower()

		if param == "e" or param == "east" then
			player:set_look_vertical(0)
			player:set_look_horizontal(-pi / 2)
		elseif param == "s" or param == "south" then
			player:set_look_vertical(0)
			player:set_look_horizontal(pi)
		elseif param == "w" or param == "west" then
			player:set_look_vertical(0)
			player:set_look_horizontal(pi / 2)
		elseif param == "u" or param == "up" then
			player:set_look_vertical(-pi / 2)
		elseif param == "d" or param == "down" then
			player:set_look_vertical(pi / 2)
		else
			player:set_look_vertical(0)
			player:set_look_horizontal(0)
		end

		return true
	end,
})
