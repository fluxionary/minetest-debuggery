if minetest.get_modpath("worldeditadditions") then
	-- already has something similar, don't clobber
	return
end

local f = string.format

local dedicated_server_step = tonumber(minetest.settings:get("dedicated_server_step")) or 0.09
local p2s = minetest.pos_to_string

local split_region_by_mapblock = futil.split_region_by_mapblock

local S = debuggery.S
local get_bounds = debuggery.util.get_bounds

local jobs_by_player_name = {}

local function show_results(player_name)
	local total_counts = jobs_by_player_name[player_name].total_counts
	for id, count in futil.table.pairs_by_value(total_counts) do
		debuggery.chat_send_player(player_name, "@1: @2", minetest.get_name_from_content_id(id), tostring(count))
	end
end

local function get_chunk_counts(pos1, pos2)
	local vm = VoxelManip(pos1, pos2)
	local va = VoxelArea(vm:get_emerged_area())
	local data = vm:get_data()
	local counts = {}
	for i in va:iterp(pos1, pos2) do
		local id = data[i]
		counts[id] = (counts[id] or 0) + 1
	end
	return counts
end

local function count_next_chunk(player_name)
	local job = jobs_by_player_name[player_name]
	if not job then
		return
	end

	local i = job.i
	local chunks = job.chunks
	local total_counts = job.total_counts
	local counts = get_chunk_counts(unpack(chunks[i]))
	for id, count in pairs(counts) do
		total_counts[id] = (total_counts[id] or 0) + count
	end

	if i == #chunks then
		show_results(player_name)
		jobs_by_player_name[player_name] = nil
	else
		job.i = i + 1
		minetest.after(0, count_next_chunk, player_name)
	end
end

minetest.register_chatcommand("/count", {
	description = S("get node counts in a region"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(player_name, params)
		if jobs_by_player_name[player_name] then
			local job = jobs_by_player_name[player_name]
			return false,
				S(
					"you are already running //count on @1, @2; @3% done",
					p2s(job.pos1),
					p2s(job.pos2),
					f("%.2f", 100 * job.i / #job.chunks)
				)
		end

		local pos1, pos2 = get_bounds(player_name)
		if not (pos1 and pos2) then
			return false, S("please select an area using either areas or worldedit")
		end

		local chunks
		if futil.vector.volume(pos1, pos2) > 16 ^ 3 then
			chunks = split_region_by_mapblock(pos1, pos2, 16)
		else
			chunks = { { pos1, pos2 } }
		end

		jobs_by_player_name[player_name] = {
			chunks = chunks,
			i = 1,
			pos1 = pos1,
			pos2 = pos2,
			total_counts = {},
		}
		count_next_chunk(player_name)

		if #chunks == 1 then
			return true
		else
			local expected = dedicated_server_step * #chunks
			return true,
				S(
					"[count] broke job into @1 chunks; please wait at least @2s for results",
					tostring(#chunks),
					f("%.2f", expected)
				)
		end
	end,
})

minetest.register_chatcommand("/abort_count", {
	description = S("stops counting"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(player_name, params)
		if jobs_by_player_name[player_name] then
			jobs_by_player_name[player_name] = nil
			return true, S("counting aborted")
		else
			return false, S("no count was active")
		end
	end,
})

minetest.register_on_leaveplayer(function(player)
	jobs_by_player_name[player:get_player_name()] = nil
end)
