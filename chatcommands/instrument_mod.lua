local get_us_time = minetest.get_us_time
local log = minetest.log
local log_level = minetest.settings:get("debug_log_level") or "action"

local pairs_by_key = futil.pairs_by_key

local old_values = {}
local total_elapsed = {}
local total_calls = {}

local num_instrumented = 0

local function instrument(name, value, _cache)
    if type(value) == "function" then
        return function(...)
            local begin = get_us_time()
            local rvs = {value(...)}
            total_elapsed[name] = (total_elapsed[name] or 0) + get_us_time() - begin
            total_calls[name] = (total_calls[name] or 0) + 1
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
                t[k] = instrument(("%s.%s"):format(name, k), v, _cache)

            else
                t[k] = instrument(("%s[%s]"):format(name, k), v, _cache)
            end
        end

	    setmetatable(t, instrument(("getmetatable(%s)"):format(name), getmetatable(value), _cache))

        return t

    else
        return value
    end
end

minetest.register_chatcommand("instrument_mod", {
    params = "<global_name>",
    description = "toggles recording timing data for all functions declared in a particular global",
    privs = {[debuggery.settings.admin_priv] = true},
    func = function(name, param)
        if not (minetest.global_exists(param) and _G[param]) then
            return false, ("unknown global %s"):format(param)
        end

        if old_values[param] then
            _G[param] = old_values[param]
            old_values[param] = nil
	        num_instrumented = num_instrumented - 1
            return true, ("instrumentation disabled for %s"):format(param)

        else
            old_values[param] = _G[param]
            _G[param] = instrument(param, _G[param])
	        num_instrumented = num_instrumented + 1
            return true, ("instrumentation enabled for %s"):format(param)
        end
    end,
})

local report_interval = debuggery.settings.instrumentation_report_interval
local elapsed = 0

minetest.register_globalstep(function(dtime)
	if num_instrumented == 0 then
		return
	end

    elapsed = elapsed + dtime
    if elapsed < report_interval then
        return
    end

    log(log_level, ("[instrument_mod] in %ss,"):format(elapsed))
    for name, num_calls in pairs_by_key(total_calls) do
        local te = total_elapsed[name]

        log(log_level, ("[instrument_mod] %s was called %s times, used %s us"):format(
            name, num_calls, te
        ))
    end

    total_calls = {}
    total_elapsed = {}

    elapsed = 0
	report_interval = debuggery.settings.instrumentation_report_interval
end)
