local Plugin = Plugin

function Plugin:Initialise()
	local command

	command = self:BindCommand("sh_trace_ray_options", "TraceRayOptions", SetTraceRayOptions)
	command:AddParam {
		Type = "number",
		Help = "Absolute acceptance"
	}

	command = self:BindCommand("sh_trace_box_options", "TraceBoxOptions", SetTraceBoxOptions)
	command:AddParam {
		Type = "number",
		Help = "Absolute acceptance"
	}

	command = self:BindCommand("sh_trace_capsule_options", "TraceCapsuleOptions", SetTraceCapsuleOptions)
	command:AddParam {
		Type = "number",
		Help = "Absolute acceptance"
	}
	command:AddParam {
		Type = "number",
		Help = "Relative acceptance"
	}
end
