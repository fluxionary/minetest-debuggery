local has_areas = debuggery.has.areas
local has_worldedit = debuggery.has.worldedit

local util = {}

function util.get_pos1(name)
	return (has_worldedit and worldedit.pos1[name]) or (has_areas and areas.pos1[name])
end

function util.get_pos2(name)
	return (has_worldedit and worldedit.pos2[name]) or (has_areas and areas.pos2[name])
end

function util.get_bounds(name)
    local pos1 = util.get_pos1(name)
    local pos2 = util.get_pos2(name)

    return vector.sort(pos1, pos2)
end

debuggery.util = util
