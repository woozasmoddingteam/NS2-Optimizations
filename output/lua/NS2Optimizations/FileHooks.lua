(not Predict and Shared.Message or function() end) [=[
------------------------------
NS2 Optimizations - FastMixin:
You will see warnings of the type:
WARNING: Improperly initialized!
These just mean that an entity creation took longer than normal.
They indicate badly written code, and help debugging.
------------------------------
]=]

Script.Load("lua/NS2Optimizations/Closures/Closure.lua")

local kVersion = 6

local default_config = Server and {
	TraceCacheSize = {
		Ray     = 0,
		Box     = 0,
		Capsule = 16
	},
	TraceAcceptance = {
		Ray     = {
			Absolute = 0.1
		},
		Box     = {
			Absolute = 0.1
		},
		Capsule = {
			Absolute = 0.1,
			Relative = 0.2
		}
	},
	InfinitePlayerRelevancy   = false,
	UnsafeTableOptimizations  = true,
	FastMixin = true,
	__Version = kVersion
} or {
	TraceCacheSize = {
		Ray     = 4,
		Box     = 4,
		Capsule = 16
	},
	UnsafeTableOptimizations  = true,
	FastMixin = true,
	SaneMinimap = true,
	__Version = kVersion
}

local function sanitize(a, b)
	local changed = false
	for k in pairs(b) do
		if type(a[k]) ~= type(b[k]) then
			a[k] = b[k]
			changed = true
		elseif type(b[k]) == "table" then
			changed = changed or sanitize(a[k], b[k])
		end
	end
	for k in pairs(a) do
		if b[k] == nil and a[k] ~= nil then
			a[k] = nil
			changed = true
		end
	end
	return changed
end

local kConfigFile = Server and "NS2OptiServer.json" or "NS2OptiClient.json"
kNS2OptiConfig = LoadConfigFile(kConfigFile, default_config)
if kNS2OptiConfig.__Version ~= kVersion then
	Shared.Message [[
---------------------------------------------------------
NS2 Optimizations has been updated!
Please adjust your configuration values accordingly.
---------------------------------------------------------
]]
end
kNS2OptiConfig.__Version = kVersion
if sanitize(kNS2OptiConfig, default_config) then
	Shared.Message [[
--------------------------------------------------------------
Your NS2 Optimizations configuration file has been sanitized!
This means stray keys have been removed, and missing defaults
have been added.
--------------------------------------------------------------
]]
	SaveConfigFile(kConfigFile, kNS2OptiConfig)
end

if Client then
	kNS2OptiConfig.TraceAcceptance = {
		Ray     = {
			Absolute = 0.1
		},
		Box     = {
			Absolute = 0.1
		},
		Capsule = {
			Absolute = 0.1,
			Relative = 0.2
		}
	}
end

Shared.RegisterNetworkMessage("trace_cache_options", {
	ray = "float",
	box = "float",
	capsule_abs = "float",
	capsule_rel = "float"
})

Script.Load "lua/NS2Optimizations/Table.lua"

Script.Load "lua/NS2Optimizations/Closures/Utility.lua"
ModLoader.SetupFileHook("lua/Entity.lua", "lua/NS2Optimizations/Closures/Entity.lua", "post")

