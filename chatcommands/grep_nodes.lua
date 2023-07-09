if not (debuggery.has.areas or debuggery.has.worldedit) then
	return
end

local table_is_empty = futil.table.is_empty
local get_bounds = debuggery.util.get_bounds

local split_region_by_mapblock = futil.split_region_by_mapblock

local function build_name_by_id(pattern)
	local get_content_id = minetest.get_content_id
	local name_by_id = {}

	for itemstring in pairs(minetest.registered_nodes) do
		if itemstring:match(pattern) then
			name_by_id[get_content_id(itemstring)] = itemstring
		end
	end

	return name_by_id
end

local HUD_ELEM_LIMIT = 10000 -- this already makes my PC drop FPS, but still usable
local huds = {}
local huddef = {
    hud_elem_type = "image_waypoint",
    scale = {x=-4/16*9,y=-4},
    text = "debuggery_dot.png",
    world_pos = nil, -- to be filled inside the loop
    offset = {x=0, y=0},
    alignment = {x=0, y=0, z=0},
}

local function find_in_bounds(pos1, pos2, player_name, names_by_id, limit)
	local vm = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = vm:read_from_map(pos1, pos2)
	local area = VoxelArea:new({ MinEdge = emerged_pos1, MaxEdge = emerged_pos2 })
	local data = vm:get_data()

	local player = minetest.get_player_by_name(player_name)
	local hud_list = huds[player_name] or {}
	huds[player_name] = hud_list

	local count_found = 0
	for i in area:iterp(pos1, pos2) do
		local itemstring = names_by_id[data[i]]
		if itemstring then
			local pos = area:position(i)
			local pos_str = minetest.pos_to_string(pos)
			minetest.chat_send_player(player_name, ("[grep] %s @ %s"):format(itemstring, pos_str))
			if #hud_list < HUD_ELEM_LIMIT then
                huddef.world_pos = pos
				table.insert(hud_list, player:hud_add(huddef))
			end
			count_found = count_found + 1
			if count_found == limit then
				break
			end
		end
	end

	return count_found
end

minetest.register_chatcommand("/grep_nodes", {
	params = "<limit> <pattern>",
	description = "Search for nodes",
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(player_name, params)
		local start = minetest.get_us_time()
		local limit, pattern = params:match("^%s*(%d+)%s+(%S+)%s*")
		limit = tonumber(limit)
		if not (limit and pattern) then
			return false, "Invalid arguments. See /help /grep_nodes"
		end

		local pos1, pos2 = get_bounds(player_name)
		if not (pos1 and pos2) then
			return false, "Please select an area using either areas or worldedit"
		end

		local names_by_id = build_name_by_id(pattern)
		if table_is_empty(names_by_id) then
			return false, "Pattern doesn't match any nodes"
		end

		local chunks = split_region_by_mapblock(pos1, pos2, 16)
		local count_found = 0
		local queue = action_queues.api.create_serverstep_queue({ num_per_step = 1 })
		for _, chunk in ipairs(chunks) do
			queue:push_back(function()
				count_found = count_found + find_in_bounds(chunk[1], chunk[2], player_name, names_by_id, limit)

				if count_found >= limit then
					queue:clear()
				end
			end)
		end

		local took = (minetest.get_us_time() - start) / 1e6
		return true, ("broke job into %s chunks, took %ss"):format(#chunks, took)
	end,
})

minetest.register_chatcommand("/grep_clear", {
	description = "Hide //grep_nodes markers.",
	params = "none",
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local hud_list = huds[name] or {}
		for _,hud_id in pairs(hud_list) do
			player:hud_remove(hud_id)
		end
        huds[name] = {}
		return true, "Markers hidden"
	end,
})
