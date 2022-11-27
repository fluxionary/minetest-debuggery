local f = string.format
local default_stack_max = tonumber(minetest.settings:get("default_stack_max")) or 99

minetest.register_chatcommand("clone_wielded", {
	params = "[<quantity>]",
	description = "increases the stack size of the wielded item",
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(name, count)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "you're not a player"
		end

		local wielded = player:get_wielded_item()
		if wielded:is_empty() then
			return false, "can't dupe nothing"
		end

		local inv = player:get_inventory()
		local def = wielded:get_definition()
		count = tonumber(count)

		if count and (count >= 65536 or count <= 0 or math.floor(count) ~= count) then
			return false, "invalid count"
		end

		if def.type == "tool" then
			count = count or 1
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
					return true, f("added %q to inventory", wielded:to_string())
				else
					return true, f("added %s %qs to inventory", created, wielded:to_string())
				end
			elseif created == 0 then
				return false, "no room in inventory"
			else
				return true, f("added %s %qs to inventory, then ran out of space", created, wielded:to_string())
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
				return true, f("cloned %q", wielded:to_string())
			else
				return false, f("wielded stack is already larger")
			end
		end
	end,
})
