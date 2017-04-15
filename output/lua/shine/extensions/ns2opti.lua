local Plugin = {}

Plugin.DefaultState = true

local function m(f)
	local a, b = f()
	if a then
		return a, b
	else
		return 0, 0
	end
end

function Plugin:Initialise()
	local command

	command = self:BindCommand("sh_trace_ray_options", "TraceRayOptions", function(_, abs)
		SetTraceRayOptions(abs)
		local a, b = m(GetTraceCapsuleOptions)
		Server.SendNetworkMessage("trace_cache_options", {
			ray = abs,
			box = m(GetTraceBoxOptions),
			capsule_abs = a,
			capsule_rel = b
		}, true)
	end)
	command:AddParam {
		Type = "number",
		Help = "Absolute acceptance"
	}

	command = self:BindCommand("sh_trace_box_options", "TraceBoxOptions", function(_, abs)
		SetTraceBoxOptions(abs)
		local a, b = m(GetTraceCapsuleOptions)
		Server.SendNetworkMessage("trace_cache_options", {
			ray = m(GetTraceRayOptions),
			box = abs,
			capsule_abs = a,
			capsule_rel = b
		}, true)
	end)
	command:AddParam {
		Type = "number",
		Help = "Absolute acceptance"
	}

	command = self:BindCommand("sh_trace_capsule_options", "TraceCapsuleOptions", function(_, abs, rel)
		SetTraceCapsuleOptions(abs, rel)
		Server.SendNetworkMessage("trace_cache_options", {
			ray = m(GetTraceRayOptions),
			box = m(GetTraceBoxOptions),
			capsule_abs = abs,
			capsule_rel = rel
		}, true)
	end)
	command:AddParam {
		Type = "number",
		Help = "Absolute acceptance"
	}
	command:AddParam {
		Type = "number",
		Help = "Relative acceptance"
	}

	command = self:BindCommand("sh_trace_cache_diff", nil, function()
		local s = TraceCacheStatsDiff()
		Shine:AdminPrint(nil, s)
	end)

	command = self:BindCommand("sh_trace_cache_total", nil, function()
		local s = TraceCacheStatsTotal()
		Shine:AdminPrint(nil, s)
	end)
end

Shine:RegisterExtension("ns2opti", Plugin)
