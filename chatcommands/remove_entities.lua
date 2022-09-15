

minetest.register_chatcommand("remove_entities", {
	params = "<entity name>",
	description = "removes all entities of the specified type",
	privs = {[debuggery.settings.admin_priv] = true},
	func = function(name, entity_name)
		entity_name = entity_name:match("^%s*(%S+)(%s*)$")
		if not entity_name then
			return false, "invalid arguments"
		end
		if not minetest.registered_entities[entity_name] then
			return false, ("unknown entity %q"):format(entity_name)
		end

		local count = 0
		for _, entity in pairs(minetest.luaentities) do
			if entity.name == entity_name then
				entity.object:remove()
				count = count + 1
			end
		end

		return true, ("removed %s %ss"):format(count, entity_name)
	end,
})