if Shared then
	Script.Load "lua/NS2Optimizations/TraceCaching/TraceRayCache.lua"
	Script.Load "lua/NS2Optimizations/TraceCaching/TraceCapsuleCache.lua"
	Script.Load "lua/NS2Optimizations/TraceCaching/TraceBoxCache.lua"

	local ray_hit, ray_miss, box_hit, box_miss, capsule_hit, capsule_miss = 0, 0, 0, 0, 0, 0
	local time = 0

	local function cacheStats()
		local ray_hit_curr, ray_miss_curr = TraceRayCacheStats()
		local box_hit_curr, box_miss_curr = TraceBoxCacheStats()
		local capsule_hit_curr, capsule_miss_curr = TraceCapsuleCacheStats()
		local ray_hit_diff  = ray_hit_curr  - ray_hit
		local ray_miss_diff = ray_miss_curr - ray_miss
		local box_hit_diff  = box_hit_curr  - box_hit
		local box_miss_diff = box_miss_curr - box_miss
		local capsule_hit_diff  = capsule_hit_curr  - capsule_hit
		local capsule_miss_diff = capsule_miss_curr - capsule_miss
		local time_diff = Shared.GetTime() - time
		time = Shared.GetTime()
		ray_hit,      ray_miss,      box_hit,      box_miss,      capsule_hit,      capsule_miss =
		ray_hit_curr, ray_miss_curr, box_hit_curr, box_miss_curr, capsule_hit_curr, capsule_miss_curr
		local small_delim = "--------"
		local big_delim = small_delim .. small_delim .. "\n"
		small_delim = small_delim .. "\n"
		local s = "\n" .. big_delim
		s = s .. "Time passed: " .. time_diff .. "\n"
		s = s .. small_delim
		s = s .. "Box Cache hits:   " .. box_hit_diff .. "\n"
		s = s .. "Box Cache misses: " .. box_miss_diff .. "\n"
		s = s .. "Box Cache hit percentage: " .. 100 * box_hit_diff / (box_hit_diff + box_miss_diff) .. "%\n"
		s = s .. small_delim
		s = s .. "Capsule Cache hits:   " .. capsule_hit_diff .. "\n"
		s = s .. "Capsule Cache misses: " .. capsule_miss_diff .. "\n"
		s = s .. "Capsule Cache hit percentage: " .. 100 * capsule_hit_diff / (capsule_hit_diff + capsule_miss_diff) .. "%\n"
		s = s .. small_delim
		s = s .. "Ray Cache hits:   " .. ray_hit_diff .. "\n"
		s = s .. "Ray Cache misses: " .. ray_miss_diff .. "\n"
		s = s .. "Ray Cache hit percentage: " .. 100 * ray_hit_diff / (ray_hit_diff + ray_miss_diff) .. "%\n"
		s = s .. big_delim
		return s
	end

	local function maybe(f)
		if f then
			return f()
		else
			return 0, 0
		end
	end

	local function cacheStatsTotal()
		local ray_hit_diff, ray_miss_diff = maybe(TraceRayCacheStats)
		local box_hit_diff, box_miss_diff = maybe(TraceBoxCacheStats)
		local capsule_hit_diff, capsule_miss_diff = maybe(TraceCapsuleCacheStats)
		local small_delim = "--------"
		local big_delim = small_delim .. small_delim .. "\n"
		small_delim = small_delim .. "\n"
		local s = "\n" .. big_delim
		s = s .. "Time passed: " .. Shared.GetTime() .. "\n"
		s = s .. small_delim
		s = s .. "Box Cache hits:   " .. box_hit_diff .. "\n"
		s = s .. "Box Cache misses: " .. box_miss_diff .. "\n"
		s = s .. "Box Cache hit percentage: " .. 100 * box_hit_diff / (box_hit_diff + box_miss_diff) .. "%\n"
		s = s .. small_delim
		s = s .. "Capsule Cache hits:   " .. capsule_hit_diff .. "\n"
		s = s .. "Capsule Cache misses: " .. capsule_miss_diff .. "\n"
		s = s .. "Capsule Cache hit percentage: " .. 100 * capsule_hit_diff / (capsule_hit_diff + capsule_miss_diff) .. "%\n"
		s = s .. small_delim
		s = s .. "Ray Cache hits:   " .. ray_hit_diff .. "\n"
		s = s .. "Ray Cache misses: " .. ray_miss_diff .. "\n"
		s = s .. "Ray Cache hit percentage: " .. 100 * ray_hit_diff / (ray_hit_diff + ray_miss_diff) .. "%\n"
		s = s .. big_delim
		return s
	end

	_G.TraceCacheStatsTotal = cacheStatsTotal
	_G.TraceCacheStatsDiff  = cacheStats

	if Server then
		Event.Hook("ClientConnect", function(client)
			local data = {
				box = GetTraceBoxOptions(),
				ray = GetTraceRayOptions()
			}
			data.capsule_abs, data.capsule_rel = GetTraceCapsuleOptions()
			Server.SendNetworkMessage(client, "trace_cache_options", data, true)
		end)
	elseif Client then
		Event.Hook("Console_trace_cache_diff", function() Shared.Message(cacheStats()) end)
		Event.Hook("Console_trace_cache_total", function() Shared.Message(cacheStatsTotal()) end)
		if SetTraceRayOptions then
			Event.Hook("Console_trace_ray_options", SetTraceRayOptions)
		end
		if SetTraceBoxOptions then
			Event.Hook("Console_trace_box_options", SetTraceBoxOptions)
		end
		if SetTraceCapsuleOptions then
			Event.Hook("Console_trace_capsule_options", SetTraceCapsuleOptions)
		end
		Client.HookNetworkMessage("trace_cache_options", function(data)
			if SetTraceRayOptions then SetTraceRayOptions(data.ray) end
			if SetTraceBoxOptions then SetTraceBoxOptions(data.box) end
			if SetTraceCapsuleOptions then SetTraceCapsuleOptions(data.capsule_abs, data.capsule_rel) end
		end)
	end
