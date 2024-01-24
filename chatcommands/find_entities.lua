local f = string.format
local S = debuggery.S

local table_is_empty = futil.table.is_empty
local setdefault = futil.table.setdefault

local counter = 0
--debuggery.ENTS = {} -- this does not work? why? futil.ENTS worked
DBG_ENTS = {} -- short non-descriptive name, for easier use from command line, like `futil.TARG.petz_fox_3`

-- FIXME this should be _per_player_, otherwise it will not mark same ents for other players etc.
local hud_by_ent = {}

local id_of_entity = {}

-- make a string ID that the user will see
local function make_id(ent)
	-- TODO be smarter figuring out a good short name for different types of ents
	counter = counter + 1
	local luaent = ent:get_luaentity()
	local name = ((luaent or {}).name or "NONAME")
	name = name:gsub("%W", "_")
	return name .. "_" .. tostring(counter)
end

-- create new ID or return existing one
local function get_id(ent)
	local id = id_of_entity[ent]
	if id then
		return id
	end
	id = make_id(ent)
	id_of_entity[ent] = id
	return id
end

-- add to HUDs
local function add_entity(player, ent)
	local id = get_id(ent)
	DBG_ENTS[id] = ent

	local pos = ent:get_pos()

	if not hud_by_ent[ent] then
		hud_by_ent[ent] = {
			player_name = player:get_player_name(),
			watch_exprs = {},
		}
		hud_by_ent[ent].img = futil.EphemeralHud(player, {
			hud_elem_type = "image_waypoint",
			text = "bubble.png",
			world_pos = pos,
			scale = { x = 1, y = 1 },
		})
		hud_by_ent[ent].txt = futil.EphemeralHud(player, {
			hud_elem_type = "waypoint",
			name = id,
			number = 0xFFFFFF,
			world_pos = pos,
			offset = {x=0, y=-30},
		})
		-- FIXME don't add this until watchable values are added
		hud_by_ent[ent].dbg = futil.EphemeralHud(player, {
			hud_elem_type = "waypoint",
			name = "",
			number = 0xFFFFFF,
			world_pos = pos,
			offset = {x=0, y=-5},
			precision = 0, -- disable showing distance
		})
	end
	return id
end

