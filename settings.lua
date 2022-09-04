local s = minetest.settings

debuggery.settings = {
	admin_priv = s:get("debuggery.admin_priv") or "server"
}
