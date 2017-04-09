local Plugin = Plugin

function Plugin:Initialise()
	local command

	command = self:BindCommand("sh_sv_trace_ray_options", "ServerTraceRayOptions", function(_, abs)
		SetTraceRayOptions(abs)
		local a, b = GetTraceCapsuleOptions()
		Server.SendNetworkMessage("trace_cache_options", {
			ray = abs,
			box = GetTraceBoxOptions()
			capsule_abs = a,
			capsule_rel = b
		}, true)
	end)
	command:AddParam {
		Type = "number",
		Help = "Absolute acceptance"
	}

	command = self:BindCommand("sh_sv_trace_box_options", "ServerTraceBoxOptions", function(_, abs)
		SetTraceBoxOptions(abs)
		local a, b = GetTraceCapsuleOptions()
		Server.SendNetworkMessage("trace_cache_options", {
			ray = GetTraceRayOptions()
			box = abs,
			capsule_abs = a,
			capsule_rel = b
		}, true)
	end)
	command:AddParam {
		Type = "number",
		Help = "Absolute acceptance"
	}

	command = self:BindCommand("sh_sv_trace_capsule_options", "ServerTraceCapsuleOptions", function(_, abs, rel)
		SetTraceCapsuleOptions(abs, rel)
		Server.SendNetworkMessage("trace_cache_options", {
			ray = GetTraceRayOptions(),
			box = GetTraceBoxOptions(),
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
end
