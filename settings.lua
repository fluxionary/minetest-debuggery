local s = minetest.settings

debuggery.settings = {
	admin_priv = s:get("debuggery.admin_priv") or "server",
	entity_lag_log_threshold = tonumber(s:get("debuggery.entity_lag_log_threshold")) or
		(tonumber(minetest.settings:get("dedicated_server_step")) or 0.09) * 5e6,
	instrumentation_report_interval = tonumber(s:get("debuggery.instrumentation_report_interval")) or 1,
}
