local f = string.format
local S = debuggery.S

local pairs_by_key = futil.table.pairs_by_key

local function count_entities(player_name, filter)
	local ret = {}
	local total = 0

	local all_objects = minetest.luaentities

	for _, entity in pairs(all_objects) do
		local name = (entity or {}).name
		if name then
			total = total + 1
			ret[name] = (ret[name] or 0) + 1
		end
	end

	local previous_mod
	local mod_total = 0
	local mod_items = 0

	for name, count in pairs_by_key(ret) do
		if filter == "" or name:match(filter) then
			local mod = name:match("^([^:]+):")

			if mod and previous_mod and mod ~= previous_mod then
				if mod_items > 1 then
					minetest.chat_send_player(player_name, S("@1 total = @2", previous_mod, tostring(mod_total)))
				end
				minetest.chat_send_player(player_name, "..............")
				mod_total = 0
				mod_items = 0
			end

			minetest.chat_send_player(player_name, f("%s = %s", name, count))
			mod_total = mod_total + count
			mod_items = mod_items + 1
			previous_mod = mod
		end
	end

	if previous_mod then
		if mod_items > 1 then
			minetest.chat_send_player(player_name, S("@1 total = @2", previous_mod, tostring(mod_total)))
		end
		minetest.chat_send_player(player_name, "..............")
	end

	minetest.chat_send_player(player_name, S("total = @1", tostring(total)))
end

minetest.register_chatcommand("count_entities", {
	description = S("get counts of all active entities on the server"),
	params = S("[<filter>]"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(name, filter)
		filter = filter:trim()
		if not futil.is_valid_regex(filter) then
			return false, S("invalid filter, please supply a valid lua regular expression")
		end
		count_entities(name, filter)
		return true
	end,
})
