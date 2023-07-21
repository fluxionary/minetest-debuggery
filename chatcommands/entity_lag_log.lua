local get_us_time = minetest.get_us_time
local p2s = minetest.pos_to_string
local v_round = vector.round

local S = debuggery.S
local log = debuggery.log
local log_threshold = debuggery.settings.entity_lag_log_threshold

local old_on_steps

local function make_logger(name, old_on_step)
	return function(self, dtime, moveresult)
		local start = get_us_time()
		local rv = old_on_step(self, dtime, moveresult)
		local elapsed = get_us_time() - start
		if elapsed > log_threshold and self.object then
			log("warning", "%s @ %s's on_step took %s us", name, p2s(v_round(self.object:get_pos())), elapsed)
		end
		return rv
	end
end

minetest.register_chatcommand("entity_lag_log_toggle", {
	description = S("toggles logging when an entity's on_step takes too long"),
	privs = { [debuggery.settings.admin_priv] = true },
	func = function()
		if old_on_steps then
			for name, old_on_step in pairs(old_on_steps) do
				minetest.registered_entities[name].on_step = old_on_step
			end
			old_on_steps = nil
		else
			old_on_steps = {}
			for name, def in pairs(minetest.registered_entities) do
				local old_on_step = def.on_step
				if old_on_step then
					old_on_steps[name] = old_on_step
					def.on_step = make_logger(name, old_on_step)
				end
			end
		end
	end,
})
