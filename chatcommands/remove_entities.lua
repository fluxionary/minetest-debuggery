local S = debuggery.S

minetest.register_chatcommand("remove_entities", {
	params = S("<entity name>"),
	description = S("removes all entities of the specified type"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function(name, entity_name)
		entity_name = entity_name:match("^%s*(%S+)%s*$")
		if not entity_name then
			return false, S("invalid arguments")
		end
		if not minetest.registered_entities[entity_name] then
			return false, S("unknown entity @1", entity_name)
		end

		local count = 0
		for _, entity in pairs(minetest.luaentities) do
			if entity.name == entity_name then
				entity.object:remove()
				count = count + 1
			end
		end

		return true, S("removed @1 @2s", tostring(count), entity_name)
	end,
})
