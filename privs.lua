if not minetest.registered_privileges[debuggery.settings.admin_priv] then
	minetest.register_privilege(debuggery.settings.admin_priv, {
		description = "debuggery admin priv",
		give_to_admin = true,
		give_to_singleplayer = true,
	})
end
