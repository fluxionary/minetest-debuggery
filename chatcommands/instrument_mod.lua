local f = string.format

local get_us_time = minetest.get_us_time
local log = minetest.log
local log_level = minetest.settings:get("debug_log_level") or "action"

local pairs_by_key = futil.table.pairs_by_key

local s = debuggery.settings

local old_values = {}
local total_elapsed = {}
local total_calls = {}

local num_instrumented = 0

local function instrument(name, value, _cache)
	if type(value) == "function" then
		return function(...)
			if s.instrument_log_every_call then
				debuggery.log("action", "%s(%s)", name, dump({ ... }))
			end
			local begin = get_us_time()
			local rvs = { value(...) }
			total_elapsed[name] = (total_elapsed[name] or 0) + get_us_time() - begin
			total_calls[name] = (total_calls[name] or 0) + 1
			if s.instrument_log_every_call then
				debuggery.log("action", "%s(...) -> %s", name, dump(rvs))
			end
			return unpack(rvs)
		end
	elseif type(value) == "table" then
		_cache = _cache or {}
		local cached = _cache[value]
		if cached then
			return cached
		end

		local t = {}
		_cache[value] = t

		for k, v in pairs(value) do
			if type(k) == "string" then
				t[k] = instrument(f("%s.%s", name, k), v, _cache)
			else
				t[k] = instrument(f("%s[%s]", name, k), v, _cache)
			end
		end

		setmetatable(t, instrument(f("getmetatable(%s)", name), getmetatable(value), _cache))

		return t
	else
		return value
	end
end

local function instrument_mod(mod)
	debuggery.log("action", "instrumenting %s", mod)
	old_values[mod] = _G[mod]
	_G[mod] = instrument(mod, _G[mod])
	num_instrumented = num_instrumented + 1
end

local function uninstrument_mod(mod)
	debuggery.log("action", "uninstrumenting %s", mod)
	_G[mod] = old_values[mod]
	old_values[mod] = nil
	num_instrumented = num_instrumented - 1
end

minetest.register_chatcommand("instrument_mod", {
	params = "<global_name>",
	description = "toggles recording timing data for all functions declared in a particular global",
	privs = { [s.admin_priv] = true },
	func = function(name, param)
		if param == "" then
			local mods = {}
			for mod in pairs(old_values) do
				table.insert(mods, mod)
			end
			if #mods == 0 then
				return true, "no mods currently instrumented"
			else
				return true, "mods currently instrumented: " .. table.concat(mods, ", ")
			end
		end

		if not (minetest.global_exists(param) and _G[param]) then
			return false, f("unknown global %s", param)
		end

		if old_values[param] then
			uninstrument_mod(param)
			return true, f("instrumentation disabled for %s", param)
		else
			instrument_mod(param)
			return true, f("instrumentation enabled for %s", param)
		end
	end,
})

local last_call
futil.register_globalstep({
	period = s.instrumentation_report_interval,
	catchup = false,
	func = function()
		if num_instrumented == 0 then
			return
		end
		local now = get_us_time()
		if last_call then
			local elapsed = now - last_call
			log(log_level, f("[instrument_mod] in %ss,", elapsed))
		end
		last_call = now

		for name, num_calls in pairs_by_key(total_calls) do
			local te = total_elapsed[name]

			log(log_level, f("[instrument_mod] %s was called %s times, used %s us", name, num_calls, te))
		end

		total_calls = {}
		total_elapsed = {}
	end,
})

minetest.register_on_mods_loaded(function()
	local mods = (s.instrument_on_load or ""):split()
	for _, mod in ipairs(mods) do
		if not (minetest.global_exists(mod) and _G[mod]) then
			error(f("cannot instrument mod %q - it does not exist.", mod))
		end
		instrument_mod(mod)
	end
end)
