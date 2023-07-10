local S = debuggery.S

local default_stack_max = tonumber(minetest.settings:get("default_stack_max")) or 99

minetest.register_chatcommand("clone_wielded", {
	params = S("[<quantity>]"),
	description = S("increases the stack size of the wielded item"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(name, count)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, S("you're not a player")
		end

		local wielded = player:get_wielded_item()
		if wielded:is_empty() then
			return false, S("can't dupe nothing")
		end

		local inv = player:get_inventory()
		local def = wielded:get_definition()
		count = tonumber(count) or 1

		if count >= 65536 or count <= 0 or math.floor(count) ~= count then
			return false, S("invalid count")
		end

		local wield_string = wielded:to_string()
		if def.type == "tool" then
			local created = 0
			for _ = 1, count do
				if inv:room_for_item("main", wielded) then
					inv:add_item("main", wielded)
				else
					break
				end
				created = created + 1
			end

			if created == count then
				if count == 1 then
					return true, S("added @1 to inventory", wield_string)
				else
					return true, S("added @1 @2s to inventory", created, wield_string)
				end
			elseif created == 0 then
				return false, S("no room in inventory")
			else
				return true, S("added @1s @2s to inventory, then ran out of space", created, wield_string)
			end
		else
			local stack_max = wielded:get_stack_max()
			if stack_max == 1 then
				stack_max = default_stack_max
			end
			count = count or stack_max

			if count > wielded:get_count() then
				wielded:set_count(count)
				player:set_wielded_item(wielded)
				return true, S("cloned @1", wield_string)
			else
				return false, S("wielded stack is already larger")
			end
		end
	end,
})
