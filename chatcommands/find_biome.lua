-- not sure how this compares to https://content.minetest.net/packages/Wuzzy/findbiome/, it's slow but simple

local f = string.format

local S = debuggery.S

minetest.register_chatcommand("find_biome", {
	description = S("toggles logging when an entity's on_step takes too long"),
	params = S("<biome_name> [<radius>=32]"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, f("you must be logged in to use this.")
		end
		local biome_name, radius = param:match("^%s*(%S+)%s+(%S+)%s*$")
		biome_name = biome_name or param:match("^%s*(%S+)%s*$")
		radius = tonumber(radius) or 32
		local biome_id = minetest.get_biome_id(biome_name)
		if not biome_id then
			return false, f("unknown biome %q", biome_name)
		end
		local pos0 = player:get_pos():round()
		local minp, maxp = pos0:subtract(radius), pos0:add(radius)
		local va = VoxelArea(minp, maxp)
		local found = 0
		for i in va:iterp(minp, maxp) do
			local pos = va:position(i)
			local bd = minetest.get_biome_data(pos)
			if bd.biome == biome_id then
				found = found + 1
				futil.create_ephemeral_hud(player, 20, {
					hud_elem_type = "waypoint",
					name = biome_name,
					text = "m",
					number = 0xffffff,
					precision = 1,
					world_pos = pos,
				})
			end
		end
		return true, f("found %s", found)
	end,
})
