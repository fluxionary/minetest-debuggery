local f = string.format
local S = debuggery.S

local get_bounds = debuggery.util.get_bounds

local iso_date = futil.iso_date
local iterate_area = futil.iterate_area

local check_privs = (minetest.registered_chatcommands.rollback_check or {}).privs or { rollback = true }
local rollback_privs = (minetest.registered_chatcommands.rollback or {}).privs or { rollback = true }

minetest.register_chatcommand("/rollback_check", {
	params = S("[<seconds>] [<limit_per_node>] [<player>] [<node>]"),
	description = S(
		"check rollback logs in region. default: seconds = 31536000, limit_per_node = 5, player = .*, node = .*"
	),
	privs = check_privs,
	func = function(name, params)
		local minp, maxp = get_bounds(name)
		if not (minp and maxp) then
			return false, S("please select an area using either areas or worldedit")
		end

		if futil.vector.volume(minp, maxp) > (16 * 16 * 16 * 27) then
			return false, S("this is a very expensive command, do not use on volumes larger than 3x3x3 mapblocks")
		end

		local pos_to_string = minetest.pos_to_string
		local rollback_get_node_actions = minetest.rollback_get_node_actions
		local chat_send_player = minetest.chat_send_player

		local args = params:split("%s+", false, -1, true)
		local seconds = tonumber(args[1]) or 86400 * 365
		local limit_per_node = tonumber(args[2]) or 5
		local player_name = args[3] and f("player:%s", args[3])
		local node_pattern = args[4]
		local now = os.time()

		local function get_message(spos, action)
			local actor = action.actor
			local action_time = action.time
			local elapsed = now - action_time
			local oldnode = action.oldnode
			local oldnode_name = oldnode.name
			local newnode = action.newnode
			local newnode_name = newnode.name

			local function build_message()
				local verb
				if oldnode_name == "" and newnode_name == "" then
					verb = S("modified meta or inv")
				elseif oldnode_name == "air" and newnode_name ~= "air" then
					verb = S("placed @1:@2:@3", newnode_name, tostring(newnode.param1), tostring(newnode.param2))
				elseif oldnode_name ~= "air" and newnode_name == "air" then
					verb = S("dug @1:@2:@3", oldnode_name, tostring(oldnode.param1), tostring(oldnode.param2))
				else
					verb = S(
						"replaced @1:@2:@3 with @4:@5:@6",
						oldnode_name,
						tostring(oldnode.param1),
						tostring(oldnode.param2),
						newnode_name,
						tostring(newnode.param1),
						tostring(newnode.param2)
					)
				end

				return S("@1 @2 @3 @4 (@5 seconds ago)", iso_date(action_time), spos, actor, verb, tostring(elapsed))
			end

			if player_name then
				if actor:match(player_name) then
					if node_pattern then
						if oldnode_name:match(node_pattern) or newnode.name:match(node_pattern) then
							return build_message()
						end
					else
						return build_message()
					end
				end
			else
				if node_pattern then
					if oldnode_name:match(node_pattern) or newnode.name:match(node_pattern) then
						return build_message()
					end
				else
					return build_message()
				end
			end
		end

		for pos in iterate_area(minp, maxp) do
			local actions = rollback_get_node_actions(pos, 0, seconds, limit_per_node)
			if not actions then
				return false, S("rollback disabled")
			end

			local spos = pos_to_string(pos)
			for _, action in ipairs(actions) do
				local message = get_message(spos, action)
				if message then
					chat_send_player(name, message)
				end
			end
		end

		return true, S("rollback check complete")
	end,
})

minetest.register_chatcommand("/rollback", {
	params = S("<seconds> <player>"),
	description = S("rollback actions by a specific player in region. warning: DANGEROUS."),
	privs = rollback_privs,
	func = function(name, params)
		local minp, maxp = get_bounds(name)
		if not (minp and maxp) then
			return false, S("please select an area using either areas or worldedit")
		end

		if futil.vector.volume(minp, maxp) > (16 * 16 * 16 * 27) then
			return false, S("this is a very expensive command, do not use on volumes larger than 3x3x3 mapblocks")
		end

		local rollback_get_node_actions = minetest.rollback_get_node_actions
		local set_node = minetest.set_node
		local list = futil.list
		local filter = futil.functional.filter

		local args = params:split("%s+", false, -1, true)
		local seconds = tonumber(args[1])
		local player_name = args[2]

		if not (seconds and player_name) then
			return false, S("must specify # of seconds and a player name.")
		end

		if not minetest.player_exists(player_name) then
			return false, S("player @1 doesn't exist", player_name)
		end

		player_name = f("player:%s", player_name)

		local i = 0
		for pos in iterate_area(minp, maxp) do
			local actions = rollback_get_node_actions(pos, 0, seconds, 100)

			if not actions then
				return false, "rollback disabled"
			end

			actions = list(filter(function(action)
				return action.actor == player_name and action.oldnode.name ~= ""
			end, actions))

			if #actions > 0 then
				local action = actions[#actions]
				set_node(pos, action.oldnode)
				i = i + 1
			end
		end

		return true, S("rollback completed; @1 nodes restored", tostring(i))
	end,
})