end

Script.Load "lua/NS2Optimizations/FastMixin/init.lua"
ModLoader.SetupFileHook("lua/MixinUtility.lua",           "lua/NS2Optimizations/FastMixin/MixinUtility.lua",   "replace")
ModLoader.SetupFileHook("lua/MixinDispatcherBuilder.lua", true,                                                 "halt")

do -- Smart Relevancy
	ModLoader.SetupFileHook("lua/Observatory.lua",              "lua/NS2Optimizations/SmartRelevancy/Observatory.lua", "post")
	--ModLoader.SetupFileHook("lua/BalanceMisc.lua",              "lua/NS2Optimizations/SmartRelevancy/BalanceMisc.lua", "post")
	if Server then
		ModLoader.SetupFileHook("lua/Gamerules.lua", "lua/NS2Optimizations/SmartRelevancy/Gamerules_Server.lua", "post")
		ModLoader.SetupFileHook("lua/Player.lua",    "lua/NS2Optimizations/SmartRelevancy/Player_Server.lua",    "post")
	end
end

ModLoader.SetupFileHook("lua/TechTreeConstants.lua", "lua/NS2Optimizations/Tech/TechTreeConstants.lua", "post")

for _, v in ipairs {
	"GUIManager",
	"GUIMinimapFrame",
	"MapBlip",
	"MapBlipMixin",
	--"MinimapMappableMixin",
	--"MinimapConnectionMixin",
	--"MapConnector",
	--"GUIMinimapButtons",
} do
	ModLoader.SetupFileHook("lua/"..v..".lua", "lua/NS2Optimizations/GUIRework/"..v..".lua", "replace")
end
for _, v in ipairs {
	"GUIUtility",
	"GUIScript",
	"GUIChat",
	"TunnelEntrance",
	"Globals",
} do
	ModLoader.SetupFileHook("lua/"..v..".lua", "lua/NS2Optimizations/GUIRework/"..v..".lua", "post")
end
ModLoader.SetupFileHook("lua/NS2Plus/GUIScripts/GUIMinimap.lua", true, "halt")
ModLoader.SetupFileHook("lua/shine/extensions/chatbox/client.lua", "lua/NS2Optimizations/GUIRework/shine_chatbox.lua", "replace")

ModLoader.SetupFileHook("lua/Mixins/ControllerMixin.lua", "lua/NS2Optimizations/NYIRemoval/ControllerMixin.lua", "post")
