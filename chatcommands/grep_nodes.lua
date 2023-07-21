if not (debuggery.has.areas or debuggery.has.worldedit) then
	return
end

local f = string.format
local S = debuggery.S

local table_is_empty = futil.table.is_empty
local setdefault = futil.table.setdefault
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

local function iterate_in_bounds(pos1, pos2, names_by_id, limit)
	return coroutine.wrap(function()
		local vm = minetest.get_voxel_manip()
		local emerged_pos1, emerged_pos2 = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({ MinEdge = emerged_pos1, MaxEdge = emerged_pos2 })
		local data = vm:get_data()

		local count_found = 0
		for i in area:iterp(pos1, pos2) do
			local itemstring = names_by_id[data[i]]
			if itemstring then
				count_found = count_found + 1
				local pos = area:position(i)
				coroutine.yield(itemstring, pos)
				if count_found == limit then
					break
				end
			end
		end
	end)
end

minetest.register_chatcommand("/grep_nodes", {
	params = S("<limit> <pattern>"),
	description = S("search for nodes"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(player_name, params)
		local start = minetest.get_us_time()
		local limit, pattern = params:match("^%s*(%d+)%s+(%S+)%s*")
		limit = tonumber(limit)
		if not (limit and pattern) then
			return false, S("invalid arguments. See /help /grep_nodes")
		end

		local pos1, pos2 = get_bounds(player_name)
		if not (pos1 and pos2) then
			return false, S("please select an area using either areas or worldedit")
		end

		if not futil.is_valid_regex(pattern) then
			return false, S("invalid filter, please supply a valid lua regular expression")
		end

		local names_by_id = build_name_by_id(pattern)
		if table_is_empty(names_by_id) then
			return false, S("pattern doesn't match any nodes")
		end

		local chunks = split_region_by_mapblock(pos1, pos2, 16)
		local count_found = 0
		local queue = action_queues.api.create_serverstep_queue({ num_per_step = 1 })
		for _, chunk in ipairs(chunks) do
			queue:push_back(function()
				for itemstring, pos in iterate_in_bounds(chunk[1], chunk[2], names_by_id, limit) do
					local spos = minetest.pos_to_string(pos)
					minetest.chat_send_player(player_name, f("[grep_nodes] %s @ %s", itemstring, spos))
					-- bubble.png
					count_found = count_found + 1

					if count_found >= limit then
						queue:clear()
						break
					end
				end
			end)
		end

		local elapsed = minetest.get_us_time() - start
		return true, S("[grep_nodes] broke job into @1 mapblocks, took @2s", tostring(#chunks), tostring(elapsed))
	end,
})

local hud_by_hpos_by_player_name = {}

-- whosit deserves credit for the idea here
minetest.register_chatcommand("/mark_nodes", {
	params = S("<limit> <pattern>"),
	description = S("highlight matching nodes via HUD waypoints"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(player_name, params)
		local start = minetest.get_us_time()

		local player = minetest.get_player_by_name(player_name)
		if not player then
			return false, S("you are not an actual player")
		end

		local limit, pattern = params:match("^%s*(%d+)%s+(%S+)%s*")
		limit = tonumber(limit)
		if not (limit and pattern) then
			return false, S("invalid arguments. See /help /mark_nodes")
		end

		local pos1, pos2 = get_bounds(player_name)
		if not (pos1 and pos2) then
			return false, S("please select an area using either areas or worldedit")
		end

		if not futil.is_valid_regex(pattern) then
			return false, S("invalid filter, please supply a valid lua regular expression")
		end

		local names_by_id = build_name_by_id(pattern)
		if table_is_empty(names_by_id) then
			return false, S("pattern doesn't match any nodes")
		end

		local hud_by_hpos = setdefault(hud_by_hpos_by_player_name, player_name, {})
		local chunks = split_region_by_mapblock(pos1, pos2, 16)
		local count_found = 0
		local queue = action_queues.api.create_serverstep_queue({ num_per_step = 1 })
		for _, chunk in ipairs(chunks) do
			queue:push_back(function()
				for _, pos in iterate_in_bounds(chunk[1], chunk[2], names_by_id, limit) do
					local hpos = minetest.hash_node_position(pos)
					if not hud_by_hpos[hpos] then
						hud_by_hpos[hpos] = futil.EphemeralHud(player, {
							hud_elem_type = "image_waypoint",
							text = "bubble.png",
							world_pos = pos,
							scale = { x = 1, y = 1 },
						})
						count_found = count_found + 1

						if count_found >= limit then
							queue:clear()
							break
						end
					end
				end
			end)
		end

		local elapsed = minetest.get_us_time() - start
		return true, S("[grep_nodes] broke job into @1 mapblocks, took @2s", tostring(#chunks), tostring(elapsed))
	end,
})

minetest.register_chatcommand("/clear_marks", {
	description = S("clear HUD marks from /mark_nodes"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(player_name)
		local hud_by_hpos = hud_by_hpos_by_player_name[player_name] or {}
		for _, hud in pairs(hud_by_hpos) do
			hud:remove()
		end
		hud_by_hpos_by_player_name[player_name] = nil
		return true, S("HUD waypoints hidden")
	end,
})

minetest.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()
	hud_by_hpos_by_player_name[player_name] = nil
end)
