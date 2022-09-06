local s = minetest.settings

debuggery.settings = {
	admin_priv = s:get("debuggery.admin_priv") or "server",
	instrumentation_report_interval = tonumber(s:get("debuggery.instrumentation_report_interval")) or 1,
}
