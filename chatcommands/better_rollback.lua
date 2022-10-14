local get_bounds = debuggery.util.get_bounds

local iterate_area = futil.iterate_area

local check_privs = (minetest.registered_chatcommands.rollback_check or {}).privs or {rollback = true}
local rollback_privs = (minetest.registered_chatcommands.rollback or {}).privs or {rollback = true}

minetest.register_chatcommand("/rollback_check", {
	params = "[<seconds>] [<limit_per_node>] [<player>]",
	description = "check rollback logs in region. default: seconds = 86400, limit_per_node = 5, player = .*",
	privs = check_privs,
	func = function(name, params)
		local minp, maxp = get_bounds(name)
		if not (minp and maxp) then
            return false, "Please select an area using either areas or worldedit"
		end

		local pos_to_string = minetest.pos_to_string
		local rollback_get_node_actions = minetest.rollback_get_node_actions
		local chat_send_player = minetest.chat_send_player
		local seconds_to_interval = futil.seconds_to_interval
		local f = string.format

		local args = params:split("%s+", false, -1, true)
		local seconds = tonumber(args[1]) or 86400
		local limit_per_node = tonumber(args[2]) or 5
		local player_name = args[3] and ("player:%s"):format(args[3])
		local now = os.time()

		for pos in iterate_area(minp, maxp) do
			local actions = rollback_get_node_actions(pos, 0, seconds, limit_per_node)
			if not actions then
				return false, "rollback disabled"
			end

			local spos = pos_to_string(pos)

			if player_name then
				for _, action in ipairs(actions) do
					if action.actor:match(player_name) then
						local elapsed = now - action.time
						local oldnode = action.oldnode
						local newnode = action.newnode
						local message
						if oldnode.name == "" and newnode.name == "" then
							message = f("%s modified meta or inv %s ago (%s seconds)",
								spos,
								seconds_to_interval(elapsed),
								elapsed
							)

						else
							message = f("%s %s:%i%:%i -> %s:%i:%i %s ago (%s seconds)",
								spos,
								oldnode.name, oldnode.param1, oldnode.param2,
								newnode.name, newnode.param1, newnode.param2,
								seconds_to_interval(elapsed),
								elapsed
							)
						end

						chat_send_player(name, message)
					end
				end
			else
				for _, action in ipairs(actions) do
					local actor = action.actor
					local elapsed = now - action.time
					local oldnode = action.oldnode
					local newnode = action.newnode
					local message
					if oldnode.name == "" and newnode.name == "" then
						message = f("%s %s modified meta or inv %s ago (%s seconds)",
							spos,
							actor,
							seconds_to_interval(elapsed),
							elapsed
						)

					else
						message = f("%s %s %s:%i:%i -> %s:%i:%i %s ago (%s seconds)",
							spos,
							actor,
							oldnode.name, oldnode.param1, oldnode.param2,
							newnode.name, newnode.param1, newnode.param2,
							seconds_to_interval(elapsed),
							elapsed
						)
					end
					chat_send_player(name, message)
				end
			end
		end

		return true, "rollback check complete"
	end,
})

minetest.register_chatcommand("/rollback", {
	params = "<seconds> <player>",
	description = "rollback actions by a specific player in region. warning: DANGEROUS.",
	privs = rollback_privs,
	func = function(name, params)
		local minp, maxp = debuggery.util.get_bounds(name)
		if not (minp and maxp) then
            return false, "Please select an area using either areas or worldedit"
		end

		local rollback_get_node_actions = minetest.rollback_get_node_actions
		local set_node = minetest.set_node
		local list = futil.list
		local filter = futil.functional.filter

		local args = params:split("%s+", false, -1, true)
		local seconds = tonumber(args[1])
		local player_name = args[2]

		if not (seconds and player_name) then
			return false, "must specify # of seconds and a player name."
		end

		if not minetest.player_exists(player_name) then
			return false, ("player %q doesn't exist"):format(player_name)
		end

		player_name = ("player:%s"):format(args[2])

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

		return true, ("rollback completed; %i nodes restored"):format(i)
	end,
})