minetest.register_chatcommand("find_entities", {
	params = S("<limit> <pattern> <radius>"),
	description = S("highlight matching entities via HUD waypoints"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(player_name, params)
		local start = minetest.get_us_time()

		local player = minetest.get_player_by_name(player_name)
		if not player then
			return false, S("you are not an actual player")
		end

		local limit, pattern, radius = params:match("^%s*(%d+)%s+(%S+)%s+(%S*)%s*")
		limit = tonumber(limit)
		radius = tonumber(radius)
		if not (limit and pattern and radius) then
			return false, S("invalid arguments. See /help /find_entities")
		end

		if not futil.is_valid_regex(pattern) then
			return false, S("invalid filter, please supply a valid lua regular expression")
		end

		--local hud_by_hpos = setdefault(hud_by_hpos_by_player_name, player_name, {})
		local count_found = 0

		for k, v in pairs(minetest.get_objects_inside_radius(player:get_pos(), radius)) do
			-- TODO check for self
			count_found = count_found + 1
			local id = add_entity(player, v)
			minetest.chat_send_player(player:get_player_name(), ("found: %s"):format(id))
		end

		local elapsed = (minetest.get_us_time() - start) / 1e6
		return true, S("[find_entities] took @1s, found @2", tostring(elapsed), tostring(count_found))
	end,
})


minetest.register_chatcommand("entity_watch", {
	params = S("<entity_id> <expression>"),
	description = S("add some debug expression to entity's label"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(player_name, params)
		local start = minetest.get_us_time()

		local player = minetest.get_player_by_name(player_name)
		if not player then
			return false, S("you are not an actual player")
		end

		local entity_id, expr = params:match("^%s*([%w_]+)%s*(.*)")
		
		local ent = DBG_ENTS[entity_id]

		--minetest.chat_send_player(player_name, dump(ent))

		code = ([[
			local this = DBG_ENTS["%s"]
			local %s = this
		    return %s
		]]):format(entity_id, entity_id, expr)

		-- TODO create proper environment instead of using string hacks
		-- TODO don't add all found entitites to it, to prevent mistakes?!
		local func, err = loadstring(code)
		if not func then
			-- Syntax error
			return false, err
		end

		local hud = hud_by_ent[ent]
		if hud then
			table.insert(hud.watch_exprs, {source = expr, func = func})
			minetest.chat_send_player(player_name, ("added %s %s"):format(entity_id, code))
		else
			return false, "no huds for " .. dump(entity_id)
		end
		local elapsed = (minetest.get_us_time() - start) / 1e6
		return true, S("[entity_watch] took @1s", tostring(elapsed))
	end,
})


minetest.register_chatcommand("entity_unwatch", {
	params = S("<entity_id> <index>"),
	description = S("remove Nth debug expression from entity's label"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(player_name, params)
		local start = minetest.get_us_time()

		local player = minetest.get_player_by_name(player_name)
		if not player then
			return false, S("you are not an actual player")
		end

		local entity_id, index = params:match("^%s*([%w_]+)%s*(.*)")
		local index = tonumber(index)
		if not index then
			return false, "second arg should be int"
		end
		
		local ent = DBG_ENTS[entity_id]

		--minetest.chat_send_player(player_name, dump(ent))

		local hud = hud_by_ent[ent]
		if hud then
			table.remove(hud.watch_exprs, index)
			minetest.chat_send_player(player_name, ("removed %s %s"):format(entity_id, index))
		else
			return false, "no huds for " .. dump(entity_id)
		end
		local elapsed = (minetest.get_us_time() - start) / 1e6
		return true, S("[entity_unwatch] took @1s", tostring(elapsed))
	end,
})


minetest.register_chatcommand("clear_find_entities", {
	params = S(""),
	description = S("remove all HUDs for entities"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(player_name, params)
		local start = minetest.get_us_time()

		local player = minetest.get_player_by_name(player_name)
		if not player then
			return false, S("you are not an actual player")
		end

		for ent,hud in pairs(hud_by_ent) do
			if hud.player_name == player_name then
				hud.img:remove()
				hud.txt:remove()
				hud.dbg:remove()
			end
			hud_by_ent[ent] = nil
			local id = get_id(ent)
			DBG_ENTS[id] = nil
		end

		local elapsed = (minetest.get_us_time() - start) / 1e6
		return true, S("[clear_find_entities] took @1s", tostring(elapsed))
	end,
})

UPDATE_INTERVAL = 0.01
local hud_time = 0

minetest.register_globalstep(function(dtime)
	hud_time = hud_time + dtime
	if hud_time < UPDATE_INTERVAL then
		return
	else
		hud_time = (hud_time % UPDATE_INTERVAL)
	end
	for id, ent in pairs(DBG_ENTS) do
		local new_pos = ent:get_pos()
		if new_pos then
			local hud = hud_by_ent[ent]
			hud.img:change({world_pos = new_pos})
			hud.txt:change({world_pos = new_pos})

			local dbg_text = ""
			for i,w in ipairs(hud.watch_exprs) do
				local ok, res = pcall(w.func)
				if ok then
					res = dump(res)
				end
				dbg_text = dbg_text .. "\n" .. tostring(i) .. " " .. w.source .. " = " .. res
			end

			hud.dbg:change({
				world_pos = new_pos,
				name = dbg_text,
			})
		end
	end
end)

-- table.set = function(t, key, val)
-- 	t[key] = val
-- 	return t
-- end

minetest.register_chatcommand(
    "sm",
    {
        params = "<text>",
        description = "Dumps the variable to the user",
        privs = {server = true},
        func = function(name, param)
            if param == "" then
                return false, "Need message"
            end

			-- wrap in a func if contains "="??
            local code = ([[
				local res = %s
				minetest.chat_send_player("%s", dump(res))
				]]):format(param, name)
            minetest.log("action", "[yl_commons] (" .. name .. " used sm) " .. param)

            local func, err = loadstring(code)
            if not func then
                -- Syntax error
                return false, err
            end
            local ok, err2 = pcall(func)
            if not ok then
                -- Runtime error
                return false, err2
            end
            return true
        end
    }
)