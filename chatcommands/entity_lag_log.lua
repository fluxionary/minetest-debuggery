local get_us_time = minetest.get_us_time
local pos_to_string = minetest.pos_to_string
local v_round = vector.round

local log = debuggery.log
local log_threshold = (tonumber(minetest.settings:get("dedicated_server_step")) or 0.09) * 5e6

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_entities) do
		local old_on_step = def.on_step
		if old_on_step then
			function def.on_step(self, dtime, moveresult)
				local start = get_us_time()
				local rv = old_on_step(self, dtime, moveresult)
				local elapsed = get_us_time() - start
				if elapsed > log_threshold and self.object then
					log("warning", "%s @ %s's on_step took %s us",
						name, pos_to_string(v_round(self.object:get_pos())), elapsed)
				end
				return rv
			end
		end
	end
end)
