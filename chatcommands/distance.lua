if not (debuggery.has.areas or debuggery.has.worldedit) then
	return
end

local f = string.format
local S = debuggery.S
local get_bounds = debuggery.util.get_bounds

minetest.register_chatcommand("/distance", {
	description = S("get the distance between two positions (areas or worldedit)"),
	func = function(player_name)
		local pos1, pos2 = get_bounds(player_name)
		if not (pos1 and pos2) then
			return false, S("please mark two points using either areas or worldedit")
		end

		return true, f("%.1f", vector.distance(pos1, pos2))
	end,
})
