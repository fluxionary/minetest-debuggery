if not (debuggery.has.areas or debuggery.has.worldedit) then
    return
end

local v_new = vector.new

local table_is_empty = table.is_empty
local get_bounds = debuggery.util.get_bounds

local function get_names_by_id(pattern)
    local get_content_id = minetest.get_content_id
    local names_by_id = {}

    for itemstring in pairs(minetest.registered_nodes) do
        if itemstring:match(pattern) then
            names_by_id[get_content_id(itemstring)] = itemstring
        end
    end

    return names_by_id
end

local chunk_size = 16 * 16
local function separate_by_mapchunk(pos1, pos2)
    local chunks = {}
    for x = pos1.x - (pos1.x % chunk_size), pos2.x - (pos2.x % chunk_size) + (chunk_size - 1), chunk_size do
        for y = pos1.y - (pos1.y % chunk_size), pos2.y - (pos2.y % chunk_size) + (chunk_size - 1), chunk_size do
            for z = pos1.z - (pos1.z % chunk_size), pos2.z - (pos2.z % chunk_size) + (chunk_size - 1), chunk_size do
                table.insert(chunks, {
                    v_new(math.max(pos1.x, x), math.max(pos1.y, y), math.max(pos1.z, z)),
                    v_new(
                        math.min(pos2.x, x + (chunk_size - 1)),
                        math.min(pos2.y, y + (chunk_size - 1)),
                        math.min(pos2.z, z + (chunk_size - 1))
                    ),
                })
            end
        end
    end
    return chunks
end

local function find_in_bounds(pos1, pos2, name, names_by_id, limit)
    local vm = minetest.get_voxel_manip()
    local emerged_pos1, emerged_pos2 = vm:read_from_map(pos1, pos2)
    local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})
    local data = vm:get_data()

    local found = 0
    for i in area:iterp(pos1, pos2) do
        local itemstring = names_by_id[data[i]]
        if itemstring then
            local pos = minetest.pos_to_string(area:position(i))
            minetest.chat_send_player(name, ("[grep] %s @ %s"):format(itemstring, pos))
            found = found + 1
            if found == limit then
                break
            end
        end
    end

    return found
end

local function process_chunk(name, names_by_id, limit, chunks, chunk_index)
    local pos1, pos2 = unpack(chunks[chunk_index])

    local found = find_in_bounds(pos1, pos2, name, names_by_id, limit)
    limit = limit - found
    if limit > 0 and chunk_index < #chunks then
        minetest.after(0, process_chunk, name, names_by_id, limit, chunks, chunk_index + 1)
    end
end

minetest.register_chatcommand("/grep_nodes", {
    params = "<limit> <pattern>",
    description = "Search for nodes",
    privs = {[debuggery.settings.admin_priv] = true},
    func = function(name, params)
        local start = minetest.get_us_time()
        local limit, pattern = params:match("^%s*(%d+)%s+(%S+)%s*")
        limit = tonumber(limit)
        if not (limit and pattern) then
            return false, "Invalid arguments. See /help /grep_nodes"
        end

        local pos1, pos2 = get_bounds(name)
        if not (pos1 and pos2) then
            return false, "Please select an area using either areas or worldedit"
        end

        local names_by_id = get_names_by_id(pattern)
        if table_is_empty(names_by_id) then
            return false, "Pattern doesn't match any nodes"
        end

        local chunks = separate_by_mapchunk(pos1, pos2)

        minetest.after(0, process_chunk, name, names_by_id, limit, chunks, 1)

        local took = (minetest.get_us_time() - start) / 1e6
        return true, ("broke job into %s chunks, took %ss"):format(#chunks, took)
    end,
})
