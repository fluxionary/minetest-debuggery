local private_state = ...
local mod_storage = private_state.mod_storage

local function get_key(player_name)
	return ("sunlight:%s"):format(player_name)
end

local function parse_args(caller_name, param)
	if param:match("^%s*$") then
		return caller_name
	end

	local value = tonumber(param)

	if value then
		return caller_name, value
	end

	local target

	target, value = param:match("^%s*(%S+)%s*(%S+)%s*$")
	value = tonumber(value)
	if target and value then
		return target, value
	end

	return param
end

minetest.register_chatcommand("sunlight", {
	-- Give players with "settime" priv the ability to override their day-night ratio
	params = "[<target>] [<ratio>]",
	description = (
		"Override day night ratio. (1 = always day, 0 = always night). "
		.. "With no argument, reset the default behavior."
	),
	privs = { settime = true },
	func = function(caller_name, param)
		local target, value = parse_args(caller_name, param)

		local player = minetest.get_player_by_name(target)
		if not player then
			return false, ("player %s is not connected"):format(target)
		end

		if value and (value < 0 or value > 1) then
			return false, "sunlight value must be between 0 and 1 inclusive"
		end

		player:override_day_night_ratio(value)

		if value then
			mod_storage:set_string(get_key(caller_name), tostring(value))
		else
			mod_storage:set_string(get_key(caller_name), "")
		end

		return true, "sunlight level set"
	end,
})

minetest.register_on_joinplayer(function(player)
	if not minetest.check_player_privs(player, { settime = true }) then
		return
	end

	local player_name = player:get_player_name()

	local ratio = tonumber(mod_storage:get(get_key(player_name)))

	if ratio then
		player:override_day_night_ratio(ratio)
	end
end)
