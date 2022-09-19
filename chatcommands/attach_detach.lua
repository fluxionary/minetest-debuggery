local function resolve(target)
	local player = minetest.get_player_by_name(target)

	if player then
		return player, nil, target
	end

	local def = minetest.registered_entities[target]

	if def then
		for k, ent in pairs(minetest.luaentities) do
			if ent.name == target then
				return ent.object, nil, target
			end
		end

		return nil, ("no %q entity found"):format(target)
	end

	if target:match(":") then
		return nil, ("uknown entity %q"):format(target)

	else
		return nil, ("player %q not connected"):format(target)
	end
end

minetest.register_chatcommand("attach", {
	params = "<target1> to <target2>",
	description = "attaches two objects",
	privs = {[debuggery.settings.admin_priv] = true},
	func = function(name, target)
		local target1, target2 = target:match("^%s*([^%s]+)%s+to%s+([^%s]+)%s*")
		if not (target1 and target2) then
			return false, "invalid arguments"
		end
		local reason1, reason2, name1, name2
		target1, reason1, name1 = resolve(target1)
		target2, reason2, name2 = resolve(target2)

		if reason1 or reason2 then
			return false, reason1 or reason2
		end

		target1:set_attach(target2)

		return true, ("attached %s @ %s to %s @ %s"):format(
			name1, minetest.pos_to_string(vector.round(target1:get_pos())),
			name2, minetest.pos_to_string(vector.round(target2:get_pos()))
		)
	end,
})

minetest.register_chatcommand("detach", {
	params = "<target>",
	description = "detaches something",
	privs = {[debuggery.settings.admin_priv] = true},
	func = function(name, target)
		local reason, name_
		target, reason, name_ = resolve(target)

		if reason then
			return false, reason
		end

		local parent = target:get_attach()

		if not parent then
			return false, ("%s not attached"):format(name_)
		end

		target:set_detach()

		return true, ("detached %s from %s"):format(target, parent)
	end,
})
